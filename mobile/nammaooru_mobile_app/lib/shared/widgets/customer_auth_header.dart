import 'gentle_motion.dart';
import 'package:flutter/material.dart';

/// Shared welcome panel for the customer authentication screens.
class CustomerAuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String languageLabel;
  final VoidCallback onLanguageChanged;

  const CustomerAuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.languageLabel,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.paddingOf(context).top + 12, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF3D9140)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -46,
            top: -58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Color(0x16FFFFFF), shape: BoxShape.circle),
              child: SizedBox(width: 150, height: 150),
            ),
          ),
          const Positioned(
            right: 72,
            bottom: -52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Color(0x0FFFFFFF), shape: BoxShape.circle),
              child: SizedBox(width: 120, height: 120),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                GentleEntrance(
                  child: Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 10,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/icons/logo-new.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NammaOoru',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      Text('Everything local, one place',
                          style: TextStyle(
                              color: Color(0xD9FFFFFF), fontSize: 10.5)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onLanguageChanged,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white12),
                  child: Text(languageLabel),
                ),
              ]),
              const SizedBox(height: 18),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.3,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, height: 1.4)),
            ],
          ),
        ],
      ),
    );
  }
}
