import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:geolocator/geolocator.dart'; // Temporarily disabled
import '../models/delivery_fee.dart';
import '../config/api_config.dart';

class DeliveryFeeService {
  static DeliveryFeeService? _instance;

  DeliveryFeeService._internal();

  static DeliveryFeeService get instance {
    _instance ??= DeliveryFeeService._internal();
    return _instance!;
  }

  /// Calculate delivery fee based on coordinates
  Future<DeliveryFeeCalculation?> calculateDeliveryFee({
    required double shopLatitude,
    required double shopLongitude,
    required double customerLatitude,
    required double customerLongitude,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-fees/calculate');

      final requestBody = {
        'shopLat': shopLatitude,
        'shopLon': shopLongitude,
        'customerLat': customerLatitude,
        'customerLon': customerLongitude,
      };

      print('Calculating delivery fee for coordinates:');
      print('Shop: $shopLatitude, $shopLongitude');
      print('Customer: $customerLatitude, $customerLongitude');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Delivery fee calculation response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return DeliveryFeeCalculation.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to calculate delivery fee');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to calculate delivery fee');
      }
    } catch (e) {
      print('Error calculating delivery fee: $e');
      return null;
    }
  }

  // /// Calculate delivery fee using Position objects - Temporarily disabled
  // Future<DeliveryFeeCalculation?> calculateDeliveryFeeFromPositions({
  //   required Position shopPosition,
  //   required Position customerPosition,
  // }) async {
  //   return calculateDeliveryFee(
  //     shopLatitude: shopPosition.latitude,
  //     shopLongitude: shopPosition.longitude,
  //     customerLatitude: customerPosition.latitude,
  //     customerLongitude: customerPosition.longitude,
  //   );
  // }

  /// Get active delivery fee ranges
  Future<List<DeliveryFeeRange>> getActiveRanges() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/delivery-fees/active');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> rangesJson = data['data'] ?? [];
          return rangesJson.map((json) => DeliveryFeeRange.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get delivery fee ranges');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to get delivery fee ranges');
      }
    } catch (e) {
      print('Error getting delivery fee ranges: $e');
      return [];
    }
  }

  /// Calculate local distance (for comparison)
  double calculateLocalDistance({
    required double shopLatitude,
    required double shopLongitude,
    required double customerLatitude,
    required double customerLongitude,
  }) {
    // Simple distance calculation using the haversine formula - temporarily simplified
    double latDiff = (customerLatitude - shopLatitude).abs();
    double lonDiff = (customerLongitude - shopLongitude).abs();
    return (latDiff + lonDiff) * 111; // Rough approximation in kilometers
  }

  /// Get estimated delivery fee based on distance ranges
  Future<double> getEstimatedFee(double distanceKm) async {
    try {
      final ranges = await getActiveRanges();

      for (final range in ranges) {
        if (distanceKm >= range.minDistanceKm && distanceKm <= range.maxDistanceKm) {
          return range.deliveryFee;
        }
      }

      // If no range matches, return highest range fee
      if (ranges.isNotEmpty) {
        ranges.sort((a, b) => b.maxDistanceKm.compareTo(a.maxDistanceKm));
        return ranges.first.deliveryFee;
      }

      // Fallback fee
      return 50.0;
    } catch (e) {
      print('Error getting estimated fee: $e');
      return 50.0; // Default fallback
    }
  }
}