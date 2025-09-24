import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ShopProfileScreen extends StatelessWidget {
  const ShopProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Shop Profile Screen\n(Coming Soon)',
          style: AppTextStyles.heading2,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}