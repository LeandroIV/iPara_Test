@echo off
echo iPara Google Drive Sharing Preparation
echo ====================================
echo.
echo This script will prepare your app for sharing via Google Drive.
echo.

echo Step 1: Checking for existing release APK...
echo Skipping build step since we know the APK already exists.

echo.
echo Step 2: Checking for APK file...
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    set APK_PATH=build\app\outputs\flutter-apk\app-release.apk
    echo APK found at: %APK_PATH%
) else if exist "android\app\build\outputs\apk\release\app-release.apk" (
    set APK_PATH=android\app\build\outputs\apk\release\app-release.apk
    echo APK found at: %APK_PATH%
) else (
    echo Warning: Could not find the release APK file in expected locations.
    echo Checking if iPara_app_release.apk already exists...

    if exist "iPara_app_release.apk" (
        echo Found existing iPara_app_release.apk
        exit /b 0
    ) else (
        echo Error: Could not find any release APK file.
        echo Please build the app first with: flutter build apk --release
        pause
        exit /b 1
    )
)

echo.
echo Step 3: Creating a copy with a descriptive name...
copy "%APK_PATH%" "iPara_app_release.apk"
if %ERRORLEVEL% neq 0 (
    echo Error copying the APK file.
    pause
    exit /b 1
)

echo.
echo Success! Your app is ready for sharing.
echo.
echo The APK file is located at:
echo %CD%\iPara_app_release.apk
echo.
echo Next steps:
echo 1. Upload this file to Google Drive
echo 2. Set sharing permissions to "Anyone with the link"
echo 3. Share the link with others
echo.
echo For detailed instructions, see the share_on_google_drive.md file.
echo.
pause
