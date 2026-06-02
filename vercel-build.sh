#!/bin/bash
echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Creating .env file for Flutter..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
echo "RAZORPAY_KEY_ID=$RAZORPAY_KEY_ID" >> .env

echo "Building Flutter Web App..."
flutter build web --release
