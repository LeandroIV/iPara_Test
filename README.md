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
