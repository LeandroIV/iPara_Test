@echo off
echo iPara App Manager
echo ================
echo.

:: Set your application ID (from build.gradle.kts)
set APP_ID=com.example.ipara_new

:: Set ADB path
set ADB_PATH=C:\Users\HP\AppData\Local\Android\sdk\platform-tools\adb.exe
set EMULATOR_ID=emulator-5554

echo Choose an option:
echo 1. Build and install app (full process)
echo 2. Install existing APK only
echo 3. Launch app only
echo 4. Exit
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" (
    call :build_and_install
) else if "%choice%"=="2" (
    call :install_only
) else if "%choice%"=="3" (
    call :launch_only
) else if "%choice%"=="4" (
    exit /b 0
) else (
    echo Invalid choice. Please try again.
    pause
    exit /b 1
)

exit /b 0

:build_and_install
echo.
echo Building and installing iPara app...
echo.

:: Build the APK
echo Building APK...
flutter build apk --debug

:: Check if build was successful
if %ERRORLEVEL% neq 0 (
    echo Error building APK.
    pause
    exit /b 1
)

:: Install the APK
echo Installing APK...
"%ADB_PATH%" -s %EMULATOR_ID% install -r "build\app\outputs\flutter-apk\app-debug.apk"

:: Check if installation was successful
if %ERRORLEVEL% neq 0 (
    echo Error installing APK.
    pause
    exit /b 1
)

:: Launch the app
echo Launching app...
"%ADB_PATH%" -s %EMULATOR_ID% shell am start -n %APP_ID%/com.example.ipara_new.MainActivity

echo App built, installed, and launched successfully!
pause
exit /b 0

:install_only
echo.
echo Installing existing iPara APK...
echo.

:: Install the APK
echo Installing APK...
"%ADB_PATH%" -s %EMULATOR_ID% install -r "android\app\build\outputs\apk\debug\app-debug.apk"

:: Check if installation was successful
if %ERRORLEVEL% neq 0 (
    echo Error installing APK. Trying alternative path...
    "%ADB_PATH%" -s %EMULATOR_ID% install -r "build\app\outputs\flutter-apk\app-debug.apk"
    
    if %ERRORLEVEL% neq 0 (
        echo Error installing APK from alternative path.
        pause
        exit /b 1
    )
)

:: Launch the app
echo Launching app...
"%ADB_PATH%" -s %EMULATOR_ID% shell am start -n %APP_ID%/com.example.ipara_new.MainActivity

echo App installed and launched successfully!
pause
exit /b 0

:launch_only
echo.
echo Launching iPara app...
echo.

:: Launch the app
echo Launching app...
"%ADB_PATH%" -s %EMULATOR_ID% shell am start -n %APP_ID%/com.example.ipara_new.MainActivity

echo App launched successfully!
pause
exit /b 0
