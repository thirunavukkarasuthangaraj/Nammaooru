import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../localization/language_provider.dart';

class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectivityProvider, LanguageProvider>(
      builder: (context, connectivityProvider, languageProvider, _) {
        if (!connectivityProvider.showAlert) {
          return child;
        }

        final isTamil = languageProvider.currentLanguage == 'ta';
        final message = isTamil
            ? connectivityProvider.alertMessageTamil
            : connectivityProvider.alertMessage;

        return Stack(
          children: [
            child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: connectivityProvider.getConnectionColor(),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        Icon(
                          connectivityProvider.getConnectionIcon(),
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            connectivityProvider.dismissAlert();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
