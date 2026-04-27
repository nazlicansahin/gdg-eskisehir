import 'package:flutter/material.dart';

class RuntimeIntegrityGate extends StatelessWidget {
  const RuntimeIntegrityGate({
    super.key,
    required this.reasons,
  });

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 56,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Security verification failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This device or runtime environment does not meet app security requirements.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  reasons.join(', '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
