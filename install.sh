#!/bin/sh
# install.sh — install the brainiac CLI with NO inewi access. Downloads the prebuilt binary
# for your platform over HTTPS from the PUBLIC inewi/brainiac-dist releases and verifies it
# against the release's SHA256SUMS manifest (checksum integrity only — downloads are NOT
# signature-verified; do not claim otherwise), then (when a Claude/Copilot CLI is present)
# wires the public dev plugin + superpowers via `brainiac setup --dev`.
#
#   curl -fsSL https://raw.githubusercontent.com/inewi/brainiac-dist/main/install.sh | sh
#
# Options (pass after `| sh -s --`):
#   --no-setup            install the binaries only; skip `brainiac setup --dev`
#   --bin-dir <dir>       install location (default: $HOME/.local/bin)
#
# Generated from inewi/brainiac-pipeline (packaging/install.sh). Do not edit on the dist repo.
set -eu

REPO="inewi/brainiac-dist"
BIN_DIR="${BRAINIAC_BIN_DIR:-$HOME/.local/bin}"
DO_SETUP=1

while [ $# -gt 0 ]; do
  case "$1" in
    --no-setup) DO_SETUP=0 ;;
    --bin-dir) shift; BIN_DIR="${1:?--bin-dir needs a path}" ;;
    *) echo "install.sh: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

# Resolve OS + architecture into the release asset suffix (must match the release workflow's names).
os=$(uname -s)
case "$os" in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  *) echo "brainiac: unsupported OS '$os' — on Windows run install.ps1 in PowerShell: irm https://raw.githubusercontent.com/inewi/brainiac-dist/main/install.ps1 | iex (or build from source)" >&2; exit 1 ;;
esac
arch=$(uname -m)
case "$arch" in
  arm64 | aarch64) arch=arm64 ;;
  x86_64 | amd64) arch=x64 ;;
  *) echo "brainiac: unsupported architecture '$arch'" >&2; exit 1 ;;
esac
suffix="${os}-${arch}"

if ! command -v curl >/dev/null 2>&1; then
  echo "brainiac: curl is required to install" >&2
  exit 1
fi

base="https://github.com/${REPO}/releases/latest/download"
mkdir -p "$BIN_DIR"

# Fetch the release's SHA256SUMS manifest once. Verification is skipped (loudly) ONLY when the
# release predates checksums — any downloaded manifest is enforced, and a missing/mismatched
# entry fails the install rather than shipping an unverifiable binary.
sums=$(mktemp "${TMPDIR:-/tmp}/brainiac-sums.XXXXXX")
trap 'rm -f "$sums"' EXIT
# No -f: we need the status code, not curl's error exit. -w prints the FINAL code after
# redirects (000 on a network-level failure). Only a true 404 (release predates checksums)
# may skip verification; any other failure aborts — fail closed, never silently unverified.
sums_code=$(curl -sSL --proto '=https' --tlsv1.2 -o "$sums" -w '%{http_code}' \
  "${base}/SHA256SUMS" 2>/dev/null) || sums_code=000
if [ "$sums_code" = "200" ]; then
  HAVE_SUMS=1
elif [ "$sums_code" = "404" ]; then
  HAVE_SUMS=0
  echo "brainiac: WARNING — this release ships no SHA256SUMS manifest; skipping checksum verification" >&2
else
  echo "brainiac: could not fetch the SHA256SUMS manifest (HTTP ${sums_code}) — refusing to install unverified binaries; re-run in a moment" >&2
  exit 1
fi

# sha256 <file> — portable digest: sha256sum (Linux) or shasum -a 256 (macOS).
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else echo ""
  fi
}

# verify <asset> <file> — compare the download against its SHA256SUMS entry. Fails closed on a
# missing entry or a mismatch; only an entirely absent manifest (HAVE_SUMS=0) skips.
verify() {
  [ "$HAVE_SUMS" -eq 1 ] || return 0
  expected=$(awk -v a="$1" '$2 == a { print $1 }' "$sums")
  if [ -z "$expected" ]; then
    echo "brainiac: SHA256SUMS has no entry for $1 — refusing to install an unverifiable binary" >&2
    return 1
  fi
  actual=$(sha256 "$2")
  if [ -z "$actual" ]; then
    echo "brainiac: no sha256sum/shasum tool found — cannot verify $1" >&2
    return 1
  fi
  if [ "$actual" != "$expected" ]; then
    echo "brainiac: checksum MISMATCH for $1 (expected ${expected}, got ${actual}) — corrupt or tampered download" >&2
    return 1
  fi
  echo "brainiac: verified $1 (sha256 OK)"
}

# Download <asset> to <dest> over HTTPS. Writes to a temp file + atomically renames on
# success so an interrupted download or a concurrent run never leaves a partial binary.
fetch() {
  asset="$1"
  dest="$2"
  tmp="${dest}.tmp.$$"
  echo "brainiac: downloading ${asset}"
  if ! curl -fSL --proto '=https' --tlsv1.2 -o "$tmp" "${base}/${asset}"; then
    echo "brainiac: download failed (${base}/${asset}) — no release asset for ${suffix}?" >&2
    rm -f "$tmp"
    exit 1
  fi
  if ! verify "$asset" "$tmp"; then
    rm -f "$tmp"
    exit 1
  fi
  chmod +x "$tmp"
  mv "$tmp" "$dest"
}

fetch "brainiac-${suffix}" "${BIN_DIR}/brainiac"
fetch "brainiac-check-${suffix}" "${BIN_DIR}/brainiac-check"

echo "brainiac: installed brainiac + brainiac-check to ${BIN_DIR}"

# Nudge PATH if the install dir is not already on it (so `brainiac` resolves in new shells).
case ":${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *) echo "brainiac: add ${BIN_DIR} to your PATH, e.g.  echo 'export PATH=\"${BIN_DIR}:\$PATH\"' >> ~/.profile" ;;
esac

if [ "$DO_SETUP" -eq 1 ]; then
  if command -v claude >/dev/null 2>&1 || command -v copilot >/dev/null 2>&1; then
    echo "brainiac: wiring the dev plugin + superpowers (brainiac setup --dev)"
    echo "brainiac: cloning the brainiac + superpowers marketplaces over the network — first run can take 10-30s..."
    "${BIN_DIR}/brainiac" setup --dev
    st=$?
    if [ $st -ne 0 ]; then
      # 126/127 = the binary cannot run at all (wrong arch, missing libc, e.g. Alpine/musl) —
      # re-running won't help. Other non-zero = setup itself failed, likely transient.
      if [ $st -eq 126 ] || [ $st -eq 127 ]; then
        echo "brainiac: the downloaded binary does not run on this system (exit ${st}) — unsupported platform. Try building from source." >&2
      else
        echo "brainiac: 'setup --dev' did not finish (exit ${st}) — re-run '${BIN_DIR}/brainiac setup --dev' later" >&2
      fi
    fi
  else
    echo "brainiac: no Claude/Copilot CLI found — run '${BIN_DIR}/brainiac setup --dev' after installing one"
  fi
fi
