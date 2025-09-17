import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/village_theme.dart';
import '../services/support_service.dart';
import '../models/faq_model.dart';
import 'faq_screen.dart';
import 'support_tickets_screen.dart';
import 'create_ticket_screen.dart';
import 'live_chat_screen.dart';
import 'feedback_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final SupportService _supportService = SupportService();
  List<ContactMethod> _contactMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContactMethods();
  }

  Future<void> _loadContactMethods() async {
    setState(() => _isLoading = true);
    try {
      final methods = await _supportService.getContactMethods();
      setState(() {
        _contactMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: VillageTheme.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadContactMethods,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header Section
                    _buildHeaderSection(),

                    // Quick Help Options
                    _buildQuickHelpSection(),

                    // Contact Methods
                    _buildContactMethodsSection(),

                    // Support Actions
                    _buildSupportActionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [VillageTheme.primaryGreen, VillageTheme.lightGreen],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'re here to help you 24/7',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelpSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: VillageTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Quick Help',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VillageTheme.textPrimary,
              ),
            ),
          ),
          _buildQuickHelpGrid(),
        ],
      ),
    );
  }

  Widget _buildQuickHelpGrid() {
    final quickOptions = [
      {
        'title': 'Frequently Asked Questions',
        'subtitle': 'Find answers to common questions',
        'icon': Icons.quiz,
        'color': VillageTheme.primaryGreen,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FAQScreen()),
        ),
      },
      {
        'title': 'Track Support Tickets',
        'subtitle': 'View your support requests',
        'icon': Icons.confirmation_number,
        'color': VillageTheme.accentOrange,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SupportTicketsScreen()),
        ),
      },
      {
        'title': 'Order Help',
        'subtitle': 'Issues with your orders',
        'icon': Icons.shopping_bag,
        'color': VillageTheme.successGreen,
        'onTap': () => _showOrderHelp(),
      },
      {
        'title': 'Account Issues',
        'subtitle': 'Problems with your account',
        'icon': Icons.account_circle,
        'color': VillageTheme.infoBlue,
        'onTap': () => _showAccountHelp(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: quickOptions.length,
      itemBuilder: (context, index) {
        final option = quickOptions[index];
        return InkWell(
          onTap: option['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: (option['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (option['color'] as Color).withOpacity(0.3),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option['icon'] as IconData,
                  size: 32,
                  color: option['color'] as Color,
                ),
                const SizedBox(height: 12),
                Text(
                  option['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VillageTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  option['subtitle'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: VillageTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactMethodsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: VillageTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VillageTheme.textPrimary,
              ),
            ),
          ),
          ..._contactMethods.map((method) => _buildContactMethodTile(method)),
        ],
      ),
    );
  }

  Widget _buildContactMethodTile(ContactMethod method) {
    IconData iconData;
    Color iconColor;

    switch (method.type) {
      case 'phone':
        iconData = Icons.phone;
        iconColor = VillageTheme.successGreen;
        break;
      case 'whatsapp':
        iconData = Icons.chat;
        iconColor = Colors.green;
        break;
      case 'email':
        iconData = Icons.email;
        iconColor = VillageTheme.accentOrange;
        break;
      case 'chat':
        iconData = Icons.chat_bubble;
        iconColor = VillageTheme.primaryGreen;
        break;
      default:
        iconData = Icons.contact_support;
        iconColor = VillageTheme.textSecondary;
    }

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(iconData, color: iconColor),
      ),
      title: Text(
        method.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: VillageTheme.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(method.description),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                method.isAvailable ? Icons.check_circle : Icons.cancel,
                size: 12,
                color: method.isAvailable ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                method.isAvailable ? 'Available' : 'Unavailable',
                style: TextStyle(
                  fontSize: 12,
                  color: method.isAvailable ? Colors.green : Colors.red,
                ),
              ),
              if (method.availableHours != null) ...[
                const SizedBox(width: 8),
                Text(
                  '• ${method.availableHours}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _handleContactMethodTap(method),
    );
  }

  Widget _buildSupportActionsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: VillageTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Support Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VillageTheme.textPrimary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle, color: VillageTheme.primaryGreen),
            title: const Text('Create Support Ticket'),
            subtitle: const Text('Report an issue or ask for help'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback, color: VillageTheme.accentOrange),
            title: const Text('Send Feedback'),
            subtitle: const Text('Share your thoughts and suggestions'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FeedbackScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.chat_bubble, color: VillageTheme.primaryGreen),
            title: const Text('Live Chat'),
            subtitle: const Text('Chat with our support team'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LiveChatScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _handleContactMethodTap(ContactMethod method) {
    switch (method.type) {
      case 'phone':
        _makePhoneCall(method.value);
        break;
      case 'whatsapp':
        _openWhatsApp(method.value);
        break;
      case 'email':
        _sendEmail(method.value);
        break;
      case 'chat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LiveChatScreen()),
        );
        break;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final uri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showOrderHelp() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Order Help',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Track Your Order'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to order tracking
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel Order'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to cancel order
              },
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Return/Exchange'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to return/exchange
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountHelp() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account Help',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Reset Password'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to password reset
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile edit
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Manage Addresses'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to address management
              },
            ),
          ],
        ),
      ),
    );
  }
}