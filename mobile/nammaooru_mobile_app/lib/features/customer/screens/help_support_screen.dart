import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/village_theme.dart';
import '../../../services/contact_config_service.dart';

class HelpSupportScreen extends StatefulWidget {
  final Map<String, dynamic> systemInformation;

  const HelpSupportScreen({
    super.key,
    this.systemInformation = const {},
  });

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _contact = ContactConfigService.instance;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _contact.fetch().then((_) {
      if (mounted) setState(() {});
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: VillageTheme.primaryGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactSupportCard(context),
              const SizedBox(height: 20),
              _buildFAQSection(context),
              const SizedBox(height: 20),
              _buildSystemInformationCard(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        'question': 'How to place an order?',
        'answer':
            '1. Browse shops near you\n2. Select products and add to cart\n3. Choose delivery address\n4. Select Cash on Delivery\n5. Confirm your order'
      },
      {
        'question': 'Cash on Delivery available?',
        'answer':
            'Yes! Cash on Delivery is available for all orders. Pay when your order arrives at your doorstep.'
      },
      {
        'question': 'Delivery time?',
        'answer':
            'Standard delivery: 30-45 minutes for nearby shops\nScheduled delivery: Choose your preferred time slot'
      },
      {
        'question': 'How to cancel order?',
        'answer':
            'Go to "My Orders" → Select your order → Click "Cancel Order". You can cancel before the shop starts preparing.'
      },
      {
        'question': 'App language?',
        'answer': 'Currently available in English and Tamil language support!'
      },
      {
        'question': 'Support hours?',
        'answer':
            'Our support team is available:\nMonday to Sunday: 8:00 AM to 10:00 PM\nFor urgent issues, call us anytime!'
      },
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            ...faqs
                .map((faq) => _buildFAQItem(
                      faq['question']!,
                      faq['answer']!,
                    ))
                .toList(),
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

  Widget _buildContactSupportCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _contact.phone,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _contact.website
                            .replaceFirst(RegExp(r'^https?://'), ''),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(context),
                    icon: const Icon(Icons.phone_rounded, size: 20),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(context),
                    icon: const Icon(Icons.chat_rounded, size: 20),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendEmail(context),
                    icon: const Icon(Icons.email_outlined, size: 20),
                    label: const Text('Email'),
                    style: _secondaryContactButtonStyle(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWebsite(context),
                    icon: const Icon(Icons.language_rounded, size: 20),
                    label: const Text('Website'),
                    style: _secondaryContactButtonStyle(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _secondaryContactButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _buildSystemInformationCard(BuildContext context) {
    final information = widget.systemInformation;
    final profileVersion = information['appVersion']?.toString() ?? '';
    final appVersion = profileVersion.isNotEmpty
        ? profileVersion
        : (_appVersion.isNotEmpty ? _appVersion : 'N/A');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'System Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                _buildInformationRow(
                  'Auth Status',
                  information['isAuthenticated'] == true
                      ? 'Authenticated'
                      : 'Not Authenticated',
                ),
                const SizedBox(height: 12),
                _buildInformationRow(
                  'Session Started',
                  _formatDateTime(information['loginTime']?.toString()),
                ),
                const SizedBox(height: 12),
                _buildInformationRow(
                  'Last Login',
                  information['lastLogin']?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInformationRow('App Version', appVersion),
                const SizedBox(height: 12),
                _buildInformationRow(
                  'Membership',
                  information['membershipType']?.toString() ?? 'Customer',
                ),
                const SizedBox(height: 12),
                _buildInformationRow(
                  'Total Orders',
                  information['totalOrders']?.toString() ?? '0',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at '
          '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _contact.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar(context, 'Could not make phone call');
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final number = _contact.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappUrl = Uri.parse('https://wa.me/91$number');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar(context, 'WhatsApp not installed');
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: _contact.email,
      query: 'subject=NammaOoru App Support&body=Hi, I need help with...',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorSnackBar(context, 'Could not open email app');
    }
  }

  Future<void> _openWebsite(BuildContext context) async {
    final websiteUrl = Uri.parse(_contact.website);

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
