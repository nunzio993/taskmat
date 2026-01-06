import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/tasks_provider.dart';

/// KPI section showing helper earnings and rating
class HelperKpisSection extends ConsumerWidget {
  const HelperKpisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(helperEarningsProvider);
    
    return earningsAsync.when(
      data: (earnings) => Row(
        children: [
          Expanded(child: _buildKpiCard(
            icon: Icons.today,
            label: 'Oggi',
            value: '€${(earnings.todayCents / 100).toStringAsFixed(0)}',
            color: Colors.teal,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(
            icon: Icons.date_range,
            label: 'Settimana',
            value: '€${(earnings.weekCents / 100).toStringAsFixed(0)}',
            color: Colors.teal,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(
            icon: Icons.account_balance_wallet,
            label: 'In Attesa',
            value: '€${(earnings.pendingPayoutCents / 100).toStringAsFixed(0)}',
            color: Colors.orange,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(
            icon: Icons.star,
            label: '${earnings.reviewCount} rec.',
            value: earnings.rating.toStringAsFixed(1),
            color: Colors.amber,
          )),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Errore caricamento KPI'),
    );
  }
  
  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color.shade600, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(color: color.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}
