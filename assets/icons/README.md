# Custom Map Icons

This folder is for storing custom map marker icons for the iPara app.

## Recommended Icons

To use Google Maps-style icons, add the following files to this folder:

- `car.png` - For drivers/vehicles
- `person.png` - For commuters

## Icon Requirements

- Format: PNG with transparency
- Size: 48x48 pixels (recommended)
- Style: Simple, clear silhouettes that are recognizable at small sizes

## How to Use

Once you've added the icon files to this folder, the app will automatically use them for map markers. The code is already set up to look for these files.

In `lib/utils/marker_generator.dart` and `lib/widgets/home_map_widget.dart`, uncomment the following code:

```dart
// For drivers
return BitmapDescriptor.fromAssetImage(
  const ImageConfiguration(size: Size(48, 48)),
  'assets/icons/car.png',
);

// For commuters
return BitmapDescriptor.fromAssetImage(
  const ImageConfiguration(size: Size(48, 48)),
  'assets/icons/person.png',
);
```

## Resources

You can find suitable icons from:

1. [Google Material Icons](https://fonts.google.com/icons)
2. [Flutter Icons](https://api.flutter.dev/flutter/material/Icons-class.html)
3. [Icons8](https://icons8.com/)
4. [Flaticon](https://www.flaticon.com/)

Remember to ensure you have the right to use any icons you download.
