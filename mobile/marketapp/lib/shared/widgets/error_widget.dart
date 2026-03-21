import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class CustomErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;
  final bool showRetryButton;
  
  const CustomErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.showRetryButton = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetryButton && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData? icon;
  final Widget? action;
  
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.action,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(String error)? errorBuilder;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });
  
  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  String? _error;
  
  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      setState(() {
        _error = details.exception.toString();
      });
    };
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ??
          CustomErrorWidget(
            title: 'Something went wrong',
            message: _error!,
            onRetry: () {
              setState(() {
                _error = null;
              });
            },
          );
    }
    
    return widget.child;
  }
}