#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up iPara project...${NC}"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter is not installed. Please install Flutter first.${NC}"
    echo "Visit https://flutter.dev/docs/get-started/install for installation instructions."
    exit 1
fi

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | grep -oP 'Flutter \K[0-9]+\.[0-9]+\.[0-9]+')
echo -e "${YELLOW}Detected Flutter version: $FLUTTER_VERSION${NC}"

# Get dependencies
echo -e "${GREEN}Getting dependencies...${NC}"
flutter pub get

# Check if running on web
if [ "$1" == "--web" ]; then
    echo -e "${GREEN}Setting up for web...${NC}"
    flutter config --enable-web
fi

# Create necessary directories if they don't exist
mkdir -p android/app/src/main/assets
mkdir -p ios/Runner/Assets.xcassets

# Check for required files
if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${YELLOW}Warning: google-services.json not found in android/app/${NC}"
    echo "Please add your Firebase configuration file."
fi

if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${YELLOW}Warning: GoogleService-Info.plist not found in ios/Runner/${NC}"
    echo "Please add your Firebase configuration file."
fi

# Run Flutter doctor
echo -e "${GREEN}Running Flutter doctor...${NC}"
flutter doctor

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add your Google Maps API key to:"
echo "   - android/app/src/main/AndroidManifest.xml"
echo "   - ios/Runner/AppDelegate.swift"
echo "   - web/index.html"
echo "2. Add your Firebase configuration files:"
echo "   - android/app/google-services.json"
echo "   - ios/Runner/GoogleService-Info.plist"
echo "3. Run the app with: flutter run" 