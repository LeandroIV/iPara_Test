#!/bin/bash

echo "iPara Logo Replacement Tool"
echo "==========================="
echo
echo "This script will help you replace the app logo with your own."
echo
echo "Prerequisites:"
echo "1. Your logo.png file should be ready"
echo "2. Flutter should be installed and in your PATH"
echo
read -p "Press Enter to continue..."

echo
echo "Step 1: Installing dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "Error installing dependencies. Please make sure Flutter is installed correctly."
    exit 1
fi

echo
echo "Step 2: Generating launcher icons..."
flutter pub run flutter_launcher_icons
if [ $? -ne 0 ]; then
    echo "Error generating launcher icons. Please check your logo.png file."
    exit 1
fi

echo
echo "Success! Your app logo has been replaced."
echo
echo "To see the changes, run the app with:"
echo "flutter run"
echo
echo "For more information, see logo_replacement_guide.md"

echo
read -p "Press Enter to exit..."
