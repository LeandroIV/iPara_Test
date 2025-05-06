@echo off
echo Flutter iPara App Installer
echo =======================
echo.

echo Step 1: Checking available devices...
flutter devices
echo.

set /p USE_SPECIFIC_DEVICE="Do you want to specify a device? (y/n): "
if /i "%USE_SPECIFIC_DEVICE%"=="y" (
    set /p DEVICE_ID="Enter device ID from the list above: "
    set DEVICE_PARAM=-d %DEVICE_ID%
) else (
    set DEVICE_PARAM=
)

echo.
echo Step 2: Installing the app...
flutter install %DEVICE_PARAM%
if %ERRORLEVEL% neq 0 (
    echo Error installing the app.
    pause
    exit /b 1
)

echo.
echo Step 3: Running the app...
flutter run %DEVICE_PARAM% --use-application-binary build\app\outputs\flutter-apk\app-debug.apk
if %ERRORLEVEL% neq 0 (
    echo.
    echo Alternative method: Running with direct APK path...
    flutter run %DEVICE_PARAM% --use-application-binary android\app\build\outputs\apk\debug\app-debug.apk
)

echo.
echo App installation process completed!
echo.
pause
