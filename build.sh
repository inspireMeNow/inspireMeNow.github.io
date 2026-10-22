#!/usr/bin/env bash
set -euo pipefail

HUGO_VERSION="0.168.0"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Installing Hugo ${HUGO_VERSION}"

curl -fsSL \
  "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz" \
  -o "$BUILD_DIR/hugo.tar.gz"

tar -xzf "$BUILD_DIR/hugo.tar.gz" -C "$BUILD_DIR" hugo

git submodule update --init --recursive

"$BUILD_DIR/hugo" version
"$BUILD_DIR/hugo" --gc --minify
