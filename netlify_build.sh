#!/bin/bash

# Exit on any error
set -e

echo "=== Starting Netlify Flutter Web Build Process ==="

# 1. Ensure FIREBASE_OPTIONS_BASE64 is provided
if [ -z "$FIREBASE_OPTIONS_BASE64" ]; then
  echo "ERROR: FIREBASE_OPTIONS_BASE64 environment variable is not set."
  echo "Please set this variable in your Netlify Build Environment settings."
  exit 1
fi

# 2. Decode the firebase_options.dart file
echo "Decoding firebase_options.dart..."
mkdir -p lib
echo "$FIREBASE_OPTIONS_BASE64" | base64 --decode > lib/firebase_options.dart

if [ ! -f "lib/firebase_options.dart" ] || [ ! -s "lib/firebase_options.dart" ]; then
  echo "ERROR: Failed to decode or write lib/firebase_options.dart correctly."
  exit 1
fi
echo "firebase_options.dart successfully generated."

# 3. Setup and cache Flutter SDK
# We use the Netlify cache directory if available, otherwise fallback to $HOME/.cache
CACHE_DIR="${NETLIFY_CACHE_DIR:-$HOME/.cache}"
FLUTTER_SDK_DIR="$CACHE_DIR/flutter"

echo "Using Cache Directory: $CACHE_DIR"

if [ ! -d "$FLUTTER_SDK_DIR/.git" ]; then
  echo "Flutter SDK not found in cache. Cloning Flutter repository (stable channel)..."
  rm -rf "$FLUTTER_SDK_DIR"
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_SDK_DIR"
else
  echo "Flutter SDK found in cache. Updating to latest stable..."
  cd "$FLUTTER_SDK_DIR"
  git fetch origin stable
  git reset --hard origin/stable
  cd -
fi

# Add Flutter to the path
export PATH="$PATH:$FLUTTER_SDK_DIR/bin"

# 4. Verify Flutter Installation
echo "Flutter version details:"
flutter --version

# 5. Enable Web Build
echo "Configuring Flutter for Web..."
flutter config --enable-web

# 6. Install Dependencies
echo "Installing dependencies..."
flutter pub get

# 7. Build Web App
echo "Building Flutter Web application (Release)..."
flutter build web --release

echo "=== Build Process Completed Successfully ==="
