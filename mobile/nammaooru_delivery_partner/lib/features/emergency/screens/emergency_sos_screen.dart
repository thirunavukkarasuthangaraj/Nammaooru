import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'emergency_history_screen.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({Key? key}) : super(key: key);

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Animation<double> _pulseAnimation;
  late Animation<int> _countdownAnimation;

  String _selectedEmergencyType = 'ACCIDENT';
  String _description = '';
  bool _isSOSActive = false;
  String? _emergencyId;
  Position? _currentLocation;
  String? _currentLocationAddress;
  List<Map<String, Object>> _emergencyContacts = [];
  Map<String, dynamic>? _driverProfile;

  bool _isCountingDown = false;
  int _countdownSeconds = 10;

  final TextEditingController _descriptionController = TextEditingController();

  final List<Map<String, dynamic>> _emergencyTypes = [
    {
      'type': 'ACCIDENT',
      'label': 'Accident',
      'icon': Icons.car_crash,
      'color': Colors.red,
      'description': 'Vehicle accident or crash'
    },
    {
      'type': 'ROBBERY',
      'label': 'Robbery/Theft',
      'icon': Icons.security,
      'color': Colors.orange,
      'description': 'Theft or robbery incident'
    },
    {
      'type': 'MEDICAL',
      'label': 'Medical Emergency',
      'icon': Icons.medical_services,
      'color': Colors.pink,
      'description': 'Health emergency or medical issue'
    },
    {
      'type': 'OTHER',
      'label': 'Other Emergency',
      'icon': Icons.warning,
      'color': Colors.amber,
      'description': 'Any other emergency situation'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadEmergencyContacts();
    _getCurrentLocation();
    _loadDriverProfile();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _countdownController = AnimationController(
      duration: Duration(seconds: _countdownSeconds),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdownAnimation = IntTween(begin: _countdownSeconds, end: 0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.linear),
    );

    _pulseController.repeat(reverse: true);
  }

  void _getCurrentLocation() async {
    try {
      Map<String, dynamic>? locationData = await _locationService.getCurrentLocationWithAddress();
      if (locationData != null) {
        setState(() {
          _currentLocation = Position(
            latitude: locationData['latitude'],
            longitude: locationData['longitude'],
            accuracy: locationData['accuracy'],
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            timestamp: locationData['timestamp'],
          );
        });

        // Store address information for emergency data
        if (locationData['address'] != null) {
          _currentLocationAddress = locationData['address']['fullAddress'] ?? 'Location not available';
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _loadEmergencyContacts() async {
    try {
      final response = await _apiService.getEmergencyContacts();
      if (response['success']) {
        setState(() {
          _emergencyContacts = List<Map<String, Object>>.from(response['contacts']);
        });
      }
    } catch (e) {
      print('Error loading emergency contacts: $e');
    }
  }

  void _loadDriverProfile() async {
    try {
      final response = await _apiService.getProfile();
      if (response['success']) {
        setState(() {
          _driverProfile = response['partner'];
        });
      }
    } catch (e) {
      print('Error loading driver profile: $e');
    }
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
    });

    _countdownController.forward().then((_) {
      if (_isCountingDown) {
        _triggerEmergencySOS();
      }
    });

    _countdownController.addListener(() {
      setState(() {});
    });
  }

  void _cancelCountdown() {
    setState(() {
      _isCountingDown = false;
    });
    _countdownController.stop();
    _countdownController.reset();
  }

  void _triggerEmergencySOS() async {
    if (_currentLocation == null) {
      _showErrorMessage('Unable to get your current location. Please try again.');
      return;
    }

    try {
      setState(() {
        _isCountingDown = false;
      });

      final response = await _apiService.triggerEmergencySOS(
        emergencyType: _selectedEmergencyType,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        description: _description,
        locationAddress: _currentLocationAddress,
      );

      if (response['success']) {
        setState(() {
          _isSOSActive = true;
          _emergencyId = response['emergencyId'];
        });

        _showSuccessMessage('Emergency SOS activated! Help is on the way.');

        // Automatically call the first emergency contact (company support)
        _makeEmergencyCall('+91 98765 43210');
      } else {
        _showErrorMessage(response['message'] ?? 'Failed to activate SOS');
      }
    } catch (e) {
      _showErrorMessage('Failed to activate emergency SOS: $e');
    }
  }

  void _cancelEmergencySOS() async {
    if (_emergencyId == null) return;

    try {
      final response = await _apiService.cancelEmergencySOS(_emergencyId!);
      if (response['success']) {
        setState(() {
          _isSOSActive = false;
          _emergencyId = null;
        });
        _showSuccessMessage('Emergency SOS cancelled');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorMessage('Failed to cancel SOS: $e');
    }
  }

  void _makeEmergencyCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorMessage('Could not make phone call');
      }
    } catch (e) {
      print('Error making phone call: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: Text('Emergency SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyHistoryScreen(),
                ),
              );
            },
            tooltip: 'Emergency History',
          ),
        ],
      ),
      body: _isSOSActive ? _buildActiveSOSScreen() : _buildSOSSetupScreen(),
    );
  }

  Widget _buildSOSSetupScreen() {
    if (_isCountingDown) {
      return _buildCountdownScreen();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 40),
                SizedBox(height: 8),
                Text(
                  'Emergency SOS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This will immediately alert emergency services and your company with your current location.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Driver Profile Card
          if (_driverProfile != null) ...[
            Text(
              'Driver Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Driver Photo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                      image: _driverProfile!['profileImageUrl'] != null
                          ? DecorationImage(
                              image: NetworkImage(_driverProfile!['profileImageUrl']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _driverProfile!['profileImageUrl'] == null
                        ? Icon(Icons.person, size: 30, color: Colors.grey.shade600)
                        : null,
                  ),
                  SizedBox(width: 16),
                  // Driver Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_driverProfile!['firstName'] ?? ''} ${_driverProfile!['lastName'] ?? ''}'.trim(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _driverProfile!['mobileNumber'] ?? 'No phone',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _driverProfile!['email'] ?? 'No email',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Online Status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_driverProfile!['isOnline'] == true)
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (_driverProfile!['isOnline'] == true) ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: (_driverProfile!['isOnline'] == true)
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],

          // Emergency type selection
          Text(
            'Emergency Type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

          ..._emergencyTypes.map((type) => _buildEmergencyTypeCard(type)),

          SizedBox(height: 24),

          // Description
          Text(
            'Description (Optional)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe the emergency situation...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              _description = value;
            },
          ),

          SizedBox(height: 32),

          // Emergency contacts
          if (_emergencyContacts.isNotEmpty) ...[
            Text(
              'Emergency Contacts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ..._emergencyContacts.map((contact) => _buildContactCard(contact)),
            SizedBox(height: 32),
          ],

          // SOS Button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _startCountdown,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sos, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'ACTIVATE EMERGENCY SOS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 16),

          // Emergency History Button
          Container(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencyHistoryScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'VIEW EMERGENCY HISTORY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _countdownAnimation,
            builder: (context, child) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${_countdownAnimation.value}',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 32),
          Text(
            'Emergency SOS Activating...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Emergency services will be contacted',
            style: TextStyle(fontSize: 16, color: Colors.red.shade700),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _cancelCountdown,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSOSScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.check,
                size: 80,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Emergency SOS Active',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Help is on the way!\nEmergency services have been contacted.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.green.shade700),
            ),
            SizedBox(height: 32),
            Text(
              'Emergency ID: $_emergencyId',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _cancelEmergencySOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'CANCEL SOS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTypeCard(Map<String, dynamic> type) {
    bool isSelected = _selectedEmergencyType == type['type'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedEmergencyType = type['type'];
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? type['color'].withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? type['color'] : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: type['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  type['icon'],
                  color: type['color'],
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type['label'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? type['color'] : Colors.black,
                      ),
                    ),
                    Text(
                      type['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: type['color'],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, Object> contact) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _makeEmergencyCall(contact['number'].toString()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.phone, color: Colors.green),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact['name'].toString(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      contact['number'].toString(),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}