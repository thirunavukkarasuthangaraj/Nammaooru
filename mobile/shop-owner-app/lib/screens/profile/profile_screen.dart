import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String token;

  const ProfileScreen({super.key, required this.userName, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _shopName = 'My Shop';
  String _shopAddress = 'Shop Address Not Set';
  String _phoneNumber = 'Phone Not Set';
  String _email = 'Email Not Set';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        // In a real app, you'd parse the JSON and extract user data
        setState(() {
          _shopName = widget.userName;
          _email = 'shopowner@nammaooru.com';
          _phoneNumber = '+91 98765 43210';
          _shopAddress = 'Koramangala, Bangalore - 560034';
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showComingSoon('Edit Profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.store,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _shopName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Shop Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.email, 'Email', _email),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.phone, 'Phone', _phoneNumber),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'Address', _shopAddress),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.access_time, 'Hours', 'Mon-Sun: 9:00 AM - 10:00 PM'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Settings & Options
            Card(
              child: Column(
                children: [
                  _buildMenuTile(
                    Icons.notifications,
                    'Notifications',
                    'Manage notification preferences',
                    () => _showComingSoon('Notifications Settings'),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    Icons.payment,
                    'Payment Settings',
                    'Bank account and payment details',
                    () => _showComingSoon('Payment Settings'),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    Icons.inventory,
                    'Inventory Settings',
                    'Stock alerts and inventory management',
                    () => _showComingSoon('Inventory Settings'),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    Icons.analytics,
                    'Business Analytics',
                    'Detailed sales and performance reports',
                    () => _showComingSoon('Business Analytics'),
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    Icons.support_agent,
                    'Support & Help',
                    'Get help and contact support',
                    () => _showComingSoon('Support Center'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.info, 'Version', '1.0.0'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.update, 'Last Updated', 'Today'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showComingSoon('Privacy Policy'),
                          icon: const Icon(Icons.privacy_tip),
                          label: const Text('Privacy Policy'),
                        ),
                        TextButton.icon(
                          onPressed: () => _showComingSoon('Terms of Service'),
                          icon: const Icon(Icons.description),
                          label: const Text('Terms of Service'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}