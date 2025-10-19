import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service_simple.dart';

class BusinessHoursScreen extends StatefulWidget {
  final String token;

  const BusinessHoursScreen({
    super.key,
    required this.token,
  });

  @override
  State<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<BusinessHoursScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  int? _shopId;
  Map<String, dynamic>? _shopStatus;

  final List<Map<String, dynamic>> _businessHours = [
    {
      'dayOfWeek': 'MONDAY',
      'displayName': 'Monday',
      'openTime': '09:00',
      'closeTime': '18:00',
      'isOpen': true,
    },
    {
      'dayOfWeek': 'TUESDAY',
      'displayName': 'Tuesday',
      'openTime': '09:00',
      'closeTime': '18:00',
      'isOpen': true,
    },
    {
      'dayOfWeek': 'WEDNESDAY',
      'displayName': 'Wednesday',
      'openTime': '09:00',
      'closeTime': '18:00',
      'isOpen': true,
    },
    {
      'dayOfWeek': 'THURSDAY',
      'displayName': 'Thursday',
      'openTime': '09:00',
      'closeTime': '18:00',
      'isOpen': true,
    },
    {
      'dayOfWeek': 'FRIDAY',
      'displayName': 'Friday',
      'openTime': '09:00',
      'closeTime': '18:00',
      'isOpen': true,
    },
    {
      'dayOfWeek': 'SATURDAY',
      'displayName': 'Saturday',
      'openTime': '09:00',
      'closeTime': '18:00',
      'isOpen': true,
    },
    {
      'dayOfWeek': 'SUNDAY',
      'displayName': 'Sunday',
      'openTime': '09:00',
      'closeTime': '18:00',
      'isOpen': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessHours();
  }

  Future<void> _loadBusinessHours() async {
    setState(() => _isLoading = true);

    try {
      // Get shop ID first
      final shopResponse = await ApiService.getMyShop();
      if (!shopResponse.isSuccess || shopResponse.data == null) {
        _showError('Failed to fetch shop information');
        return;
      }

      final shopData = shopResponse.data['data'] ?? shopResponse.data;
      _shopId = shopData['id'];

      if (_shopId == null) {
        _showError('Shop ID not found');
        return;
      }

      // Load business hours
      final response = await ApiService.getBusinessHours(_shopId!);
      if (response.isSuccess && response.data != null) {
        final hours = response.data as List;

        // Update business hours with server data
        for (var hour in hours) {
          final dayOfWeek = hour['dayOfWeek'];
          final index = _businessHours.indexWhere((h) => h['dayOfWeek'] == dayOfWeek);

          if (index != -1) {
            setState(() {
              _businessHours[index]['id'] = hour['id'];
              _businessHours[index]['openTime'] = _formatTime(hour['openTime']);
              _businessHours[index]['closeTime'] = _formatTime(hour['closeTime']);
              _businessHours[index]['isOpen'] = hour['isOpen'] ?? true;
            });
          }
        }

        // Load shop status
        await _loadShopStatus();
      } else {
        // No hours exist, create defaults
        await _createDefaultHours();
      }
    } catch (e) {
      print('Error loading business hours: $e');
      _showError('Failed to load business hours');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadShopStatus() async {
    if (_shopId == null) return;

    try {
      final response = await ApiService.getShopStatus(_shopId!);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _shopStatus = response.data;
        });
      }
    } catch (e) {
      print('Error loading shop status: $e');
    }
  }

