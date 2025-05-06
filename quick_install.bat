@echo off
echo Installing iPara app...

:: Set your application ID (from build.gradle.kts)
set APP_ID=com.example.ipara_new

:: Check if ADB is in PATH, otherwise use the hardcoded path
where adb >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set ADB_CMD=adb
) else (
    set ADB_CMD=C:\Users\HP\AppData\Local\Android\sdk\platform-tools\adb.exe
)

:: List available devices
echo Available devices:
%ADB_CMD% devices
echo.

:: Ask user if they want to specify a device
set /p USE_SPECIFIC_DEVICE="Do you want to specify a device? (y/n): "
if /i "%USE_SPECIFIC_DEVICE%"=="y" (
    set /p DEVICE_ID="Enter device ID from the list above: "
    set ADB_DEVICE_PARAM=-s %DEVICE_ID%
) else (
    set ADB_DEVICE_PARAM=
)

:: Install the APK using ADB
echo Installing APK...
%ADB_CMD% %ADB_DEVICE_PARAM% install -r "android\app\build\outputs\apk\debug\app-debug.apk"

:: Check if installation was successful
if %ERRORLEVEL% neq 0 (
    echo Error installing APK.
    pause
    exit /b 1
)

:: Launch the app
echo Launching app...
%ADB_CMD% %ADB_DEVICE_PARAM% shell am start -n %APP_ID%/com.example.ipara_new.MainActivity

echo App launched successfully!
pause
