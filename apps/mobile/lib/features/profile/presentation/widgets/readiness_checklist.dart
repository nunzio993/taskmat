import 'package:flutter/material.dart';

class ReadinessChecklist extends StatelessWidget {
  final Map<String, bool> readiness;
  final VoidCallback onCompleteProfile;
  final VoidCallback onConnectStripe;

  const ReadinessChecklist({
    super.key, 
    required this.readiness,
    required this.onCompleteProfile,
    required this.onConnectStripe,
  });

  @override
  Widget build(BuildContext context) {
    final bool isStripeReady = readiness['stripe'] ?? false;
    final bool isProfileReady = readiness['profile'] ?? false;
    final bool isCategoriesReady = readiness['categories'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              const Text(
                'Requirements to go Online', 
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCheckItem(context, 'Identity Verified', true), // Mock always true
          _buildCheckItem(context, 'Stripe Connected', isStripeReady, onTap: isStripeReady ? null : onConnectStripe),
          _buildCheckItem(context, 'Profile Completed (Bio, Photo)', isProfileReady, onTap: isProfileReady ? null : onCompleteProfile),
          _buildCheckItem(context, 'At least 1 Service Category', isCategoriesReady, onTap: null), // Handled in same screen
        ],
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String label, bool isDone, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isDone ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (!isDone && onTap != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
              child: const Text('Fix', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
