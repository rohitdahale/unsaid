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
FLUTTER_REVISION="84fc5cbb22bc12f83d65b647ff8a56caf779ffd"

echo "Using Cache Directory: $CACHE_DIR"
echo "Target Flutter Revision: $FLUTTER_REVISION"

if [ ! -d "$FLUTTER_SDK_DIR/.git" ]; then
  echo "Flutter SDK not found in cache. Cloning Flutter repository..."
  rm -rf "$FLUTTER_SDK_DIR"
  git clone https://github.com/flutter/flutter.git "$FLUTTER_SDK_DIR"
else
  echo "Flutter SDK found in cache."
fi

# Navigate to Flutter SDK to fetch and checkout the correct revision
cd "$FLUTTER_SDK_DIR"
echo "Updating/Checking out Flutter revision $FLUTTER_REVISION..."
git fetch origin
git checkout "$FLUTTER_REVISION"
cd -

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
