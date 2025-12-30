import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_provider.dart';

class PrivateTab extends ConsumerWidget {
  const PrivateTab({super.key});

  void _startEditFlow(BuildContext context, String field, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        bool otpSent = false;
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(otpSent ? 'Enter OTP' : 'Update $field'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!otpSent)
                  TextField(controller: ctrl, decoration: InputDecoration(labelText: 'New $field'))
                else
                  const TextField(decoration: InputDecoration(labelText: '123456', helperText: 'Mock OTP: Any 6 digits')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (!otpSent) {
                    setState(() => otpSent = true);
                  } else {
                    // "Verify" OTP and save
                    if (field == 'Email') {
                        ref.read(authProvider.notifier).updateProfile(email: ctrl.text);
                    } else if (field == 'Phone') {
                        ref.read(authProvider.notifier).updateProfile(phone: ctrl.text);
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verified & Updated')));
                  }
                },
                child: Text(otpSent ? 'Verify & Save' : 'Send OTP'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildReadOnlyItem('User ID', '#${session.id}'),
        _buildReadOnlyItem('Account Status', 'Active', color: Colors.green),
        const Divider(height: 32),
        _buildEditableItem(context, ref, 'Email', session.email, Icons.email),
        _buildEditableItem(context, ref, 'Phone', session.phone ?? 'Not set', Icons.phone),
      ],
    );
  }

  Widget _buildReadOnlyItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEditableItem(BuildContext context, WidgetRef ref, String label, String value, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: TextButton(
        onPressed: () => _startEditFlow(context, label, ref),
        child: const Text('Change'),
      ),
    );
  }
}
