import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServiceAreaDialog extends StatefulWidget {
  final String message;
  final double? radiusKm;
  final double? centerLat;
  final double? centerLng;
  final double? userLat;
  final double? userLng;

  const ServiceAreaDialog({
    Key? key,
    required this.message,
    this.radiusKm,
    this.centerLat,
    this.centerLng,
    this.userLat,
    this.userLng,
  }) : super(key: key);

  @override
  State<ServiceAreaDialog> createState() => _ServiceAreaDialogState();
}

class _ServiceAreaDialogState extends State<ServiceAreaDialog>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  Set<Circle> get _circles {
    if (widget.centerLat == null || widget.centerLng == null) return {};
    return {
      Circle(
        circleId: const CircleId('service_area'),
        center: LatLng(widget.centerLat!, widget.centerLng!),
        radius: (widget.radiusKm ?? 50) * 1000,
        fillColor: Colors.green.withOpacity(0.1),
        strokeColor: Colors.green,
        strokeWidth: 2,
      ),
    };
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    if (widget.centerLat != null && widget.centerLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('center'),
        position: LatLng(widget.centerLat!, widget.centerLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Service Area Center'),
      ));
    }
    if (widget.userLat != null && widget.userLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: LatLng(widget.userLat!, widget.userLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    }
    return markers;
  }

  double? get _distanceKm {
    if (widget.userLat == null || widget.userLng == null ||
        widget.centerLat == null || widget.centerLng == null) return null;
    return _haversineKm(
      widget.userLat!, widget.userLng!,
      widget.centerLat!, widget.centerLng!,
    );
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * pi / 180;

  LatLngBounds? get _mapBounds {
    if (widget.centerLat == null || widget.centerLng == null) return null;
    final radiusDeg = (widget.radiusKm ?? 50) / 111.0;
    final extra = widget.userLat != null
        ? max(radiusDeg, (widget.userLat! - widget.centerLat!).abs() * 1.3)
        : radiusDeg;
    return LatLngBounds(
      southwest: LatLng(widget.centerLat! - extra, widget.centerLng! - extra),
      northeast: LatLng(widget.centerLat! + extra, widget.centerLng! + extra),
    );
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_off,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Service Not Available',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Stats row
              if (_distanceKm != null || widget.radiusKm != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFFFFF3E0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.radiusKm != null)
                        _statChip(
                          Icons.radar,
                          'Service Radius',
                          '${widget.radiusKm!.toInt()} km',
                          Colors.green,
                        ),
                      if (_distanceKm != null)
                        _statChip(
                          Icons.near_me,
                          'You Are',
                          '${_distanceKm!.toStringAsFixed(1)} km away',
                          Colors.red,
                        ),
                    ],
                  ),
                ),

              // Map
              Expanded(
                child: Stack(
                  children: [
                    if (widget.centerLat != null && widget.centerLng != null)
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                              widget.centerLat!, widget.centerLng!),
                          zoom: 8,
                        ),
                        circles: _circles,
                        markers: _markers,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          final bounds = _mapBounds;
                          if (bounds != null) {
                            Future.delayed(const Duration(milliseconds: 500),
                                () {
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngBounds(bounds, 40),
                              );
                            });
                          }
                        },
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('Map not available',
                                style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      ),

                    // Map legend
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _legendItem(Colors.green, 'Service Area'),
                            const SizedBox(height: 4),
                            _legendItem(Colors.red, 'Your Location'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom message
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                color: Colors.white,
                child: const Text(
                  'Please move into the service area (green circle) to use NammaOoru.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(
      IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
