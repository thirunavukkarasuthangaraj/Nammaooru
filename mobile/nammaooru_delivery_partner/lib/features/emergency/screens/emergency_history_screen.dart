import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';

class EmergencyHistoryScreen extends StatefulWidget {
  const EmergencyHistoryScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyHistoryScreen> createState() => _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState extends State<EmergencyHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _emergencyHistory = [];
  bool _isLoading = false;
  int _totalCount = 0;
  int _activeCount = 0;
  int _resolvedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEmergencyHistory();
  }

  Future<void> _loadEmergencyHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getEmergencyHistory();
      if (response['success']) {
        setState(() {
          _emergencyHistory = List<Map<String, dynamic>>.from(response['emergencyHistory']);
          _totalCount = response['totalCount'] ?? 0;
          _activeCount = response['activeCount'] ?? 0;
          _resolvedCount = response['resolvedCount'] ?? 0;
        });
      } else {
        _showErrorMessage(response['message'] ?? 'Failed to load emergency history');
      }
    } catch (e) {
      _showErrorMessage('Error loading emergency history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.red;
      case 'RESOLVED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade700;
      case 'MEDIUM':
        return Colors.yellow.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  IconData _getEmergencyIcon(String emergencyType) {
    switch (emergencyType.toUpperCase()) {
      case 'ACCIDENT':
        return Icons.car_crash;
      case 'ROBBERY':
        return Icons.security;
      case 'MEDICAL':
        return Icons.medical_services;
      case 'VEHICLE_BREAKDOWN':
        return Icons.build;
      default:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Emergency History'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEmergencyHistory,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildHistoryContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 16),
          Text('Loading emergency history...'),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    return Column(
      children: [
        // Summary Cards
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(child: _buildSummaryCard('Total', _totalCount.toString(), Colors.blue)),
              SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Active', _activeCount.toString(), Colors.red)),
              SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Resolved', _resolvedCount.toString(), Colors.green)),
            ],
          ),
        ),

        // Emergency List
        Expanded(
          child: _emergencyHistory.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadEmergencyHistory,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _emergencyHistory.length,
                    itemBuilder: (context, index) {
                      return _buildEmergencyCard(_emergencyHistory[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'No Emergency History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your emergency alerts will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> emergency) {
    final String emergencyType = emergency['emergencyType'] ?? 'OTHER';
    final String status = emergency['status'] ?? 'UNKNOWN';
    final String severity = emergency['severity'] ?? 'MEDIUM';
    final String description = emergency['description'] ?? 'No description';
    final bool wasOnDelivery = emergency['wasOnDelivery'] ?? false;
    final String? orderId = emergency['orderId'];
    final String? responseTime = emergency['responseTime'];

    DateTime? timestamp;
    if (emergency['timestamp'] != null) {
      timestamp = DateTime.tryParse(emergency['timestamp']);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Emergency Icon
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEmergencyIcon(emergencyType),
                      color: _getSeverityColor(severity),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Emergency Type & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emergencyType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(severity).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                severity,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getSeverityColor(severity),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Time
                  if (timestamp != null)
                    Text(
                      DateFormat('MMM dd, yyyy\nhh:mm a').format(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                ],
              ),

              SizedBox(height: 12),

              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),

              SizedBox(height: 12),

              // Additional Info
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (wasOnDelivery)
                    _buildInfoChip(Icons.delivery_dining, 'During Delivery', Colors.blue),
                  if (orderId != null)
                    _buildInfoChip(Icons.receipt, 'Order: $orderId', Colors.purple),
                  if (responseTime != null)
                    _buildInfoChip(Icons.timer, 'Response: $responseTime', Colors.orange),
                  if (emergency['requiresPolice'] == true)
                    _buildInfoChip(Icons.local_police, 'Police Required', Colors.red),
                  if (emergency['requiresAmbulance'] == true)
                    _buildInfoChip(Icons.medical_services, 'Medical Required', Colors.green),
                ],
              ),

              // Location (if available)
              if (emergency['locationAddress'] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        emergency['locationAddress'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}