  Future<void> _createDefaultHours() async {
    if (_shopId == null) return;

    try {
      final response = await ApiService.createDefaultBusinessHours(_shopId!);
      if (response.isSuccess) {
        _showSuccess('Default business hours created');
        await _loadBusinessHours();
      }
    } catch (e) {
      print('Error creating default hours: $e');
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '09:00';
    if (time is String) {
      // Handle formats like "09:00:00" or "09:00"
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return time;
    }
    return time.toString();
  }

  Future<void> _saveBusinessHours() async {
    if (_shopId == null) {
      _showError('Shop ID not found');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Convert to backend format
      final hoursData = _businessHours.map((hour) {
        return {
          'shopId': _shopId,
          'dayOfWeek': hour['dayOfWeek'],
          'openTime': hour['isOpen'] ? '${hour['openTime']}:00' : null,
          'closeTime': hour['isOpen'] ? '${hour['closeTime']}:00' : null,
          'isOpen': hour['isOpen'],
          'is24Hours': false,
        };
      }).toList();

      final response = await ApiService.bulkUpdateBusinessHours(_shopId!, hoursData);

      if (response.isSuccess) {
        _showSuccess('Business hours saved successfully!');
        await _loadShopStatus();
      } else {
        _showError(response.error ?? 'Failed to save business hours');
      }
    } catch (e) {
      print('Error saving business hours: $e');
      _showError('Failed to save business hours');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _copyMondayToAll() {
    final monday = _businessHours[0];
    setState(() {
      for (var i = 1; i < _businessHours.length; i++) {
        _businessHours[i]['openTime'] = monday['openTime'];
        _businessHours[i]['closeTime'] = monday['closeTime'];
        _businessHours[i]['isOpen'] = monday['isOpen'];
      }
    });
    _showSuccess('Monday hours copied to all days');
  }

  void _setDefaultHours() {
    setState(() {
      for (var hour in _businessHours) {
        hour['openTime'] = '09:00';
        hour['closeTime'] = '18:00';
        hour['isOpen'] = true;
      }
      // Close Sunday by default
      _businessHours[6]['isOpen'] = false;
    });
    _showSuccess('Default hours set (9 AM - 6 PM)');
  }

  void _set24Hours() {
    setState(() {
      for (var hour in _businessHours) {
        hour['openTime'] = '00:00';
        hour['closeTime'] = '23:59';
        hour['isOpen'] = true;
      }
    });
    _showSuccess('24-hour operation set for all days');
  }

  void _closeWeekends() {
    setState(() {
      _businessHours[5]['isOpen'] = false; // Saturday
      _businessHours[6]['isOpen'] = false; // Sunday
    });
    _showSuccess('Weekends set to closed');
  }

  void _openAllDays() {
    setState(() {
      for (var hour in _businessHours) {
        hour['isOpen'] = true;
        if (hour['openTime'] == null || hour['openTime'].isEmpty) {
          hour['openTime'] = '09:00';
        }
        if (hour['closeTime'] == null || hour['closeTime'].isEmpty) {
          hour['closeTime'] = '18:00';
        }
      }
    });
    _showSuccess('All days set to open');
  }

  Future<void> _selectTime(BuildContext context, int dayIndex, bool isOpenTime) async {
    final hour = _businessHours[dayIndex];
    final currentTime = isOpenTime ? hour['openTime'] : hour['closeTime'];
    final timeParts = currentTime.split(':');

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
    );

    if (picked != null) {
      setState(() {
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isOpenTime) {
          hour['openTime'] = formattedTime;
        } else {
          hour['closeTime'] = formattedTime;
        }
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.contains('OPEN')) return Colors.green;
    if (status.contains('CLOSED')) return Colors.red;
    return Colors.orange;
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.help;
    if (status.contains('OPEN')) return Icons.check_circle;
    if (status.contains('CLOSED')) return Icons.cancel;
    return Icons.access_time;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Hours'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveBusinessHours,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBusinessHours,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Status Card
                    if (_shopStatus != null) ...[
                      Card(
                        color: _getStatusColor(_shopStatus!['status'])
                            .withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(_shopStatus!['status']),
                                    color: _getStatusColor(_shopStatus!['status']),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Current Status',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _shopStatus!['message'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusColor(_shopStatus!['status']),
                                ),
                              ),
                              if (_shopStatus!['currentTime'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Current Time: ${_shopStatus!['currentTime']} (${_shopStatus!['currentDay'] ?? ''})',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quick Actions
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _copyMondayToAll,
                                  icon: const Icon(Icons.content_copy),
                                  label: const Text('Copy Mon to All'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _setDefaultHours,
                                  icon: const Icon(Icons.restore),
                                  label: const Text('Default (9-6)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _set24Hours,
                                  icon: const Icon(Icons.access_time),
                                  label: const Text('24 Hours'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _closeWeekends,
                                  icon: const Icon(Icons.weekend),
                                  label: const Text('Close Weekends'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _openAllDays,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Open All Days'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Weekly Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Day-by-day cards
                    ..._businessHours.asMap().entries.map((entry) {
                      final index = entry.key;
                      final hour = entry.value;
                      final isOpen = hour['isOpen'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    hour['displayName'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        isOpen ? 'Open' : 'Closed',
                                        style: TextStyle(
                                          color: isOpen ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Switch(
                                        value: isOpen,
                                        onChanged: (value) {
                                          setState(() {
                                            hour['isOpen'] = value;
                                            if (value && hour['openTime'].isEmpty) {
                                              hour['openTime'] = '09:00';
                                              hour['closeTime'] = '18:00';
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (isOpen) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _selectTime(context, index, true),
                                        icon: const Icon(Icons.schedule),
                                        label: Text(
                                          'Open: ${hour['openTime']}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _selectTime(context, index, false),
                                        icon: const Icon(Icons.schedule),
                                        label: Text(
                                          'Close: ${hour['closeTime']}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${hour['openTime']} - ${hour['closeTime']}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.block, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'Closed All Day',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),

                    // Save button at bottom
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveBusinessHours,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
