#!/bin/bash
#
# Generates the Homebrew formula for scrut with correct SHA256 hashes.
#
# Usage:
#   ./scripts/generate-homebrew-formula.sh <version>
#
# Example:
#   ./scripts/generate-homebrew-formula.sh 0.4.3
#
# The script will:
#   1. Download release tarballs for all supported platforms
#   2. Compute SHA256 hashes
#   3. Generate Formula/scrut.rb with the correct values
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FORMULA_PATH="$REPO_ROOT/Formula/scrut.rb"

usage() {
    echo "Usage: $0 <version>"
    echo ""
    echo "Generate the Homebrew formula for scrut with correct SHA256 hashes."
    echo ""
    echo "Arguments:"
    echo "  version    The release version (e.g., 0.4.3)"
    echo ""
    echo "Example:"
    echo "  $0 0.4.3"
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

VERSION="$1"

# Validate version format (basic check)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 0.4.3)"
    exit 1
fi

BASE_URL="https://github.com/facebookincubator/scrut/releases/download/v${VERSION}"

# Platform configurations: name, url_suffix
declare -A PLATFORMS=(
    ["macos_arm"]="macos-aarch64"
    ["macos_intel"]="macos-x86_64"
    ["linux_arm"]="linux-aarch64"
    ["linux_intel"]="linux-x86_64"
)

declare -A HASHES

echo "Fetching SHA256 hashes for scrut v${VERSION}..."
echo ""

# Create temp directory for downloads
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

for platform in "${!PLATFORMS[@]}"; do
    suffix="${PLATFORMS[$platform]}"
    filename="scrut-v${VERSION}-${suffix}.tar.gz"
    url="${BASE_URL}/${filename}"

    echo "Downloading ${filename}..."

    if ! curl -fsSL -o "$TMPDIR/$filename" "$url"; then
        echo "Error: Failed to download $url"
        echo "Make sure the release v${VERSION} exists and includes all platform binaries."
        exit 1
    fi

    # Compute SHA256 hash
    if command -v sha256sum &> /dev/null; then
        hash=$(sha256sum "$TMPDIR/$filename" | cut -d' ' -f1)
    elif command -v shasum &> /dev/null; then
        hash=$(shasum -a 256 "$TMPDIR/$filename" | cut -d' ' -f1)
    else
        echo "Error: Neither sha256sum nor shasum found"
        exit 1
    fi

    HASHES[$platform]="$hash"
    echo "  SHA256: $hash"
    echo ""
done

echo "Generating Formula/scrut.rb..."

# Create the formula directory if it doesn't exist
mkdir -p "$REPO_ROOT/Formula"

cat > "$FORMULA_PATH" << EOF
class Scrut < Formula
  desc "Simple and powerful test framework for CLI applications"
  homepage "https://facebookincubator.github.io/scrut/"
  version "${VERSION}"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/facebookincubator/scrut/releases/download/v#{version}/scrut-v#{version}-macos-aarch64.tar.gz"
      sha256 "${HASHES[macos_arm]}"
    elsif Hardware::CPU.intel?
      url "https://github.com/facebookincubator/scrut/releases/download/v#{version}/scrut-v#{version}-macos-x86_64.tar.gz"
      sha256 "${HASHES[macos_intel]}"
    else
      odie "scrut: unsupported macOS architecture: #{Hardware::CPU.arch}"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/facebookincubator/scrut/releases/download/v#{version}/scrut-v#{version}-linux-aarch64.tar.gz"
      sha256 "${HASHES[linux_arm]}"
    elsif Hardware::CPU.intel?
      url "https://github.com/facebookincubator/scrut/releases/download/v#{version}/scrut-v#{version}-linux-x86_64.tar.gz"
      sha256 "${HASHES[linux_intel]}"
    else
      odie "scrut: unsupported Linux architecture: #{Hardware::CPU.arch}"
    end
  end

  def install
    bin.install "scrut"

    generate_completions_from_executable(bin/"scrut", shells: [:bash, :fish, :pwsh, :zsh]) do |shell|
      env_value = { bash: "bash_source", fish: "fish_source", pwsh: "powershell_source", zsh: "zsh_source" }.fetch(shell)
      Utils.safe_popen_read({ "_SCRUT_COMPLETE" => env_value }, bin/"scrut")
    end
  end

  test do
    assert_match "scrut #{version}", shell_output("#{bin}/scrut --version")
  end
end
EOF

echo ""
echo "Successfully generated $FORMULA_PATH for version ${VERSION}"
echo ""
echo "Hashes:"
echo "  macOS ARM (aarch64): ${HASHES[macos_arm]}"
echo "  macOS Intel (x86_64): ${HASHES[macos_intel]}"
echo "  Linux ARM (aarch64):  ${HASHES[linux_arm]}"
echo "  Linux Intel (x86_64): ${HASHES[linux_intel]}"
