import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_provider.dart';

class PrivateTab extends ConsumerWidget {
  const PrivateTab({super.key});

  void _startEditFlow(BuildContext context, String field, String currentValue, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController(text: currentValue == 'Non impostato' ? '' : currentValue);
        final otpCtrl = TextEditingController();
        bool otpSent = false;
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  otpSent ? Icons.lock_open : Icons.edit,
                  color: Colors.teal.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  otpSent ? 'Verifica OTP' : 'Modifica $field',
                  style: TextStyle(color: Colors.teal.shade800),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!otpSent)
                  TextField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      labelText: 'Nuovo $field',
                      labelStyle: TextStyle(color: Colors.teal.shade600),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Abbiamo inviato un codice a ${ctrl.text}',
                    style: TextStyle(color: Colors.teal.shade600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    decoration: InputDecoration(
                      labelText: 'Codice OTP',
                      helperText: 'Demo: inserisci 6 cifre qualsiasi',
                      helperStyle: TextStyle(color: Colors.teal.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annulla', style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!otpSent) {
                    setState(() => otpSent = true);
                  } else {
                    if (field == 'Email') {
                      ref.read(authProvider.notifier).updateProfile(email: ctrl.text);
                    } else if (field == 'Telefono') {
                      ref.read(authProvider.notifier).updateProfile(phone: ctrl.text);
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$field verificato e aggiornato'),
                        backgroundColor: Colors.green.shade600,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(otpSent ? 'Verifica' : 'Invia OTP'),
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
        // ═══════════════════════════════════════════════════════════════
        // EDITABLE WITH VERIFICATION
        // ═══════════════════════════════════════════════════════════════
        _buildSectionHeader('Contatti Verificabili'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            _buildEditableItem(
              context, ref,
              icon: Icons.email_outlined,
              label: 'Email',
              value: session.email,
              verified: true,
            ),
            Divider(color: Colors.teal.shade100),
            _buildEditableItem(
              context, ref,
              icon: Icons.phone_outlined,
              label: 'Telefono',
              value: session.phone ?? 'Non impostato',
              verified: session.phone != null,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // ═══════════════════════════════════════════════════════════════
        // READ-ONLY ACCOUNT INFO
        // ═══════════════════════════════════════════════════════════════
        _buildSectionHeader('Informazioni Account'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            _buildReadOnlyItem(Icons.fingerprint, 'User ID', '#${session.id}'),
            Divider(color: Colors.teal.shade100),
            _buildReadOnlyItem(Icons.check_circle_outline, 'Stato Account', 'Attivo', valueColor: Colors.green.shade600),
            Divider(color: Colors.teal.shade100),
            _buildReadOnlyItem(Icons.public, 'Paese', 'Italia'),
            Divider(color: Colors.teal.shade100),
            _buildReadOnlyItem(Icons.euro, 'Valuta', 'EUR'),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // ═══════════════════════════════════════════════════════════════
        // CONSENTS (read-only)
        // ═══════════════════════════════════════════════════════════════
        _buildSectionHeader('Consensi'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            _buildConsentItem(
              icon: Icons.description_outlined,
              label: 'Termini di Servizio',
              acceptedAt: DateTime(2024, 1, 15),
            ),
            Divider(color: Colors.teal.shade100),
            _buildConsentItem(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              acceptedAt: DateTime(2024, 1, 15),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.teal.shade800,
      ),
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

  Widget _buildReadOnlyItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade500),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: Colors.teal.shade600))),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.teal.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required String value,
    required bool verified,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: TextStyle(color: Colors.teal.shade600, fontSize: 12)),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified, size: 14, color: Colors.green.shade500),
                    ],
                  ],
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _startEditFlow(context, label, value, ref),
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Modifica'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentItem({
    required IconData icon,
    required String label,
    required DateTime acceptedAt,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w500)),
                Text(
                  'Accettato il ${acceptedAt.day}/${acceptedAt.month}/${acceptedAt.year}',
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade500),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, size: 20, color: Colors.green.shade500),
        ],
      ),
    );
  }
}
