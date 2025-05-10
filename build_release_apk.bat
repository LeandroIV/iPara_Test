@echo off
echo iPara Release APK Builder
echo =======================
echo.
echo This script will build a release APK that you can share with others.
echo.

echo Step 1: Cleaning the project...
call flutter clean
if %ERRORLEVEL% neq 0 (
    echo Error cleaning project. Error code: %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo Step 2: Getting dependencies...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo Error getting dependencies. Error code: %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo Step 3: Building release APK...
call flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo Error building release APK. Error code: %ERRORLEVEL%
    pause
    exit /b 1
)

echo.
echo Release APK built successfully!
echo.
echo You can find the APK at:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo Copy this file to share with others.
echo.
pause
