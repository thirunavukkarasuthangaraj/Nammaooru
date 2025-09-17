import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/delivery_partner_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../services/profile_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/document_verification_card.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/document_upload_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;
  Map<String, dynamic>? _documentSummary;
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<DeliveryPartnerProvider>(context, listen: false);
      final partnerId = provider.currentPartner?.id;

      if (partnerId != null) {
        final documentSummary = await _profileService.getDocumentVerificationSummary(partnerId);
        final settings = await _profileService.getSettings(partnerId);

        setState(() {
          _documentSummary = documentSummary;
          _settings = settings;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load profile data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Consumer<DeliveryPartnerProvider>(
                      builder: (context, provider, child) {
                        if (provider.currentPartner != null) {
                          return ProfileHeader(
                            partner: provider.currentPartner!,
                            settings: _settings,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Document Verification Section
                    if (_documentSummary != null) ...{
                      _buildDocumentVerificationSection(),
                      const SizedBox(height: 24),
                    },

                    // Profile Menu Items
                    _buildProfileMenuSection(),

                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

Widget _buildDocumentVerificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Document Verification',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_documentSummary != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCompletionColor(_documentSummary!['completionPercentage']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_documentSummary!['completionPercentage']}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            DocumentVerificationCard(
              documentSummary: _documentSummary!,
              onUploadDocument: _showDocumentUploadDialog,
              onViewDocuments: _navigateToDocuments,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ProfileMenuItem(
              icon: Icons.settings,
              title: 'App Settings',
              subtitle: 'Notifications, language, theme',
              onTap: () => _navigateToSettings(),
            ),

            const Divider(),

            ProfileMenuItem(
              icon: Icons.work_outline,
              title: 'Work Schedule',
              subtitle: 'Set your working hours',
              onTap: () => _navigateToWorkSchedule(),
            ),

            const Divider(),

            ProfileMenuItem(
              icon: Icons.location_on,
              title: 'Location Settings',
              subtitle: 'Location sharing preferences',
              onTap: () => _navigateToLocationSettings(),
            ),

            const Divider(),

            ProfileMenuItem(
              icon: Icons.contact_emergency,
              title: 'Emergency Contact',
              subtitle: 'Emergency contact information',
              onTap: () => _navigateToEmergencyContact(),
            ),

            const Divider(),

            ProfileMenuItem(
              icon: Icons.account_balance_wallet,
              title: 'Banking Details',
              subtitle: 'Payment and withdrawal settings',
              onTap: () => _navigateToBankingSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.upload_file,
                    label: 'Upload Document',
                    onTap: () => _showDocumentUploadDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.verified_user,
                    label: 'View Documents',
                    onTap: () => _navigateToDocuments(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () => _navigateToSupport(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompletionColor(int percentage) {
    if (percentage >= 100) return AppColors.success;
    if (percentage >= 70) return AppColors.warning;
    return AppColors.error;
  }

  void _showDocumentUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => DocumentUploadDialog(
        onDocumentUploaded: (success, message) {
          Navigator.of(context).pop();
          if (success) {
            _showSuccessSnackBar(message);
            _loadProfileData();
          } else {
            _showErrorSnackBar(message);
          }
        },
      ),
    );
  }

  void _navigateToDocuments() {
    Navigator.pushNamed(context, '/documents').then((_) => _loadProfileData());
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/app-settings').then((_) => _loadProfileData());
  }

  void _navigateToWorkSchedule() {
    Navigator.pushNamed(context, '/work-schedule').then((_) => _loadProfileData());
  }

  void _navigateToLocationSettings() {
    Navigator.pushNamed(context, '/location-settings').then((_) => _loadProfileData());
  }

  void _navigateToEmergencyContact() {
    Navigator.pushNamed(context, '/emergency-contact').then((_) => _loadProfileData());
  }

  void _navigateToBankingSettings() {
    Navigator.pushNamed(context, '/banking-settings').then((_) => _loadProfileData());
  }

  void _navigateToSupport() {
    Navigator.pushNamed(context, '/support');
  }
}