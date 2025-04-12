# iPara - PUV Tracking App

A Flutter application for tracking public utility vehicles (PUVs) in real-time.

## Requirements

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Google Maps API Key
- Firebase project setup

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone [your-repository-url]
   cd ipara
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Maps API Key**
   - For Android: Update `android/app/src/main/AndroidManifest.xml`
   - For iOS: Update `ios/Runner/AppDelegate.swift`
   - For Web: Update `web/index.html`

4. **Configure Firebase**
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the configuration files:
     - Android: `google-services.json` to `android/app/`
     - iOS: `GoogleService-Info.plist` to `ios/Runner/`

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Business logic and services
├── widgets/         # Reusable UI components
└── main.dart        # Entry point
```

## Features

- Real-time PUV tracking
- User location tracking
- Interactive map interface
- Route information
- Estimated arrival times

## Dependencies

Key dependencies are listed in `pubspec.yaml`:

- `google_maps_flutter`: ^2.5.3
- `geolocator`: ^10.1.0
- `firebase_core`: ^2.0.0
- `cloud_firestore`: ^4.0.0
- `permission_handler`: ^11.3.0

## Platform Support

- Android
- iOS
- Web

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## API Keys and Security

To maintain security of API keys and sensitive credentials, this project follows these best practices:

### Setting Up API Keys

#### 1. Flutter/Dart Configuration
1. Create a copy of `lib/config/api_keys.template.dart` and name it `lib/config/api_keys.dart`
2. Replace the placeholders in this file with your actual API keys:
   ```dart
   class ApiKeys {
     static const String googleMapsAndroid = 'YOUR_ANDROID_MAPS_API_KEY';
     static const String googleMapsIOS = 'YOUR_IOS_MAPS_API_KEY';
     static const String googleMapsWeb = 'YOUR_WEB_MAPS_API_KEY';
   }
   ```

#### 2. Android-specific setup:
1. Create or edit the `android/local.properties` file (already in `.gitignore`)
2. Add your Google Maps API key: `MAPS_API_KEY=your_actual_key_here`
3. The build system will automatically use this key in your app

#### 3. iOS-specific setup:
1. Create or edit `ios/Runner/AppDelegate.swift`
2. Replace the API key in `GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY")`
3. Make sure `GoogleService-Info.plist` is in the correct location and not committed to git

#### 4. Web-specific setup:
1. Create a copy of `web/js/api_config.template.js` and name it `web/js/api_config.js`
2. Replace the placeholder with your web API key:
   ```javascript
   const API_CONFIG = {
     googleMapsApiKey: 'YOUR_WEB_MAPS_API_KEY'
   };
   ```
3. Update `web/index.html` to use the API key from the config file:
   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_MAPS_API_KEY&libraries=places"></script>
   ```

### API Keys needed for this project:

- **Google Maps API Keys**:
  - Android: For map functionality on Android devices
  - iOS: For map functionality on iOS devices
  - Web: For map functionality in web browsers
- **Firebase API Keys**: These are in your `google-services.json` and `GoogleService-Info.plist` files

### For collaborators:

Ask the project owner for the API keys to set up your local development environment. Never commit these keys to the repository, even if it's private.

## Alternative: Using environment variables

For CI/CD systems or production deployments, you can also use environment variables:

1. Create a `.env` file at the root of the project
2. Add your API keys in the format:
   ```
   GOOGLE_MAPS_ANDROID_API_KEY=your_android_key
   GOOGLE_MAPS_IOS_API_KEY=your_ios_key
   GOOGLE_MAPS_WEB_API_KEY=your_web_key
   ```
3. Use a package like `flutter_dotenv` to load these variables

This approach is recommended for deployment pipelines where you can securely store environment variables.

## Important security reminder

Even with a private repository:
- API keys in Git history can be exposed if the repository becomes public
- API keys can be accessed by anyone with repository access
- Removing keys later still leaves them in Git history

Always use the approach outlined above to keep your keys secure.
