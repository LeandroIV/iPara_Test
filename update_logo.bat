@echo off
echo iPara Logo Update Tool
echo =====================
echo.
echo This script will update your app logo and reinstall the app.
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
echo Step 3: Generating launcher icons...
flutter pub run flutter_launcher_icons
if %ERRORLEVEL% neq 0 (
    echo Error generating launcher icons.
    pause
    exit /b 1
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
echo Success! Your app has been updated with the new logo.
echo.
pause
