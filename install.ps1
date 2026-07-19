<#
install.ps1 — install the brainiac CLI on Windows with NO inewi access. Downloads the prebuilt
binary for windows-x64 from the PUBLIC inewi/brainiac-dist releases, then (when a Claude/Copilot
CLI is present) wires the public dev plugin + superpowers via `brainiac setup --dev`.

  irm https://raw.githubusercontent.com/inewi/brainiac-dist/main/install.ps1 | iex

To pass options, download the script first (piping to `iex` can't forward parameters):
  iwr https://raw.githubusercontent.com/inewi/brainiac-dist/main/install.ps1 -OutFile install.ps1
  .\install.ps1 -NoSetup                 # install the binaries only; skip `brainiac setup --dev`
  .\install.ps1 -BinDir C:\tools\bin     # install location (default: %USERPROFILE%\.local\bin)

Generated from inewi/brainiac-pipeline (packaging/install.ps1). Do not edit on the dist repo.
#>
[CmdletBinding()]
param(
  [switch]$NoSetup,
  [string]$BinDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# TLS 1.2 for Invoke-WebRequest on Windows PowerShell 5.1 (its default protocol set is too old for
# GitHub); harmless on PowerShell 7+.
[Net.ServicePointManager]::SecurityProtocol = `
  [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Repo = 'inewi/brainiac-dist'

# Resolve the install dir: -BinDir wins, then $env:BRAINIAC_BIN_DIR, then %USERPROFILE%\.local\bin
# (matches scripts/setup-lib.mjs defaultBinDir for win32).
if (-not $BinDir) { $BinDir = $env:BRAINIAC_BIN_DIR }
if (-not $BinDir) { $BinDir = Join-Path $env:USERPROFILE '.local\bin' }

# Only the windows-x64 asset is published (must match the release workflow's names). One asset
# covers every supported Windows machine: it runs natively on AMD64 and under the built-in x64
# emulation on Windows-on-ARM — so there is no arch branch, unlike install.sh's unix arm64/x64 split.
$base = "https://github.com/$Repo/releases/latest/download"

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

# Fetch the release's SHA256SUMS manifest once. Verification is skipped (loudly) ONLY when the
# release predates checksums — any downloaded manifest is enforced, and a missing/mismatched
# entry fails the install rather than shipping an unverifiable binary.
$script:SumsFile = Join-Path ([IO.Path]::GetTempPath()) "brainiac-sums-$PID.txt"
$script:HaveSums = $true
try {
  Invoke-WebRequest -UseBasicParsing -Uri "$base/SHA256SUMS" -OutFile $script:SumsFile
} catch {
  Remove-Item -Force -ErrorAction SilentlyContinue $script:SumsFile
  # Only a true 404 (release predates checksums) may skip verification; any other failure
  # (5xx, network-level) aborts — fail closed. Response is absent on network-level errors,
  # and StrictMode throws on missing properties, so probe via PSObject.Properties.
  $status = 0
  $respProp = $_.Exception.PSObject.Properties['Response']
  if ($respProp -and $respProp.Value) { $status = [int]$respProp.Value.StatusCode }
  if ($status -eq 404) {
    $script:HaveSums = $false
    Write-Warning 'brainiac: this release ships no SHA256SUMS manifest; skipping checksum verification'
  } else {
    throw "brainiac: could not fetch the SHA256SUMS manifest (HTTP $status) — refusing to install unverified binaries; re-run in a moment"
  }
}

# Compare a download against its SHA256SUMS entry (sha256sum format: `<hash>  <name>`). Fails
# closed on a missing entry or a mismatch; only an entirely absent manifest skips.
function Test-BrainiacChecksum {
  param([string]$Asset, [string]$File)
  if (-not $script:HaveSums) { return }
  $entry = Get-Content $script:SumsFile |
    Where-Object { $parts = $_ -split '\s+', 2; ($parts.Count -ge 2) -and ($parts[1] -eq $Asset) } |
    Select-Object -First 1
  if (-not $entry) {
    throw "brainiac: SHA256SUMS has no entry for $Asset — refusing to install an unverifiable binary"
  }
  $expected = ($entry -split '\s+')[0].ToLowerInvariant()
  $actual = (Get-FileHash -Algorithm SHA256 -Path $File).Hash.ToLowerInvariant()
  if ($actual -ne $expected) {
    throw "brainiac: checksum MISMATCH for $Asset (expected $expected, got $actual) — corrupt or tampered download"
  }
  Write-Host "brainiac: verified $Asset (sha256 OK)"
}

# Download <asset> to <dest> over HTTPS, writing to a temp file + atomically renaming on success so
# an interrupted download or a concurrent run never leaves a partial binary.
function Get-BrainiacAsset {
  param([string]$Asset, [string]$Dest)
  $tmp = "$Dest.tmp.$PID"
  Write-Host "brainiac: downloading $Asset"
  try {
    Invoke-WebRequest -UseBasicParsing -Uri "$base/$Asset" -OutFile $tmp
  } catch {
    Remove-Item -Force -ErrorAction SilentlyContinue $tmp
    # `throw` (not `exit`) so the advertised `irm … | iex` path surfaces the error without killing
    # the user's interactive session (iex runs in-process); on a `-File` run it still exits non-zero.
    throw "brainiac: download failed ($base/$Asset) — release asset missing?"
  }
  try {
    Test-BrainiacChecksum -Asset $Asset -File $tmp
  } catch {
    Remove-Item -Force -ErrorAction SilentlyContinue $tmp
    throw
  }
  Move-Item -Force -Path $tmp -Destination $Dest
}

Get-BrainiacAsset 'brainiac-windows-x64.exe' (Join-Path $BinDir 'brainiac.exe')
Get-BrainiacAsset 'brainiac-check-windows-x64.exe' (Join-Path $BinDir 'brainiac-check.exe')
Remove-Item -Force -ErrorAction SilentlyContinue $script:SumsFile

Write-Host "brainiac: installed brainiac + brainiac-check to $BinDir"

# Nudge PATH if the install dir is not already on it (parity with install.sh: print the fix, never
# mutate the user's registry PATH silently).
$onPath = ($env:PATH -split ';') -contains $BinDir
if (-not $onPath) {
  Write-Host "brainiac: add $BinDir to your PATH, e.g. run:"
  Write-Host "  [Environment]::SetEnvironmentVariable('Path', '$BinDir;' + [Environment]::GetEnvironmentVariable('Path','User'), 'User')"
}

$brainiac = Join-Path $BinDir 'brainiac.exe'
if (-not $NoSetup) {
  $hasHost = (Get-Command claude -ErrorAction SilentlyContinue) -or `
    (Get-Command copilot -ErrorAction SilentlyContinue)
  if ($hasHost) {
    Write-Host "brainiac: wiring the dev plugin + superpowers (brainiac setup --dev)"
    Write-Host "brainiac: cloning the brainiac + superpowers marketplaces over the network — first run can take 10-30s..."
    & $brainiac setup --dev
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "brainiac: 'setup --dev' did not finish (exit $LASTEXITCODE) — re-run '$brainiac setup --dev' later"
    }
  } else {
    Write-Host "brainiac: no Claude/Copilot CLI found — run '$brainiac setup --dev' after installing one"
  }
}
