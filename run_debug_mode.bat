@echo off
echo iPara Debug Mode
echo =======================
echo.

echo Step 1: Running app in debug mode...
echo This will help identify where the app is getting stuck.
echo.
flutter run -t lib/main_debug.dart -v

echo.
echo Debug session completed!
echo.
pause
