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
      return _buildHelperPayments(context, ref);
    } else {
      return _buildClientPayments(context, ref);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLIENT PAYMENTS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildClientPayments(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Metodi di Pagamento'),
        const SizedBox(height: 12),
        
        paymentsAsync.when(
          data: (payments) => _buildCard(
            children: [
              if (payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.credit_card_off, size: 48, color: Colors.teal.shade300),
                      const SizedBox(height: 8),
                      Text('Nessun metodo salvato', style: TextStyle(color: Colors.teal.shade500)),
                    ],
                  ),
                )
              else
                ...payments.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  return Column(
                    children: [
                      if (idx > 0) Divider(color: Colors.teal.shade100),
                      _buildPaymentMethodRow(context, ref, p),
                    ],
                  );
                }),
            ],
          ),
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )),
          error: (err, _) => _buildCard(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Errore: $err', style: TextStyle(color: Colors.red.shade400)),
            ),
          ]),
        ),
        
        const SizedBox(height: 16),
        
        ElevatedButton.icon(
          onPressed: () => _showAddCardDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Aggiungi Metodo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Receipts
        _buildSectionHeader('Ricevute'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            _buildReceiptRow('Task #1234 - Pulizie', '€ 45.00', '02/01/2024', 'Pagato'),
            Divider(color: Colors.teal.shade100),
            _buildReceiptRow('Task #1102 - Trasloco', '€ 120.00', '28/12/2023', 'Pagato'),
            Divider(color: Colors.teal.shade100),
            _buildReceiptRow('Task #1089 - Giardinaggio', '€ 35.00', '20/12/2023', 'Pagato'),
          ],
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER PAYMENTS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHelperPayments(BuildContext context, WidgetRef ref) {
    // Mock Stripe status
    const stripeStatus = 'COMPLETE'; // NOT_STARTED, IN_PROGRESS, COMPLETE
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Stripe Connect'),
        const SizedBox(height: 12),
        
        _buildStripeConnectCard(context, stripeStatus),
        
        const SizedBox(height: 24),
        
        _buildSectionHeader('Payout'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            _buildPayoutRow(Icons.pending, 'In Attesa', '€ 165.00', Colors.orange.shade600),
            Divider(color: Colors.teal.shade100),
            _buildPayoutRow(Icons.check_circle, 'Ultimo Payout', '€ 320.00', Colors.green.shade600),
            Divider(color: Colors.teal.shade100),
            _buildPayoutRow(Icons.calendar_today, 'Prossimo', '15/01/2024', Colors.teal.shade600),
          ],
        ),
        
        const SizedBox(height: 24),
        
        _buildSectionHeader('Guadagni Recenti'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            _buildEarningRow('Task #1234 - Idraulica', '€ 45.00', 'Oggi'),
            Divider(color: Colors.teal.shade100),
            _buildEarningRow('Task #1102 - Trasloco', '€ 120.00', 'Ieri'),
            Divider(color: Colors.teal.shade100),
            _buildEarningRow('Task #1089 - Montaggio', '€ 35.00', '2 giorni fa'),
          ],
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStripeConnectCard(BuildContext context, String status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String buttonText;
    
    switch (status) {
      case 'COMPLETE':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        statusText = 'Account Attivo';
        buttonText = 'Gestisci Account';
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.pending;
        statusText = 'In Verifica';
        buttonText = 'Completa Registrazione';
        break;
      default:
        statusColor = Colors.grey.shade500;
        statusIcon = Icons.warning;
        statusText = 'Non Configurato';
        buttonText = 'Configura Stripe';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Icon(Icons.account_balance, color: Colors.teal.shade600, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stripe Connect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(statusText, style: TextStyle(color: statusColor, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════
  
  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.credit_card, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            Text('Aggiungi Carta', style: TextStyle(color: Colors.teal.shade800)),
          ],
        ),
        content: Text(
          'In un\'app reale si aprirebbe Stripe Elements. Per questa demo aggiungeremo una carta Visa mock.',
          style: TextStyle(color: Colors.teal.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red.shade600),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildPaymentMethodRow(BuildContext context, WidgetRef ref, PaymentMethod p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.credit_card, color: Colors.teal.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.cardBrand.toUpperCase()} •••• ${p.last4}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade800),
                ),
                Text(
                  'Scade ${p.expMonth}/${p.expYear}',
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade500),
                ),
              ],
            ),
          ),
          if (p.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Default', style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.bold)),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.teal.shade400),
            onSelected: (value) {
              // Handle actions
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'default', child: Text('Imposta Default')),
              const PopupMenuItem(value: 'remove', child: Text('Rimuovi')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String title, String amount, String date, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.receipt_long, size: 20, color: Colors.teal.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade800)),
                Text(date, style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              Text(status, style: TextStyle(fontSize: 11, color: Colors.green.shade600)),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.teal.shade300),
        ],
      ),
    );
  }

  Widget _buildPayoutRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: Colors.teal.shade600))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
        ],
      ),
    );
  }

  Widget _buildEarningRow(String title, String amount, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.euro, size: 20, color: Colors.green.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade800)),
                Text(date, style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade600)),
        ],
      ),
    );
  }
}
