@echo off
echo iPara App Runner with Direct APK
echo =======================
echo.

echo Step 1: Building the app...
cd android
call gradlew assembleDebug
cd ..

echo.
echo Step 2: Installing the APK directly...
flutter install --use-application-binary android\app\build\outputs\apk\debug\app-debug.apk

echo.
echo App installed successfully!
echo.
pause
