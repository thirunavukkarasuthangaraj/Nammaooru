import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/profile_model.dart';

class ProfileInfoWidget extends StatelessWidget {
  final Profile profile;

  const ProfileInfoWidget({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoSection(
              'Contact Details',
              [
                _buildInfoRow('📧', 'Email', profile.email),
                _buildInfoRow('📱', 'Phone', profile.phoneNumber),
                _buildInfoRow('🚨', 'Emergency Contact', '${profile.emergencyContactName}\n${profile.emergencyContactNumber}'),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoSection(
              'Address',
              [
                _buildInfoRow('🏠', 'Home Address', profile.address.fullAddress),
                if (profile.address.landmark != null)
                  _buildInfoRow('📍', 'Landmark', profile.address.landmark!),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoSection(
              'Vehicle Details',
              [
                _buildInfoRow('🏍️', 'Vehicle', profile.vehicleInfo.displayName),
                _buildInfoRow('🔢', 'Number', profile.vehicleInfo.vehicleNumber),
                _buildInfoRow('🎨', 'Color', profile.vehicleInfo.vehicleColor),
                if (profile.vehicleInfo.insuranceNumber != null)
                  _buildInfoRow('🛡️', 'Insurance', profile.vehicleInfo.insuranceNumber!),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoSection(
              'Bank Details',
              [
                _buildInfoRow('🏦', 'Bank', profile.bankDetails.bankName),
                _buildInfoRow('💳', 'Account', profile.bankDetails.maskedAccountNumber),
                _buildInfoRow('🔑', 'IFSC', profile.bankDetails.ifscCode),
                _buildInfoRow('👤', 'Account Holder', profile.bankDetails.accountHolderName),
                if (profile.bankDetails.branchName != null)
                  _buildInfoRow('🏢', 'Branch', profile.bankDetails.branchName!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}