import 'dart:convert';
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
  List<_RouteGroup> _routeGroups = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedLocation = '';
  List<String> _locationOptions = [];
  String? _expandedKey; // "routeIndex-timingIndex"

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
        final locations = <String>{};
        for (final t in data) {
          if (t['locationArea'] != null && t['locationArea'].toString().isNotEmpty) {
            locations.add(t['locationArea'].toString());
          }
        }

        setState(() {
          _busTimings = data;
          _locationOptions = locations.toList()..sort();
          _isLoading = false;
        });
        _applyFilters();
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

  int _parseTimeForSort(String time) {
    if (time.isEmpty) return 0;
    try {
      final t = time.toUpperCase().trim();
      final isPM = t.contains('PM');
      final cleaned = t.replaceAll(RegExp(r'[APM\s]'), '');
      final parts = cleaned.split(':');
      var hour = int.parse(parts[0]);
      final min = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return hour * 60 + min;
    } catch (_) {
      return 0;
    }
  }

  void _applyFilters() {
    final search = _searchController.text.toLowerCase().trim();

    final filtered = _busTimings.where((t) {
      if (_selectedLocation.isNotEmpty && t['locationArea'] != _selectedLocation) {
        return false;
      }
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

    // Group by route (from → to)
    final Map<String, List<dynamic>> groupMap = {};
    for (final t in filtered) {
      final from = (t['routeFrom'] ?? '').toString().trim();
      final to = (t['routeTo'] ?? '').toString().trim();
      final key = '$from → $to';
      groupMap.putIfAbsent(key, () => []);
      groupMap[key]!.add(t);
    }

    // Sort timings within each group by departure time
    final groups = <_RouteGroup>[];
    for (final entry in groupMap.entries) {
      entry.value.sort((a, b) {
        final timeA = _parseTimeForSort(a['departureTime'] ?? '');
        final timeB = _parseTimeForSort(b['departureTime'] ?? '');
        return timeA.compareTo(timeB);
      });
      groups.add(_RouteGroup(route: entry.key, timings: entry.value));
    }

    // Sort groups alphabetically by route
    groups.sort((a, b) => a.route.compareTo(b.route));

    setState(() {
      _routeGroups = groups;
      _expandedKey = null;
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

    if (_routeGroups.isEmpty) {
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _routeGroups.length,
        itemBuilder: (context, groupIndex) {
          return _buildRouteGroupCard(_routeGroups[groupIndex], groupIndex);
        },
      ),
    );
  }

  Widget _buildRouteGroupCard(_RouteGroup group, int groupIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.route,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${group.timings.length} bus${group.timings.length > 1 ? 'es' : ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Time list
          ...List.generate(group.timings.length, (timingIndex) {
            final timing = group.timings[timingIndex];
            final key = '$groupIndex-$timingIndex';
            final isExpanded = _expandedKey == key;
            final isLast = timingIndex == group.timings.length - 1;
            return _buildTimingRow(timing, key, isExpanded, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimingRow(dynamic timing, String key, bool isExpanded, bool isLast) {
    final busType = timing['busType'] ?? 'GOVERNMENT';
    final isGovt = busType == 'GOVERNMENT';
    final fare = timing['fare'];
    final depTime = timing['departureTime'] ?? '';
    final arrTime = timing['arrivalTime'] ?? '';
    final stops = _parseStops(timing['viaStops']?.toString());

    return Column(
      children: [
        // Compact row
        InkWell(
          onTap: () {
            setState(() {
              _expandedKey = isExpanded ? null : key;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Time column
                SizedBox(
                  width: 58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        depTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        arrTime,
                        style: TextStyle(fontSize: 11, color: Colors.red[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1, height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.grey[200],
                ),
                // Bus info
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isGovt ? Colors.blue[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isGovt ? Colors.blue[200]! : Colors.orange[200]!),
                        ),
                        child: Text(
                          timing['busNumber'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isGovt ? Colors.blue[800] : Colors.orange[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isGovt ? Colors.blue[700] : Colors.orange[700],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          isGovt ? 'Govt' : 'Pvt',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (stops.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${stops.length} stops',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
                // Fare + chevron
                if (fare != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '₹${fare is double ? fare.toStringAsFixed(0) : fare}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),

        // Expanded: full route timeline
        if (isExpanded)
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (timing['busName'] != null && timing['busName'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      timing['busName'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ),
                _buildRouteTimeline(timing, stops),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _getOperatingDaysLabel(timing['operatingDays'] ?? 'DAILY'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
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

        if (!isLast && !isExpanded) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  List<Map<String, String>> _parseStops(String? viaStops) {
    if (viaStops == null || viaStops.isEmpty) return [];
    try {
      final parsed = jsonDecode(viaStops);
      if (parsed is List) {
        return parsed.map<Map<String, String>>((s) => {
          'name': (s['name'] ?? '').toString(),
          'time': (s['time'] ?? '').toString(),
        }).where((s) => s['name']!.isNotEmpty).toList();
      }
    } catch (_) {
      if (viaStops.contains(',') || viaStops.trim().isNotEmpty) {
        return viaStops.split(',').map((s) => {
          'name': s.trim(),
          'time': '',
        }).where((s) => s['name']!.isNotEmpty).toList();
      }
    }
    return [];
  }

  Widget _buildRouteTimeline(dynamic timing, List<Map<String, String>> stops) {
    return Column(
      children: [
        _buildTimelineRow(
          color: Colors.green[600]!,
          dotSize: 10,
          name: timing['routeFrom'] ?? '',
          time: timing['departureTime'] ?? '',
          timeBg: const Color(0xFFE8F5E9),
          timeColor: const Color(0xFF2E7D32),
          isFirst: true,
          isLast: stops.isEmpty,
          isBold: true,
        ),
        for (int i = 0; i < stops.length; i++)
          _buildTimelineRow(
            color: Colors.orange[600]!,
            dotSize: 7,
            name: stops[i]['name'] ?? '',
            time: stops[i]['time'] ?? '',
            timeBg: const Color(0xFFFFF3E0),
            timeColor: const Color(0xFFE65100),
            isFirst: false,
            isLast: false,
            isBold: false,
          ),
        _buildTimelineRow(
          color: Colors.red[600]!,
          dotSize: 10,
          name: timing['routeTo'] ?? '',
          time: timing['arrivalTime'] ?? '',
          timeBg: const Color(0xFFFFEBEE),
          timeColor: const Color(0xFFC62828),
          isFirst: false,
          isLast: true,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildTimelineRow({
    required Color color,
    required double dotSize,
    required String name,
    required String time,
    required Color timeBg,
    required Color timeColor,
    required bool isFirst,
    required bool isLast,
    required bool isBold,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: Colors.grey[300]))
                else
                  const Expanded(child: SizedBox()),
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[300]))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isBold ? 6 : 4),
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  fontSize: isBold ? 14 : 13,
                  color: isBold ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
          ),
          if (time.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(vertical: isBold ? 4 : 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: timeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isBold ? 12 : 11,
                  color: timeColor,
                ),
              ),
            ),
        ],
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

class _RouteGroup {
  final String route;
  final List<dynamic> timings;

  _RouteGroup({required this.route, required this.timings});
}
