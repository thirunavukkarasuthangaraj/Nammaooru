import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/language_provider.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  String? _selected;

  Future<void> _selectLanguage(String lang) async {
    setState(() => _selected = lang);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    langProvider.setLanguage(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 250));
      context.go('/customer/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.storefront_rounded,
                    size: 44, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'NammaOoru',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select your language  •  மொழியை தேர்ந்தெடுங்கள்',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // English
              _LangTile(
                label: 'English',
                isSelected: _selected == 'en',
                onTap: () => _selectLanguage('en'),
              ),
              const SizedBox(height: 14),
              // Tamil
              _LangTile(
                label: 'தமிழ்',
                isSelected: _selected == 'ta',
                onTap: () => _selectLanguage('ta'),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }
}
