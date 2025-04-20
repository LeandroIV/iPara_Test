import 'dart:async';
import 'dart:convert';
import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'platform_map_service.dart';

/// Web specific implementation of the PlatformMapService
class WebMapService implements PlatformMapService {
  // Use the API key defined in web/index.html and web/js/api_config.js
  static const String _apiKey = 'AIzaSyDtm_kDatDOlKtvEMCA5lcVRFyTM6f6NNk';

  @override
  Future<List<dynamic>> searchPlaces(
    String query,
    double lat,
    double lng,
  ) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=$query&location=$lat,$lng&radius=50000&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'];
        } else {
          print('Error in place search: ${data['status']}');
          return [];
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception in searchPlaces: $e');
      return [];
    }
  }

  @override
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId&fields=name,formatted_address,geometry&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          return PlaceDetails(
            name: result['name'] ?? '',
            address: result['formatted_address'] ?? '',
            latitude: result['geometry']['location']['lat'],
            longitude: result['geometry']['location']['lng'],
          );
        } else {
          print('Error in place details: ${data['status']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception in getPlaceDetails: $e');
      return null;
    }
  }

  @override
  String getPlaceName(dynamic place) {
    try {
      // Log the place structure
      print('Web place structure for name extraction: $place');

      // Try different formats for place names in web responses
      final name =
          place['name'] ??
          place['structured_formatting']?['main_text'] ??
          place['description'] ??
          place['displayName']?['text'] ??
          place['formatted_address'] ??
          'Unknown Place';

      print('Web extracted name: $name');
      return name;
    } catch (e) {
      print('Error extracting place name: $e');
      return 'Unknown Place';
    }
  }

  @override
  String getPlaceAddress(dynamic place) {
    try {
      // Log the place structure
      print('Web place structure for address extraction: $place');

      // Try different formats for place addresses in web responses
      final address =
          place['formatted_address'] ??
          place['formattedAddress'] ??
          place['structured_formatting']?['secondary_text'] ??
          place['vicinity'] ??
          place['description'] ??
          '';

      print('Web extracted address: $address');
      return address;
    } catch (e) {
      print('Error extracting place address: $e');
      return '';
    }
  }

  @override
  String getPlaceId(dynamic place) {
    try {
      // Try different formats for place IDs in web responses
      return place['place_id'] ?? place['id'] ?? '';
    } catch (e) {
      print('Error extracting place ID: $e');
      return '';
    }
  }
}

/// Implementation of the factory for the web platform
PlatformMapService getPlatformMapService() {
  return WebMapService();
}
