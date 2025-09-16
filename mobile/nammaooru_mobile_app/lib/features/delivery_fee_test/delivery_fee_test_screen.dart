import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';
import '../../core/services/delivery_fee_service.dart';
import '../../core/models/delivery_fee.dart';

class DeliveryFeeTestScreen extends StatefulWidget {
  const DeliveryFeeTestScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryFeeTestScreen> createState() => _DeliveryFeeTestScreenState();
}

class _DeliveryFeeTestScreenState extends State<DeliveryFeeTestScreen> {
  Position? _currentPosition;
  DeliveryFeeCalculation? _feeCalculation;
  List<DeliveryFeeRange> _feeRanges = [];
  String? _currentAddress;
  bool _isLoading = false;
  String? _errorMessage;

  // Example shop coordinates (you can change these)
  final double _shopLatitude = 12.9716; // Bangalore coordinates
  final double _shopLongitude = 77.5946;

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFeeRanges();
  }

  Future<void> _loadFeeRanges() async {
    try {
      final ranges = await DeliveryFeeService.instance.getActiveRanges();
      setState(() {
        _feeRanges = ranges;
      });
    } catch (e) {
      print('Error loading fee ranges: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Position? position = await LocationService.instance.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _latController.text = position.latitude.toStringAsFixed(6);
          _lngController.text = position.longitude.toStringAsFixed(6);
        });

        // Get address from coordinates
        String? address = await LocationService.instance.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _currentAddress = address;
          _addressController.text = address ?? '';
        });

        // Calculate delivery fee
        await _calculateDeliveryFee();
      } else {
        setState(() {
          _errorMessage = 'Failed to get current location';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateDeliveryFee() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      DeliveryFeeCalculation? calculation = await DeliveryFeeService.instance.calculateDeliveryFee(
        shopLatitude: _shopLatitude,
        shopLongitude: _shopLongitude,
        customerLatitude: _currentPosition!.latitude,
        customerLongitude: _currentPosition!.longitude,
      );

      setState(() {
        _feeCalculation = calculation;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error calculating fee: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _useManualCoordinates() async {
    try {
      double lat = double.parse(_latController.text);
      double lng = double.parse(_lngController.text);

      Position manualPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      setState(() {
        _currentPosition = manualPosition;
      });

      await _calculateDeliveryFee();
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid coordinates: $e';
      });
    }
  }

  Future<void> _useAddressCoordinates() async {
    if (_addressController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Position? position = await LocationService.instance.getCoordinatesFromAddress(_addressController.text);
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _latController.text = position.latitude.toStringAsFixed(6);
          _lngController.text = position.longitude.toStringAsFixed(6);
        });

        await _calculateDeliveryFee();
      } else {
        setState(() {
          _errorMessage = 'Could not find coordinates for this address';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error geocoding address: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Fee Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Location Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop Location',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Latitude: $_shopLatitude'),
                    Text('Longitude: $_shopLongitude'),
                    Text('Address: Bangalore, Karnataka'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current Location Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Location',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Get current location button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Current Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Manual coordinates input
                    const Text('Or enter coordinates manually:'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _lngController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _useManualCoordinates,
                        child: const Text('Use Manual Coordinates'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Address input
                    const Text('Or enter address:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        hintText: 'Enter full address...',
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _useAddressCoordinates,
                        child: const Text('Use Address'),
                      ),
                    ),

                    if (_currentAddress != null) ...[
                      const SizedBox(height: 16),
                      Text('Current Address: $_currentAddress'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Delivery Fee Calculation Results
            if (_feeCalculation != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Fee Calculation',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Distance:', style: TextStyle(fontSize: 16)),
                          Text(
                            '${_feeCalculation!.distance.toStringAsFixed(2)} km',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Fee:', style: TextStyle(fontSize: 16)),
                          Text(
                            '₹${_feeCalculation!.deliveryFee.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Partner Commission:', style: TextStyle(fontSize: 14)),
                          Text(
                            '₹${_feeCalculation!.partnerCommission.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Fee Ranges Display
            if (_feeRanges.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Fee Ranges',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._feeRanges.map((range) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(range.distanceRangeText),
                            Text(
                              '₹${range.deliveryFee.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}