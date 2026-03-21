import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class MapsService {
  static final Completer<GoogleMapController> _controller = Completer();
  static Set<Marker> _markers = {};
  static Set<Polyline> _polylines = {};
  static Set<Polygon> _polygons = {};
  static Set<Circle> _circles = {};
  
  static Future<GoogleMapController> get controller async {
    return await _controller.future;
  }
  
  static Set<Marker> get markers => _markers;
  static Set<Polyline> get polylines => _polylines;
  static Set<Polygon> get polygons => _polygons;
  static Set<Circle> get circles => _circles;
  
  static void onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }
  
  static Future<void> moveCamera(LatLng target, {double zoom = 14.0}) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
        ),
      ),
    );
  }
  
  static Future<void> moveCameraToCurrentLocation({double zoom = 14.0}) async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      await moveCamera(
        LatLng(position.latitude, position.longitude),
        zoom: zoom,
      );
    }
  }
  
  static Future<void> fitBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
    
    final GoogleMapController controller = await _controller.future;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }
  
  static void addMarker({
    required String markerId,
    required LatLng position,
    required String infoWindow,
    BitmapDescriptor? icon,
    VoidCallback? onTap,
  }) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(title: infoWindow),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: onTap,
    );
    
    _markers.add(marker);
  }
  
  static void removeMarker(String markerId) {
    _markers.removeWhere((marker) => marker.markerId.value == markerId);
  }
  
  static void clearMarkers() {
    _markers.clear();
  }
  
  static void addPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color color = Colors.blue,
    double width = 5.0,
    List<PatternItem> patterns = const [],
  }) {
    final polyline = Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color,
      width: width.toInt(),
      patterns: patterns,
    );
    
    _polylines.add(polyline);
  }
  
  static void removePolyline(String polylineId) {
    _polylines.removeWhere((polyline) => polyline.polylineId.value == polylineId);
  }
  
  static void clearPolylines() {
    _polylines.clear();
  }
  
  static void addPolygon({
    required String polygonId,
    required List<LatLng> points,
    Color fillColor = Colors.blue,
    Color strokeColor = Colors.blue,
    double strokeWidth = 2.0,
  }) {
    final polygon = Polygon(
      polygonId: PolygonId(polygonId),
      points: points,
      fillColor: fillColor.withOpacity(0.3),
      strokeColor: strokeColor,
      strokeWidth: strokeWidth.toInt(),
    );
    
    _polygons.add(polygon);
  }
  
  static void removePolygon(String polygonId) {
    _polygons.removeWhere((polygon) => polygon.polygonId.value == polygonId);
  }
  
  static void clearPolygons() {
    _polygons.clear();
  }
  
  static void addCircle({
    required String circleId,
    required LatLng center,
    required double radius,
    Color fillColor = Colors.blue,
    Color strokeColor = Colors.blue,
    double strokeWidth = 2.0,
  }) {
    final circle = Circle(
      circleId: CircleId(circleId),
      center: center,
      radius: radius,
      fillColor: fillColor.withOpacity(0.3),
      strokeColor: strokeColor,
      strokeWidth: strokeWidth.toInt(),
    );
    
    _circles.add(circle);
  }
  
  static void removeCircle(String circleId) {
    _circles.removeWhere((circle) => circle.circleId.value == circleId);
  }
  
  static void clearCircles() {
    _circles.clear();
  }
  
  static void clearAll() {
    clearMarkers();
    clearPolylines();
    clearPolygons();
    clearCircles();
  }
  
  static Future<BitmapDescriptor> createCustomMarkerIcon({
    required String assetPath,
    int width = 100,
    int height = 100,
  }) async {
    return await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(width.toDouble(), height.toDouble())),
      assetPath,
    );
  }
  
  static Future<BitmapDescriptor> createColoredMarkerIcon(Color color) async {
    final hue = HSVColor.fromColor(color).hue;
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }
  
  static LatLng calculateMidpoint(LatLng point1, LatLng point2) {
    final lat = (point1.latitude + point2.latitude) / 2;
    final lng = (point1.longitude + point2.longitude) / 2;
    return LatLng(lat, lng);
  }
  
  static double calculateDistanceBetweenPoints(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
  
  static Future<LatLngBounds> getVisibleRegion() async {
    final GoogleMapController controller = await _controller.future;
    return await controller.getVisibleRegion();
  }
  
  static Future<void> takeSnapshot() async {
    final GoogleMapController controller = await _controller.future;
    await controller.takeSnapshot();
  }
  
  static CameraPosition getInitialCameraPosition({
    LatLng? target,
    double zoom = 14.0,
  }) {
    return CameraPosition(
      target: target ?? const LatLng(13.0827, 80.2707), // Chennai coordinates
      zoom: zoom,
    );
  }
  
  static void addUserLocationMarker(LatLng position) {
    addMarker(
      markerId: 'user_location',
      position: position,
      infoWindow: 'Your Location',
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }
  
  static void addShopMarker({
    required String shopId,
    required LatLng position,
    required String shopName,
    VoidCallback? onTap,
  }) {
    addMarker(
      markerId: 'shop_$shopId',
      position: position,
      infoWindow: shopName,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      onTap: onTap,
    );
  }
  
  static void addDeliveryPartnerMarker({
    required String deliveryPartnerId,
    required LatLng position,
    required String partnerName,
    VoidCallback? onTap,
  }) {
    addMarker(
      markerId: 'delivery_$deliveryPartnerId',
      position: position,
      infoWindow: partnerName,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      onTap: onTap,
    );
  }
  
  static void drawDeliveryRoute(List<LatLng> routePoints) {
    addPolyline(
      polylineId: 'delivery_route',
      points: routePoints,
      color: Colors.blue,
      width: 5.0,
    );
  }
  
  static void showDeliveryArea({
    required LatLng center,
    required double radiusInMeters,
  }) {
    addCircle(
      circleId: 'delivery_area',
      center: center,
      radius: radiusInMeters,
      fillColor: Colors.blue,
      strokeColor: Colors.blue,
      strokeWidth: 2.0,
    );
  }
}

import 'dart:math' as math;