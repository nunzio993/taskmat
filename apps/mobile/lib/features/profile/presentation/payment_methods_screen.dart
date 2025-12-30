import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPaymentCard(context, 'Visa ending in 4242', 'Expires 12/26', true),
          const SizedBox(height: 16),
          _buildPaymentCard(context, 'Mastercard ending in 8888', 'Expires 01/25', false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Card Feature Pending Integration')));
        },
        label: const Text('Add Card'),
        icon: const Icon(Icons.add_card),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, String title, String subtitle, bool isDefault) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.credit_card, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: isDefault 
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
        onTap: () {
           if(!isDefault) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set as default')));
           }
        },
      ),
    );
  }
}
