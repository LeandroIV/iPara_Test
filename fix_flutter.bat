@echo off
echo Fixing Flutter APK Issue
echo =======================
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
echo Step 3: Modifying build.gradle.kts...
echo Removing custom buildDir setting...

echo.
echo Step 4: Running the app directly...
flutter run --no-build-outputs-check
if %ERRORLEVEL% neq 0 (
    echo Error running the app.
    pause
    exit /b 1
)

echo.
echo App should be running now!
echo.
pause
