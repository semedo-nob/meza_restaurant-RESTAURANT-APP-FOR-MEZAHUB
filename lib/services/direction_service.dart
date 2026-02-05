/*
import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  final String apiKey;

  DirectionsService(this.apiKey);

  // Get route between origin and destination
  Future<Map<String, dynamic>> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? waypoints, // For multiple stops
  }) async {
    try {
      final String origin = '$originLat,$originLng';
      final String destination = '$destLat,$destLng';

      final Uri url = Uri.parse('$_baseUrl?'
          'origin=$origin&'
          'destination=$destination&'
          'key=$apiKey&'
          'mode=driving&' // driving, walking, bicycling, transit
          'alternatives=true&'
          'units=metric${waypoints != null ? '&waypoints=$waypoints' : ''}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return _parseDirections(data);
        } else {
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to fetch directions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting directions: $e');
    }
  }

  // Parse directions response
  Map<String, dynamic> _parseDirections(Map<String, dynamic> data) {
    final routes = data['routes'] as List;
    if (routes.isEmpty) {
      throw Exception('No routes found');
    }

    // Get the first route (you can modify to let user choose)
    final route = routes.first;
    final legs = route['legs'] as List;
    final leg = legs.first;

    // Parse polyline points for map drawing
    final overviewPolyline = route['overview_polyline']['points'];

    // Parse steps for turn-by-turn directions
    final steps = _parseSteps(leg['steps'] as List);

    return {
      'distance': leg['distance']['text'],
      'distanceMeters': leg['distance']['value'],
      'duration': leg['duration']['text'],
      'durationSeconds': leg['duration']['value'],
      'startAddress': leg['start_address'],
      'endAddress': leg['end_address'],
      'polylinePoints': overviewPolyline,
      'steps': steps,
      'bounds': _parseBounds(route['bounds']),
    };
  }

  // Parse route steps for turn-by-turn navigation
  List<Map<String, dynamic>> _parseSteps(List<dynamic> stepsData) {
    return stepsData.map<Map<String, dynamic>>((step) {
      return {
        'instruction': _stripHtml(step['html_instructions']),
        'distance': step['distance']['text'],
        'duration': step['duration']['text'],
        'startLocation': step['start_location'],
        'endLocation': step['end_location'],
        'polyline': step['polyline']['points'],
      };
    }).toList();
  }

  // Parse viewport bounds
  Map<String, dynamic> _parseBounds(Map<String, dynamic> bounds) {
    return {
      'northeast': bounds['northeast'],
      'southwest': bounds['southwest'],
    };
  }

  // Remove HTML tags from instructions
  String _stripHtml(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .trim();
  }

  // Calculate estimated delivery time
  Future<Duration> calculateETA({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final directions = await getDirections(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );

    final seconds = directions['durationSeconds'] as int;
    return Duration(seconds: seconds);
  }

  // Get distance matrix for multiple destinations
  Future<Map<String, dynamic>> getDistanceMatrix({
    required List<String> origins,
    required List<String> destinations,
  }) async {
    try {
      final String originsParam = origins.join('|');
      final String destinationsParam = destinations.join('|');

      final Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json?'
            'origins=$originsParam&'
            'destinations=$destinationsParam&'
            'key=$apiKey&'
            'mode=driving&'
            'units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch distance matrix: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting distance matrix: $e');
    }
  }
}*/
