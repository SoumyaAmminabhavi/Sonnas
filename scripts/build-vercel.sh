#!/bin/bash
set -e

echo "Downloading Flutter..."
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi
export PATH="$PATH:`pwd`/flutter/bin"

echo "Building Flutter Web..."
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=BACKEND_URL="$BACKEND_URL"

echo "Copying to public..."
mkdir -p public
cp -r build/web/* public/
