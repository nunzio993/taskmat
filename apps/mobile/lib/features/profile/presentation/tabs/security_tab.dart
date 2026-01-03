import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_provider.dart';

class SecurityTab extends ConsumerStatefulWidget {
  const SecurityTab({super.key});

  @override
  ConsumerState<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends ConsumerState<SecurityTab> {
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).value!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ═══════════════════════════════════════════════════════════════
        // ACTIVE SESSIONS
        // ═══════════════════════════════════════════════════════════════
        _buildSectionHeader('Sessioni Attive'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            _buildSessionItem(
              icon: Icons.phone_iphone,
              device: 'iPhone 13',
              location: 'Roma, IT',
              lastSeen: 'Sessione corrente',
              isCurrent: true,
            ),
            Divider(color: Colors.teal.shade100),
            _buildSessionItem(
              icon: Icons.laptop,
              device: 'Chrome su Windows',
              location: 'Milano, IT',
              lastSeen: 'Ultimo accesso 2h fa',
              isCurrent: false,
            ),
            Divider(color: Colors.teal.shade100),
            _buildSessionItem(
              icon: Icons.tablet,
              device: 'iPad Pro',
              location: 'Roma, IT',
              lastSeen: 'Ultimo accesso 3 giorni fa',
              isCurrent: false,
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        OutlinedButton.icon(
          onPressed: () => _showDisconnectAllDialog(context),
          icon: Icon(Icons.logout, color: Colors.red.shade400),
          label: Text('Disconnetti Tutti', style: TextStyle(color: Colors.red.shade400)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // ═══════════════════════════════════════════════════════════════
        // LOGIN METHOD
        // ═══════════════════════════════════════════════════════════════
        _buildSectionHeader('Metodo di Accesso'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Login via OTP',
              value: session.email,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Attivo', style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Per cambiare email o telefono vai alla tab Privato',
              style: TextStyle(fontSize: 12, color: Colors.teal.shade400, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // ═══════════════════════════════════════════════════════════════
        // APP PROTECTION
        // ═══════════════════════════════════════════════════════════════
        _buildSectionHeader('Protezione App'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            Row(
              children: [
                Icon(Icons.fingerprint, size: 24, color: Colors.teal.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sblocco Biometrico', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade800)),
                      Text('Face ID / Touch ID', style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
                    ],
                  ),
                ),
                Switch(
                  value: _biometricEnabled,
                  activeColor: Colors.teal.shade600,
                  onChanged: (val) => setState(() => _biometricEnabled = val),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // ═══════════════════════════════════════════════════════════════
        // ACCOUNT ACTIONS
        // ═══════════════════════════════════════════════════════════════
        _buildSectionHeader('Azioni Account'),
        const SizedBox(height: 12),
        
        _buildCard(
          children: [
            _buildActionItem(
              icon: Icons.pause_circle_outline,
              label: 'Disattiva Account',
              description: 'Nasconde temporaneamente il tuo profilo',
              color: Colors.orange,
              onTap: () => _showDeactivateDialog(context),
            ),
            Divider(color: Colors.teal.shade100),
            _buildActionItem(
              icon: Icons.delete_forever,
              label: 'Elimina Account',
              description: 'Rimuove permanentemente tutti i dati',
              color: Colors.red,
              onTap: () => _showDeleteDialog(context),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  void _showDisconnectAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text('Disconnetti Tutti', style: TextStyle(color: Colors.teal.shade800)),
          ],
        ),
        content: Text(
          'Verrai disconnesso da tutti i dispositivi. Dovrai effettuare nuovamente l\'accesso.',
          style: TextStyle(color: Colors.teal.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Tutte le sessioni disconnesse'), backgroundColor: Colors.green.shade600),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.pause_circle, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text('Disattiva Account', style: TextStyle(color: Colors.teal.shade800)),
          ],
        ),
        content: Text(
          'Il tuo profilo sarà nascosto ma i dati saranno conservati. Potrai riattivarlo in qualsiasi momento.',
          style: TextStyle(color: Colors.teal.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Account disattivato'), backgroundColor: Colors.orange.shade600),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Disattiva'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Elimina Account', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ATTENZIONE: Questa azione è irreversibile!',
              style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Tutti i tuoi dati, task, recensioni e cronologia saranno eliminati permanentemente.',
              style: TextStyle(color: Colors.teal.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Scrivi ELIMINA per confermare',
                labelStyle: TextStyle(color: Colors.red.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In real app, would verify confirmation text and call API
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Account eliminato'), backgroundColor: Colors.red.shade600),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Elimina'),
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

  Widget _buildSessionItem({
    required IconData icon,
    required String device,
    required String location,
    required String lastSeen,
    required bool isCurrent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.teal.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: isCurrent ? Colors.teal.shade600 : Colors.grey.shade500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade800)),
                Text('$location • $lastSeen', style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Questo', style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
            )
          else
            IconButton(
              icon: Icon(Icons.logout, size: 20, color: Colors.red.shade400),
              onPressed: () {},
              tooltip: 'Disconnetti',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
              Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade800)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
