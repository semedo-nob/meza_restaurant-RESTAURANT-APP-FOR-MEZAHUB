/*
import 'package:cloud_firestore/cloud_firestore.dart';

import 'direction_service.dart';
import 'location_service.dart';

class DeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final DirectionsService _directionsService;

  DeliveryService(String apiKey) : _directionsService = DirectionsService(apiKey);

  // Calculate delivery fee based on distance
  Future<double> calculateDeliveryFee({
    required double restaurantLat,
    required double restaurantLng,
    required double deliveryLat,
    required double deliveryLng,
  }) async {
    final double distance = _locationService.calculateDistance(
      restaurantLat,
      restaurantLng,
      deliveryLat,
      deliveryLng,
    );

    // Base fee + distance-based fee
    const double baseFee = 2.0; // $2 base fee
    const double perKmFee = 1.5; // $1.5 per km

    return baseFee + (distance * perKmFee);
  }

  // Update delivery status and location
  Future<void> updateDeliveryStatus({
    required String orderId,
    required String status,
    required double? lat,
    required double? lng,
  }) async {
    final updateData = <String, dynamic>{
      'deliveryStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (lat != null && lng != null) {
      updateData['currentLocation'] = GeoPoint(lat, lng);
    }

    await _firestore.collection('orders').doc(orderId).update(updateData);
  }

  // Track delivery in real-time
  Stream<DocumentSnapshot> trackDelivery(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots();
  }

  // Get optimal delivery route for multiple orders
  Future<Map<String, dynamic>> getOptimalRoute({
    required double startLat,
    required double startLng,
    required List<Map<String, dynamic>> deliveries,
  }) async {
    if (deliveries.isEmpty) {
      throw Exception('No deliveries provided');
    }

    // Convert deliveries to waypoints
    final waypoints = deliveries.map((delivery) =>
    '${delivery['lat']},${delivery['lng']}').join('|');

    return await _directionsService.getDirections(
      originLat: startLat,
      originLng: startLng,
      destLat: startLat, // Return to start
      destLng: startLng,
      waypoints: 'optimize:true|$waypoints',
    );
  }
}*/
