@echo off
echo iPara Maps Loading Fix Tool
echo =========================
echo.
echo This script will help fix Google Maps loading issues in the iPara app.
echo.

echo Step 1: Cleaning the project...
flutter clean
if %ERRORLEVEL% neq 0 (
    echo Error cleaning project.
    pause
    exit /b 1
)

echo.
echo Step 2: Getting dependencies...
flutter pub get
if %ERRORLEVEL% neq 0 (
    echo Error getting dependencies.
    pause
    exit /b 1
)

echo.
echo Step 3: Clearing app data (this will log you out)...
adb shell pm clear com.example.ipara_new
if %ERRORLEVEL% neq 0 (
    echo Warning: Could not clear app data. You may need to do this manually.
)

echo.
echo Step 4: Building the app...
flutter build apk --debug
if %ERRORLEVEL% neq 0 (
    echo Error building APK.
    pause
    exit /b 1
)

echo.
echo Step 5: Installing the app...
adb install -r "build\app\outputs\flutter-apk\app-debug.apk"
if %ERRORLEVEL% neq 0 (
    echo Error installing APK. Trying alternative path...
    adb install -r "android\app\build\outputs\apk\debug\app-debug.apk"
    
    if %ERRORLEVEL% neq 0 (
        echo Error installing APK from alternative path.
        pause
        exit /b 1
    )
)

echo.
echo Step 6: Launching the app...
adb shell am start -n com.example.ipara_new/com.example.ipara_new.MainActivity
if %ERRORLEVEL% neq 0 (
    echo Error launching app.
    pause
    exit /b 1
)

echo.
echo Success! The app has been reinstalled with fixes for Google Maps loading.
echo.
echo If you still experience issues:
echo 1. Try switching between roles (commuter/driver) to force map reload
echo 2. Use the refresh button on the map
echo 3. Restart your device
echo.
pause
