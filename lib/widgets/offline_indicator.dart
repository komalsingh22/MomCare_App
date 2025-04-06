import 'package:flutter/material.dart';
// import 'package:health_app/theme/app_theme.dart';

class OfflineIndicator extends StatelessWidget {
  final bool isOffline;
  final VoidCallback onTap;

  const OfflineIndicator({
    super.key,
    required this.isOffline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: const Color(0xFFFFF9C4),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off,
              size: 16,
              color: Colors.orange.shade800,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'You are offline. Some features may be limited.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB7791F),
                ),
              ),
            ),
            Icon(
              Icons.refresh,
              size: 16,
              color: Colors.orange.shade800,
            ),
          ],
        ),
      ),
    );
  }
} 