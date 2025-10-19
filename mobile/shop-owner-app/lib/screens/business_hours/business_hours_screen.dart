import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

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
  bool _isShopOpen = false;
  String _shopStatus = 'Unknown';
  List<BusinessHour> _businessHours = [];

  final List<String> _daysOfWeek = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
    'FRIDAY', 'SATURDAY', 'SUNDAY'
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessHours();
    _checkShopStatus();
  }

  Future<void> _loadBusinessHours() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getShopBusinessHours('1'); // Using shop ID 1 for now

      if (response.success) {
        final data = response.data['data'] as List;
        setState(() {
          _businessHours = data.map((json) => BusinessHour.fromJson(json)).toList();
        });
      } else {
        _showError('Failed to load business hours: ${response.error}');
      }
    } catch (e) {
      _showError('Error loading business hours: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkShopStatus() async {
    try {
      final isOpenResponse = await ApiService.checkShopIsOpen('1');
      final statusResponse = await ApiService.getShopStatus('1');

      if (isOpenResponse.success && statusResponse.success) {
        setState(() {
          _isShopOpen = isOpenResponse.data['data'] == true;
          _shopStatus = statusResponse.data['data']['status'] ?? 'Unknown';
        });
      }
    } catch (e) {
      print('Error checking shop status: $e');
    }
  }

  Future<void> _saveBulkBusinessHours() async {
    try {
      final List<Map<String, dynamic>> hoursData = _businessHours.map((hour) => {
        'dayOfWeek': hour.dayOfWeek,
        'openTime': hour.openTime,
        'closeTime': hour.closeTime,
        'isOpen': hour.isOpen,
        'is24Hours': hour.is24Hours,
        'breakStartTime': hour.breakStartTime,
        'breakEndTime': hour.breakEndTime,
        'specialNote': hour.specialNote,
      }).toList();

      final response = await ApiService.bulkUpdateBusinessHours('1', hoursData);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business hours updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        await _checkShopStatus();
      } else {
        _showError('Failed to update business hours: ${response.error}');
      }
    } catch (e) {
      _showError('Error updating business hours: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _updateBusinessHour(String day, BusinessHour updatedHour) {
    setState(() {
      final index = _businessHours.indexWhere((h) => h.dayOfWeek == day);
      if (index != -1) {
        _businessHours[index] = updatedHour;
      } else {
        _businessHours.add(updatedHour);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Hours'),
        backgroundColor: AppColors.surface,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _saveBulkBusinessHours,
            icon: const Icon(Icons.save, color: AppColors.primary),
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Status Card
                  _buildStatusCard(),
                  const SizedBox(height: AppSizes.spacingLg),

                  // Business Hours List
                  Text(
                    'Weekly Schedule',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppSizes.spacingMd),

                  ..._daysOfWeek.map((day) => _buildDayCard(day)).toList(),

                  const SizedBox(height: AppSizes.spacingXl),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loadBusinessHours,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: AppThemes.secondaryButtonStyle,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingMd),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveBulkBusinessHours,
                          icon: const Icon(Icons.save),
                          label: const Text('Save All'),
                          style: AppThemes.primaryButtonStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isShopOpen ? Icons.store : Icons.store_mall_directory_outlined,
                  color: _isShopOpen ? AppColors.success : AppColors.error,
                  size: AppSizes.iconLg,
                ),
                const SizedBox(width: AppSizes.spacingSm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop Status',
                      style: AppTextStyles.titleMedium,
                    ),
                    Text(
                      _isShopOpen ? 'Currently Open' : 'Currently Closed',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _isShopOpen ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              'Status: $_shopStatus',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(String day) {
    final hour = _businessHours.firstWhere(
      (h) => h.dayOfWeek == day,
      orElse: () => BusinessHour(
        dayOfWeek: day,
        isOpen: false,
        openTime: '09:00',
        closeTime: '18:00',
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDayName(day),
                  style: AppTextStyles.titleMedium,
                ),
                Switch(
                  value: hour.isOpen,
                  onChanged: (value) {
                    _updateBusinessHour(day, hour.copyWith(isOpen: value));
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),

            if (hour.isOpen) ...[
              const SizedBox(height: AppSizes.spacingSm),

              // Open/Close Times
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      label: 'Open Time',
                      time: hour.openTime,
                      onChanged: (time) {
                        _updateBusinessHour(day, hour.copyWith(openTime: time));
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingMd),
                  Expanded(
                    child: _buildTimeField(
                      label: 'Close Time',
                      time: hour.closeTime,
                      onChanged: (time) {
                        _updateBusinessHour(day, hour.copyWith(closeTime: time));
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingSm),

              // 24 Hours Toggle
              CheckboxListTile(
                title: const Text('24 Hours'),
                value: hour.is24Hours,
                onChanged: (value) {
                  _updateBusinessHour(day, hour.copyWith(is24Hours: value ?? false));
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Break Times
              if (!hour.is24Hours) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeField(
                        label: 'Break Start',
                        time: hour.breakStartTime ?? '',
                        onChanged: (time) {
                          _updateBusinessHour(day, hour.copyWith(breakStartTime: time.isEmpty ? null : time));
                        },
                        isOptional: true,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingMd),
                    Expanded(
                      child: _buildTimeField(
                        label: 'Break End',
                        time: hour.breakEndTime ?? '',
                        onChanged: (time) {
                          _updateBusinessHour(day, hour.copyWith(breakEndTime: time.isEmpty ? null : time));
                        },
                        isOptional: true,
                      ),
                    ),
                  ],
                ),
              ],

              // Special Note
              const SizedBox(height: AppSizes.spacingSm),
              TextFormField(
                initialValue: hour.specialNote ?? '',
                decoration: const InputDecoration(
                  labelText: 'Special Note (Optional)',
                  hintText: 'e.g., Lunch break 1-2 PM',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateBusinessHour(day, hour.copyWith(specialNote: value.isEmpty ? null : value));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required String time,
    required Function(String) onChanged,
    bool isOptional = false,
  }) {
    return TextFormField(
      initialValue: time,
      decoration: InputDecoration(
        labelText: label + (isOptional ? ' (Optional)' : ''),
        hintText: 'HH:MM',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () async {
            final TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: _parseTime(time),
            );
            if (pickedTime != null) {
              final formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
              onChanged(formattedTime);
            }
          },
        ),
      ),
      onChanged: onChanged,
    );
  }

  TimeOfDay _parseTime(String time) {
    if (time.isEmpty) return TimeOfDay.now();
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatDayName(String day) {
    return day.toLowerCase().replaceRange(0, 1, day[0].toUpperCase());
  }
}

class BusinessHour {
  final String dayOfWeek;
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final bool is24Hours;
  final String? breakStartTime;
  final String? breakEndTime;
  final String? specialNote;

  BusinessHour({
    required this.dayOfWeek,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    this.is24Hours = false,
    this.breakStartTime,
    this.breakEndTime,
    this.specialNote,
  });

  factory BusinessHour.fromJson(Map<String, dynamic> json) {
    return BusinessHour(
      dayOfWeek: json['dayOfWeek'] ?? '',
      isOpen: json['isOpen'] ?? false,
      openTime: json['openTime'] ?? '09:00',
      closeTime: json['closeTime'] ?? '18:00',
      is24Hours: json['is24Hours'] ?? false,
      breakStartTime: json['breakStartTime'],
      breakEndTime: json['breakEndTime'],
      specialNote: json['specialNote'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
      'is24Hours': is24Hours,
      'breakStartTime': breakStartTime,
      'breakEndTime': breakEndTime,
      'specialNote': specialNote,
    };
  }

  BusinessHour copyWith({
    String? dayOfWeek,
    bool? isOpen,
    String? openTime,
    String? closeTime,
    bool? is24Hours,
    String? breakStartTime,
    String? breakEndTime,
    String? specialNote,
  }) {
    return BusinessHour(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      is24Hours: is24Hours ?? this.is24Hours,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      specialNote: specialNote ?? this.specialNote,
    );
  }
}