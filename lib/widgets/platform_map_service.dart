import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// Place details model to store essential place information
class PlaceDetails {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

/// Platform interface for map services
/// This abstraction allows for platform-specific implementations
abstract class PlatformMapService {
  /// Search for places matching the given query
  /// Returns a list of place predictions
  Future<List<dynamic>> searchPlaces(String query, double lat, double lng);

  /// Get detailed information about a place
  /// Returns a PlaceDetails object or null if the place was not found
  Future<PlaceDetails?> getPlaceDetails(String placeId);

  /// Extract the main place name from a place prediction
  String getPlaceName(dynamic place);

  /// Extract the place address from a place prediction
  String getPlaceAddress(dynamic place);

  /// Extract the place ID from a place prediction
  String getPlaceId(dynamic place);
}

/// Factory function to get the appropriate platform implementation
/// This will be implemented differently on each platform
PlatformMapService getPlatformMapService() {
  throw UnimplementedError(
    'No default implementation for getPlatformMapService',
  );
}

// Implementation that works for both platforms
class MapService implements PlatformMapService {
  // Google Maps API key
  final String _apiKey = 'AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk';

  @override
  Future<List<dynamic>> searchPlaces(
    String query,
    double lat,
    double lng,
  ) async {
    try {
      print("MapService: Searching for places with query: $query");
      // Use the Google Maps Places API with the Places API Key
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.displayName,places.formattedAddress,places.location,places.id',
        },
        body: jsonEncode({
          'textQuery': query,
          'locationBias': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': 50000.0,
            },
          },
          'languageCode': 'en',
          'regionCode': 'PH',
        }),
      );

      print("MapService: Got API response with status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['places'] != null) {
          print("MapService: Found ${data['places'].length} places");
          return data['places'];
        } else {
          print("MapService: No places found in response: ${response.body}");
          // Create a fallback place as a map for testing
          return [
            {
              'id': 'fallback_1',
              'displayName': {'text': 'USTP Main Campus'},
              'formattedAddress': 'CM Recto Avenue, Cagayan de Oro City',
            },
            {
              'id': 'fallback_2',
              'displayName': {'text': 'SM City CDO'},
              'formattedAddress': 'Downtown, Cagayan de Oro City',
            },
          ];
        }
      }

      print("MapService: Error response from API: ${response.body}");
      // Create a fallback place as a map for error cases
      return [
        {
          'id': 'error_1',
          'displayName': {'text': 'Error Getting Places'},
          'formattedAddress': 'Try again with a different search',
        },
      ];
    } catch (e) {
      print('MapService: Error searching places: $e');
      // Create a fallback place for exception cases
      return [
        {
          'id': 'exception_1',
          'displayName': {'text': 'Connection Error'},
          'formattedAddress': 'Check your internet connection',
        },
      ];
    }
  }

  @override
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://places.googleapis.com/v1/places/$placeId'
          '?fields=id,displayName,formattedAddress,location'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final place = json.decode(response.body);
        final location = place['location'];
        final lat = location['latitude'];
        final lng = location['longitude'];
        final name = place['displayName']['text'];
        final address = place['formattedAddress'];

        return PlaceDetails(
          latitude: lat,
          longitude: lng,
          name: name,
          address: address,
        );
      }
      print(
        'Get place details returned status: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  @override
  String getPlaceName(dynamic place) {
    try {
      // Log the place structure to understand what fields are available
      print('Place structure for name extraction: $place');

      // Different APIs return different structures
      // Try all known formats to extract the name
      final name =
          place['displayName']?['text'] ?? // New Places API format
          place['name'] ?? // Places Details API format
          place['structured_formatting']?['main_text'] ?? // Autocomplete API format
          place['description'] ?? // Fallback for autocomplete
          place['formatted_address'] ?? // Another fallback
          'Unknown place';

      // Log the extracted name
      print('Extracted name: $name');
      return name;
    } catch (e) {
      print('Error getting place name: $e');
      return 'Unknown place';
    }
  }

  @override
  String getPlaceAddress(dynamic place) {
    try {
      // Log the place structure to understand what fields are available
      print('Place structure for address extraction: $place');

      // Different APIs return different structures
      // Try all known formats to extract the address
      final address =
          place['formattedAddress'] ?? // New Places API format
          place['formatted_address'] ?? // Places Details API format
          place['structured_formatting']?['secondary_text'] ?? // Autocomplete API format
          place['vicinity'] ?? // Nearby search format
          '';

      // Log the extracted address
      print('Extracted address: $address');
      return address;
    } catch (e) {
      print('Error getting place address: $e');
      return '';
    }
  }

  @override
  String getPlaceId(dynamic place) {
    try {
      // Try different possible structures for place IDs
      return place['id'] ?? // New Places API format
          place['place_id'] ?? // Classic Places API format
          '';
    } catch (e) {
      print('Error getting place ID: $e');
      return '';
    }
  }
}

// Factory to create the service
PlatformMapService createPlatformMapService() {
  return MapService();
}
