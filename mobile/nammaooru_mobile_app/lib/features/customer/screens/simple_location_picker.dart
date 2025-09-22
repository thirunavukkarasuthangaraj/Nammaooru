import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../widgets/save_address_dialog.dart';

class SimpleLocationPicker extends StatefulWidget {
  final String? currentLocation;

  const SimpleLocationPicker({
    super.key,
    this.currentLocation,
  });

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  final _addressController = TextEditingController();
  List<Map<String, dynamic>> _filteredLocations = [];

  // Predefined locations for quick selection
  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'T. Nagar, Chennai',
      'address': 'T. Nagar, Chennai, Tamil Nadu 600017',
      'lat': 13.0435,
      'lng': 80.2341,
    },
    {
      'name': 'Anna Nagar, Chennai',
      'address': 'Anna Nagar, Chennai, Tamil Nadu 600040',
      'lat': 13.0850,
      'lng': 80.2101,
    },
    {
      'name': 'Velachery, Chennai',
      'address': 'Velachery, Chennai, Tamil Nadu 600042',
      'lat': 12.9815,
      'lng': 80.2207,
    },
    {
      'name': 'Adyar, Chennai',
      'address': 'Adyar, Chennai, Tamil Nadu 600020',
      'lat': 13.0067,
      'lng': 80.2206,
    },
    {
      'name': 'Mylapore, Chennai',
      'address': 'Mylapore, Chennai, Tamil Nadu 600004',
      'lat': 13.0338,
      'lng': 80.2619,
    },
    {
      'name': 'Nungambakkam, Chennai',
      'address': 'Nungambakkam, Chennai, Tamil Nadu 600034',
      'lat': 13.0594,
      'lng': 80.2428,
    },
    {
      'name': 'Tambaram, Chennai',
      'address': 'Tambaram, Chennai, Tamil Nadu 600045',
      'lat': 12.9249,
      'lng': 80.1000,
    },
    {
      'name': 'Porur, Chennai',
      'address': 'Porur, Chennai, Tamil Nadu 600116',
      'lat': 13.0358,
      'lng': 80.1597,
    },
    {
      'name': 'OMR, Chennai',
      'address': 'Old Mahabalipuram Road, Chennai, Tamil Nadu 600119',
      'lat': 12.9698,
      'lng': 80.2444,
    },
    {
      'name': 'Guindy, Chennai',
      'address': 'Guindy, Chennai, Tamil Nadu 600032',
      'lat': 13.0097,
      'lng': 80.2209,
    },
  ];

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.currentLocation ?? '';
    _filteredLocations = List.from(_locations);
    _addressController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    _addressController.removeListener(_filterLocations);
    _addressController.dispose();
    super.dispose();
  }

  void _filterLocations() {
    final query = _addressController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = List.from(_locations);
      } else {
        _filteredLocations = _locations.where((location) {
          final name = location['name'].toLowerCase();
          final address = location['address'].toLowerCase();
          return name.contains(query) || address.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _selectLocation(Map<String, dynamic> location) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SaveAddressDialog(
        latitude: location['lat'],
        longitude: location['lng'],
        detectedAddress: location['address'],
        detectedCity: 'Chennai',
        detectedState: 'Tamil Nadu',
        detectedPincode: '600001',
      ),
    );

    if (result != null && result['success'] == true) {
      if (mounted) {
        Navigator.pop(context, result['fullAddress']);
      }
    }
  }

  void _useCustomLocation() {
    final customAddress = _addressController.text.trim();
    if (customAddress.isNotEmpty) {
      Navigator.pop(context, customAddress);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an address first'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _addressController,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Search location...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Add Custom Location Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _useCustomLocation(),
              icon: const Icon(Icons.edit_location, color: Colors.white),
              label: const Text(
                'Use Current Search as Address',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: VillageTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          // Quick Locations
          Expanded(
            child: _filteredLocations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No locations found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location = _filteredLocations[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VillageTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: VillageTheme.primaryGreen,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      location['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      location['address'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _selectLocation(location),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VillageTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Select'),
                    ),
                    onTap: () => _selectLocation(location),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}