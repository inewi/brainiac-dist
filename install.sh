#!/bin/sh
# install.sh — install the brainiac CLI with NO inewi access. Downloads the prebuilt, signed binary
# for your platform from the PUBLIC inewi/brainiac-dist releases, then (when a Claude/Copilot CLI is
# present) wires the public dev plugin + superpowers via `brainiac setup --dev`.
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
  *) echo "brainiac: unsupported OS '$os' (use Scoop on Windows, or build from source)" >&2; exit 1 ;;
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
    echo "brainiac: cloning the brainiac-dev + superpowers marketplaces over the network — first run can take 10-30s..."
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
