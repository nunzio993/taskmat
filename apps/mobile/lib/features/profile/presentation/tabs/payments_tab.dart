import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_provider.dart';

import '../../application/user_service.dart';

final paymentsProvider = FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  final service = ref.read(userServiceProvider.notifier);
  return service.getPaymentMethods();
});

class PaymentsTab extends ConsumerWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value!;
    final isHelper = session.role == 'helper';

    if (isHelper) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConnectStatus(context),
          const SizedBox(height: 24),
          const Text('Recent Earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          _buildEarningItem('Task #1234 - Plumbing', '€ 45.00', 'Today'),
          _buildEarningItem('Task #1102 - Moving', '€ 120.00', 'Yesterday'),
        ],
      );
    } else {
      final paymentsAsync = ref.watch(paymentsProvider);
      return paymentsAsync.when(
        data: (payments) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...payments.map((p) => _buildPaymentCard(
              context, 
              '${p.cardBrand.toUpperCase()} ending in ${p.last4}', 
              'Expires ${p.expMonth}/${p.expYear}', 
              p.isDefault
            )).toList(),
            if (payments.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No payment methods saved.'),
              )),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _showAddCardDialog(context, ref), 
              icon: const Icon(Icons.add), 
              label: const Text('Add Payment Method')
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      );
    }
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Card (Simulated)'),
        content: const Text('In a real app, this would open Stripe Elements or similar. For this MVP, we will add a mock Visa card.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                // Simulate generating a token and details
                await ref.read(userServiceProvider.notifier).addPaymentMethod({
                    'card_brand': 'visa',
                    'last4': '4242',
                    'exp_month': 12,
                    'exp_year': 2025,
                    'provider_token_id': 'tok_visa_${DateTime.now().millisecondsSinceEpoch}',
                    'is_default': false
                });
                ref.invalidate(paymentsProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }, 
            child: const Text('Add Mock Card')
          ),
        ],
      ),
    );
  }

  Widget _buildConnectStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stripe Connect Active', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Payouts enabled', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('View Payout Dashboard'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEarningItem(String title, String amount, String date) {
    return ListTile(
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
    );
  }

  Widget _buildPaymentCard(BuildContext context, String title, String subtitle, bool isDefault) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.credit_card),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isDefault ? const Icon(Icons.check_circle, color: Colors.green) : null,
      ),
    );
  }
}
