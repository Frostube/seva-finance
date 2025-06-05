#!/bin/bash
set -e
FLUTTER_VERSION=3.22.1
INSTALL_DIR="$HOME/flutter"
if [ ! -d "$INSTALL_DIR" ]; then
  echo "Installing Flutter $FLUTTER_VERSION to $INSTALL_DIR" >&2
  curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o flutter.tar.xz
  mkdir -p "$HOME"
  tar -xf flutter.tar.xz -C "$HOME"
  rm flutter.tar.xz
fi
export PATH="$INSTALL_DIR/bin:$PATH"
flutter --version

