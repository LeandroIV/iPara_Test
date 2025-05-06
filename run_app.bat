@echo off
echo Building and running iPara app...

:: Set your application ID (from build.gradle.kts)
set APP_ID=com.example.ipara_new

:: Build the APK (using Flutter but only the build step)
echo Building APK...
flutter build apk --debug

:: Check if build was successful
if %ERRORLEVEL% neq 0 (
    echo Error building APK.
    pause
    exit /b 1
)

:: Create directory structure if it doesn't exist
echo Creating directory structure...
mkdir -p build\app\outputs\flutter-apk 2>nul

:: Copy the APK to the expected location
echo Copying APK to expected location...
copy android\app\build\outputs\apk\debug\app-debug.apk build\app\outputs\flutter-apk\app-debug.apk

:: Check if copy was successful
if %ERRORLEVEL% neq 0 (
    echo Error copying APK.
    pause
    exit /b 1
)

:: Install the APK using ADB
echo Installing APK...
adb install -r "build\app\outputs\flutter-apk\app-debug.apk"

:: Check if installation was successful
if %ERRORLEVEL% neq 0 (
    echo Error installing APK.
    pause
    exit /b 1
)

:: Launch the app
echo Launching app...
adb shell am start -n %APP_ID%/com.example.ipara_new.MainActivity

echo App launched successfully!
pause
