import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  // Village-friendly support contact details
  static const String supportPhoneNumber = '+91 9876543210';
  static const String whatsappNumber = '+91 9876543210';
  static const String supportEmail = 'support@nammaooru.com';
  static const String officialWebsite = 'https://nammaooru.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActionsCard(context),
            const SizedBox(height: 20),
            _buildFAQSection(context),
            const SizedBox(height: 20),
            _buildContactInfoCard(context),
            const SizedBox(height: 20),
            _buildAppInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'விரைவு உதவி / Quick Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'உங்கள் பொதுவான கேள்விகளுக்கு விரைவான உதவி / Quick help for your common questions',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.phone,
                    label: 'Call Now',
                    color: Colors.green,
                    onPressed: () => _makePhoneCall(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: Colors.green.shade600,
                    onPressed: () => _openWhatsApp(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.email,
                    label: 'Email',
                    color: Colors.blue,
                    onPressed: () => _sendEmail(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.web,
                    label: 'Website',
                    color: Colors.orange,
                    onPressed: () => _openWebsite(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        'question': 'How to place an order?',
        'answer': '1. Browse shops near you\n2. Select products and add to cart\n3. Choose delivery address\n4. Select Cash on Delivery\n5. Confirm your order'
      },
      {
        'question': 'Cash on Delivery available?',
        'answer': 'Yes! Cash on Delivery is available for all orders. Pay when your order arrives at your doorstep.'
      },
      {
        'question': 'Delivery time?',
        'answer': 'Standard delivery: 30-45 minutes for nearby shops\nScheduled delivery: Choose your preferred time slot'
      },
      {
        'question': 'How to cancel order?',
        'answer': 'Go to "My Orders" → Select your order → Click "Cancel Order". You can cancel before the shop starts preparing.'
      },
      {
        'question': 'App language?',
        'answer': 'Currently available in English and Tamil language support!'
      },
      {
        'question': 'Support hours?',
        'answer': 'Our support team is available:\nMonday to Sunday: 8:00 AM to 10:00 PM\nFor urgent issues, call us anytime!'
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...faqs.map((faq) => _buildFAQItem(
              faq['question']!,
              faq['answer']!,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.phone,
              title: 'Customer Support',
              value: supportPhoneNumber,
              onTap: () => _makePhoneCall(context),
            ),
            _buildContactItem(
              icon: Icons.chat,
              title: 'WhatsApp Support',
              value: whatsappNumber,
              onTap: () => _openWhatsApp(context),
            ),
            _buildContactItem(
              icon: Icons.email,
              title: 'Email Support',
              value: supportEmail,
              onTap: () => _sendEmail(context),
            ),
            _buildContactItem(
              icon: Icons.web,
              title: 'Website',
              value: officialWebsite,
              onTap: () => _openWebsite(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.green.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return Card(
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('App Version'),
                Text('1.0.0'),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Last Updated'),
                Text('Dec 2024'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'About NammaOoru',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'NammaOoru connects you with local shops in your village and city. Order groceries, medicines, and daily essentials from nearby stores with fast delivery and Cash on Delivery option.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: supportPhoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar(context, 'Could not make phone call');
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = 'Hi! I need help with NammaOoru app.';
    final whatsappUrl = Uri.parse('https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar(context, 'WhatsApp not installed');
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=NammaOoru App Support&body=Hi, I need help with...',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorSnackBar(context, 'Could not open email app');
    }
  }

  Future<void> _openWebsite(BuildContext context) async {
    final websiteUrl = Uri.parse(officialWebsite);
    
    if (await canLaunchUrl(websiteUrl)) {
      await launchUrl(websiteUrl, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar(context, 'Could not open website');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}