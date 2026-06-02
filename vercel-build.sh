#!/bin/bash
echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Creating dummy .env file for Flutter..."
touch .env

echo "Building Flutter Web App..."
flutter build web --release
