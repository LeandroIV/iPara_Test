# Logo Replacement Guide for iPara App

Follow these steps to replace the app logo with your own:

## Step 1: Prepare Your Logo

1. Create your logo as a PNG file with a transparent background
2. Make sure it's at least 512x512 pixels in size
3. Name it `logo.png`

## Step 2: Replace the Logo Files

1. Replace the existing logo file in the assets folder:
   - Navigate to `assets/logo.png`
   - Replace it with your new logo.png file

## Step 3: Generate Launcher Icons

1. Open a terminal in your project directory
2. Run the following command to install the dependencies:
   ```
   flutter pub get
   ```
3. Run the following command to generate the launcher icons:
   ```
   flutter pub run flutter_launcher_icons
   ```

This will automatically:
- Generate Android launcher icons in different sizes
- Generate iOS app icons in different sizes
- Update the necessary configuration files

## Step 4: Verify the Changes

1. Run the app to see your new logo in action:
   ```
   flutter run
   ```

2. Check the following screens to ensure your logo appears correctly:
   - Splash screen
   - Login screen
   - Welcome screen

## Troubleshooting

If your logo doesn't appear correctly:

1. Make sure your logo.png file is in the correct location (assets/logo.png)
2. Check that the logo has a transparent background
3. Try cleaning the project and rebuilding:
   ```
   flutter clean
   flutter pub get
   flutter pub run flutter_launcher_icons
   flutter run
   ```

## Additional Customization

If you want to customize the app name as well:

1. For Android:
   - Open `android/app/src/main/AndroidManifest.xml`
   - Change the `android:label="iPara"` to your desired app name

2. For iOS:
   - Open `ios/Runner/Info.plist`
   - Change the value of `CFBundleName` to your desired app name
