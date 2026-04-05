#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${ROOT_DIR}/.tools"
GO_VERSION="${GO_VERSION:-1.22.5}"
GO_ARCHIVE="go${GO_VERSION}.darwin-arm64.tar.gz"
GO_URL="https://go.dev/dl/${GO_ARCHIVE}"

mkdir -p "${TOOLS_DIR}"

if [[ -x "${TOOLS_DIR}/go/bin/go" ]]; then
  echo "Local Go already installed: $(${TOOLS_DIR}/go/bin/go version)"
  exit 0
fi

echo "Downloading ${GO_URL}"
curl -L "${GO_URL}" -o "${TOOLS_DIR}/go.tar.gz"
tar -xzf "${TOOLS_DIR}/go.tar.gz" -C "${TOOLS_DIR}"

echo "Installed local Go: $(${TOOLS_DIR}/go/bin/go version)"
echo "Usage example:"
echo "  PATH=\"${TOOLS_DIR}/go/bin:\$PATH\" go version"
