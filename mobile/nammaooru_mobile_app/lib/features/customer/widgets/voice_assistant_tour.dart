import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/village_theme.dart';

/// First-time walkthrough for the Voice Assistant.
/// 3 simple Tamil-first steps so villagers know: tap mic → speak → tap Add.
/// Shown once (SharedPreferences flag), replayable via the ❓ AppBar button.
class VoiceAssistantTour extends StatefulWidget {
  final VoidCallback onFinish;

  const VoiceAssistantTour({super.key, required this.onFinish});

  static const _seenKey = 'voice_assistant_tour_seen';

  /// Whether the tour was already completed on this device
  static Future<bool> alreadySeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  @override
  State<VoiceAssistantTour> createState() => _VoiceAssistantTourState();
}

class _TourStep {
  final IconData icon;
  final Color iconColor;
  final String titleTamil;
  final String titleEnglish;
  final String bodyTamil;
  final String bodyEnglish;

  const _TourStep({
    required this.icon,
    required this.iconColor,
    required this.titleTamil,
    required this.titleEnglish,
    required this.bodyTamil,
    required this.bodyEnglish,
  });
}

class _VoiceAssistantTourState extends State<VoiceAssistantTour> {
  int _step = 0;

  static const List<_TourStep> _steps = [
    _TourStep(
      icon: Icons.mic,
      iconColor: Colors.red,
      titleTamil: 'மைக்கை தட்டி பேசுங்க',
      titleEnglish: 'Tap the mic & speak',
      bodyTamil: 'கீழே உள்ள பச்சை மைக் பட்டனை தட்டி,\nபொருள் பெயர் சொல்லுங்க:\n"தக்காளி", "அரிசி", "சீனி"',
      bodyEnglish: 'Tap the green mic button below and\nsay a product name',
    ),
    _TourStep(
      icon: Icons.stop_circle_outlined,
      iconColor: Colors.orange,
      titleTamil: 'பேசி முடிச்சா தானா நிற்கும்',
      titleEnglish: 'Stops by itself',
      bodyTamil: 'பேசி முடிச்சதும் 3 வினாடியில்\nதானாக நின்றுவிடும்.\nஉடனே நிறுத்த மீண்டும் தட்டுங்க.',
      bodyEnglish: 'Recording stops 3 seconds after you\nfinish talking — or tap again to stop',
    ),
    _TourStep(
      icon: Icons.add_shopping_cart,
      iconColor: VillageTheme.primaryGreen,
      titleTamil: '"Add" தட்டினா கார்ட்டில் சேரும்',
      titleEnglish: 'Tap "Add" on the product',
      bodyTamil: 'பொருட்கள் வந்ததும் "Add" தட்டுங்க.\nடைப் செய்யவும் முடியும்.\nமுடிந்ததும் கார்ட் → Checkout!',
      bodyEnglish: 'Tap Add on a product card.\nTyping works too. Then cart → checkout!',
    ),
  ];

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      VoiceAssistantTour.markSeen();
      widget.onFinish();
    }
  }

  void _skip() {
    VoiceAssistantTour.markSeen();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Big icon in colored circle
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.iconColor.withOpacity(0.12),
                  ),
                  child: Icon(step.icon, size: 44, color: step.iconColor),
                ),
                const SizedBox(height: 20),
                Text(
                  step.titleTamil,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  step.titleEnglish,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Text(
                  step.bodyTamil,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 6),
                Text(
                  step.bodyEnglish,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
                ),
                const SizedBox(height: 22),
                // Step dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    return Container(
                      width: i == _step ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _step
                            ? VillageTheme.primaryGreen
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                // Next / Got it
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VillageTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isLast ? 'சரி, புரிந்தது! • Got it!' : 'அடுத்து • Next',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (!isLast)
                  TextButton(
                    onPressed: _skip,
                    child: Text('Skip',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
