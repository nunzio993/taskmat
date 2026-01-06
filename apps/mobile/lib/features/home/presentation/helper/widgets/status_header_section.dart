import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/tasks_provider.dart';

/// Status header showing helper availability toggle and alerts
class StatusHeaderSection extends ConsumerWidget {
  const StatusHeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(helperAvailabilityProvider);
    final alertsAsync = ref.watch(helperAlertsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAvailable 
                ? [Colors.teal.shade50, Colors.teal.shade100.withValues(alpha: 0.5)]
                : [Colors.grey.shade100, Colors.grey.shade200.withValues(alpha: 0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAvailable ? Colors.teal.shade200 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.teal.shade600 : Colors.grey.shade500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAvailable ? Icons.check_circle : Icons.pause_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAvailable ? 'Sei disponibile' : 'In pausa',
                      style: TextStyle(
                        color: isAvailable ? Colors.teal.shade800 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isAvailable 
                        ? 'I clienti possono vedere le tue offerte'
                        : 'Non riceverai nuove richieste',
                      style: TextStyle(
                        color: isAvailable ? Colors.teal.shade600 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAvailable,
                activeTrackColor: Colors.teal.shade600,
                onChanged: (_) => ref.read(helperAvailabilityProvider.notifier).toggle(),
              ),
            ],
          ),
        ),
        alertsAsync.when(
          data: (alerts) {
            if (alerts.isEmpty) return const SizedBox.shrink();
            return Column(
              children: alerts.map((alert) => Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(alert, style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: () => context.push('/preferences'),
                      child: Text('Risolvi', style: TextStyle(color: Colors.orange.shade700)),
                    ),
                  ],
                ),
              )).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
