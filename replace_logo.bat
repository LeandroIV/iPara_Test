@echo off
echo iPara Logo Replacement Tool
echo ===========================
echo.
echo This script will help you replace the app logo with your own.
echo.
echo Prerequisites:
echo 1. Your logo.png file should be ready
echo 2. Flutter should be installed and in your PATH
echo.
echo Press any key to continue...
pause > nul

echo.
echo Step 1: Installing dependencies...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo Error installing dependencies. Please make sure Flutter is installed correctly.
    goto :end
)

echo.
echo Step 2: Generating launcher icons...
call flutter pub run flutter_launcher_icons
if %ERRORLEVEL% neq 0 (
    echo Error generating launcher icons. Please check your logo.png file.
    goto :end
)

echo.
echo Success! Your app logo has been replaced.
echo.
echo To see the changes, run the app with:
echo flutter run
echo.
echo For more information, see logo_replacement_guide.md

:end
echo.
echo Press any key to exit...
pause > nul
