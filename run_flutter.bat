@echo off
echo Running iPara Flutter App
echo =======================
echo.

echo Step 1: Building the app...
cd android
call gradlew assembleDebug
cd ..

echo.
echo Step 2: Creating directory structure for Flutter...
mkdir -p build\app\outputs\flutter-apk 2>nul

echo.
echo Step 3: Copying APK to Flutter's expected location...
copy android\app\build\outputs\apk\debug\app-debug.apk build\app\outputs\flutter-apk\app-debug.apk

echo.
echo Step 4: Installing and running the app...
flutter install

echo.
echo App installed successfully!
echo.
pause
