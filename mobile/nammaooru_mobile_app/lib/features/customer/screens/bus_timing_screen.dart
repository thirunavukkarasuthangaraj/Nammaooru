import 'package:flutter/material.dart';
import '../../../core/theme/village_theme.dart';
import '../services/bus_timing_service.dart';

class BusTimingScreen extends StatefulWidget {
  const BusTimingScreen({super.key});

  @override
  State<BusTimingScreen> createState() => _BusTimingScreenState();
}

class _BusTimingScreenState extends State<BusTimingScreen> {
  final BusTimingService _busTimingService = BusTimingService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _busTimings = [];
  List<dynamic> _filteredTimings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedLocation = '';
  List<String> _locationOptions = [];

  @override
  void initState() {
    super.initState();
    _loadBusTimings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBusTimings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _busTimingService.getActiveBusTimings();

      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>? ?? [];
        // Extract unique locations
        final locations = <String>{};
        for (final t in data) {
          if (t['locationArea'] != null && t['locationArea'].toString().isNotEmpty) {
            locations.add(t['locationArea'].toString());
          }
        }

        setState(() {
          _busTimings = data;
          _filteredTimings = data;
          _locationOptions = locations.toList()..sort();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load bus timings';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to server';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final search = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredTimings = _busTimings.where((t) {
        // Location filter
        if (_selectedLocation.isNotEmpty && t['locationArea'] != _selectedLocation) {
          return false;
        }
        // Search filter
        if (search.isNotEmpty) {
          final busNumber = (t['busNumber'] ?? '').toString().toLowerCase();
          final busName = (t['busName'] ?? '').toString().toLowerCase();
          final routeFrom = (t['routeFrom'] ?? '').toString().toLowerCase();
          final routeTo = (t['routeTo'] ?? '').toString().toLowerCase();
          final viaStops = (t['viaStops'] ?? '').toString().toLowerCase();
          return busNumber.contains(search) ||
              busName.contains(search) ||
              routeFrom.contains(search) ||
              routeTo.contains(search) ||
              viaStops.contains(search);
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bus Timing', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: VillageTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildLocationFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: VillageTheme.primaryGreen,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilters(),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search bus number, route...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLocationFilter() {
    if (_locationOptions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildFilterChip('All', ''),
          ..._locationOptions.map((loc) => _buildFilterChip(loc, loc)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedLocation == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: VillageTheme.primaryGreen,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        side: BorderSide(color: isSelected ? VillageTheme.primaryGreen : Colors.grey[300]!),
        onSelected: (_) {
          setState(() {
            _selectedLocation = value;
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadBusTimings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VillageTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredTimings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty || _selectedLocation.isNotEmpty
                  ? 'No bus timings match your search'
                  : 'No bus timings available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBusTimings,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredTimings.length,
        itemBuilder: (context, index) => _buildBusCard(_filteredTimings[index]),
      ),
    );
  }

  Widget _buildBusCard(dynamic timing) {
    final busType = timing['busType'] ?? 'GOVERNMENT';
    final isGovt = busType == 'GOVERNMENT';
    final fare = timing['fare'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Bus number + type badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGovt ? Colors.blue[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isGovt ? Colors.blue[200]! : Colors.orange[200]!),
                  ),
                  child: Text(
                    timing['busNumber'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isGovt ? Colors.blue[800] : Colors.orange[800],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isGovt ? Colors.blue[700] : Colors.orange[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isGovt ? 'Govt' : 'Private',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                if (fare != null)
                  Text(
                    '₹${fare is double ? fare.toStringAsFixed(0) : fare}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                  ),
              ],
            ),

            if (timing['busName'] != null && timing['busName'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                timing['busName'],
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],

            const SizedBox(height: 12),

            // Route: From → To
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.green[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    timing['routeFrom'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    timing['departureTime'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: VillageTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),

            // Via stops
            if (timing['viaStops'] != null && timing['viaStops'].toString().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey[300]!, width: 2)),
                  ),
                  child: Text(
                    'via ${timing['viaStops']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              ),
            ],

            Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.red[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    timing['routeTo'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                if (timing['arrivalTime'] != null && timing['arrivalTime'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      timing['arrivalTime'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Footer: Operating days + Location
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _getOperatingDaysLabel(timing['operatingDays'] ?? 'DAILY'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  timing['locationArea'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getOperatingDaysLabel(String days) {
    switch (days) {
      case 'DAILY':
        return 'Daily';
      case 'WEEKDAYS':
        return 'Mon-Fri';
      case 'WEEKENDS':
        return 'Sat-Sun';
      default:
        return days;
    }
  }
}
