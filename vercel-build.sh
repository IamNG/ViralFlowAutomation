#!/bin/bash
# Vercel Build Script for Flutter Web

echo "Downloading Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Checking Flutter version..."
flutter --version

echo "Resolving dependencies..."
flutter pub get

echo "Generating built models (Freezed/JSON)..."
dart run build_runner build --delete-conflicting-outputs

echo "Building web application..."
flutter build web \
  --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=RAZORPAY_KEY_ID=$RAZORPAY_KEY_ID \
  --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY

echo "Build complete! Web files are located in build/web"
