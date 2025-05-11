# iPara App Troubleshooting Guide

This guide will help you resolve common issues with the iPara app.

## Google Maps Loading Issues

If Google Maps doesn't load properly when you first open the app:

### Quick Fixes:

1. **Use the Refresh Button**: 
   - Tap the refresh button (circular arrow icon) on the map screen
   - This will reinitialize the map and often resolves loading issues

2. **Switch Roles and Switch Back**:
   - Go to the menu and select "Switch Role"
   - Select a different role (e.g., switch from Commuter to Driver)
   - Then switch back to your original role
   - This forces the map to reload completely

3. **Restart the App**:
   - Close the app completely (swipe it away from recent apps)
   - Open it again
   - The map should load properly on the second launch

### Advanced Fixes:

If the quick fixes don't work:

1. **Clear App Cache**:
   - Go to your device Settings > Apps > iPara > Storage
   - Tap "Clear Cache" (not "Clear Data" unless you want to log out)
   - Restart the app

2. **Check Internet Connection**:
   - Ensure you have a stable internet connection
   - Try switching between Wi-Fi and mobile data

3. **Run the Fix Script** (for developers):
   - Connect your device to your computer
   - Run the `fix_maps_loading.bat` script
   - This will reinstall the app with optimized settings

## App Logo Appears Zoomed

If the app logo appears zoomed in or cropped on your device:

1. **Update to the Latest Version**:
   - Make sure you have the latest version of the app
   - The latest version includes fixes for icon display issues

2. **For Developers**:
   - Run `flutter pub run flutter_launcher_icons` to regenerate app icons
   - This will create properly sized adaptive icons for Android

## Location Services Issues

If the app can't detect your location:

1. **Check Location Permissions**:
   - Go to your device Settings > Apps > iPara > Permissions
   - Ensure Location permission is set to "Allow all the time" or "Allow while using"

2. **Enable High Accuracy Mode**:
   - Go to your device Settings > Location
   - Enable "High accuracy" mode (uses GPS, Wi-Fi, and mobile networks)

3. **Restart Location Services**:
   - Turn off Location in your device settings
   - Wait 10 seconds
   - Turn Location back on
   - Restart the app

## General Performance Tips

For the best experience with iPara:

1. **Keep the App Updated**:
   - Always use the latest version of the app
   - Updates include performance improvements and bug fixes

2. **Optimize Your Device**:
   - Close other apps running in the background
   - Ensure your device has sufficient free storage space
   - Restart your device occasionally to clear memory

3. **Battery Optimization**:
   - Disable battery optimization for iPara in your device settings
   - This allows the app to maintain location services properly

## Contact Support

If you continue to experience issues:

- Email: support@ipara.com
- In-app: Go to Settings > Help & Support > Report an Issue
