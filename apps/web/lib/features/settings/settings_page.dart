import 'package:flutter/material.dart';

/// Settings page for desktop
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _marketingEmails = false;
  String _language = 'it';
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settings sections
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: [
                    // Notifications
                    _buildSettingsCard(
                      'Notifiche',
                      Icons.notifications_outlined,
                      [
                        _buildSwitchTile('Notifiche email', 'Ricevi aggiornamenti via email', _emailNotifications, (v) => setState(() => _emailNotifications = v)),
                        _buildSwitchTile('Notifiche push', 'Ricevi notifiche sul browser', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
                        _buildSwitchTile('SMS', 'Ricevi SMS per eventi importanti', _smsNotifications, (v) => setState(() => _smsNotifications = v)),
                        _buildSwitchTile('Email marketing', 'Offerte e novità da TaskMat', _marketingEmails, (v) => setState(() => _marketingEmails = v)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Privacy
                    _buildSettingsCard(
                      'Privacy',
                      Icons.lock_outline,
                      [
                        _buildActionTile('Visibilità profilo', 'Pubblico', Icons.visibility_outlined, () {}),
                        _buildActionTile('Condivisione posizione', 'Solo durante i task', Icons.location_on_outlined, () {}),
                        _buildActionTile('Scarica i miei dati', 'Esporta tutti i tuoi dati', Icons.download_outlined, () {}),
                        _buildActionTile('Elimina account', 'Elimina permanentemente', Icons.delete_outline, () {}, isDestructive: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              
              // Right column
              Expanded(
                child: Column(
                  children: [
                    // Preferences
                    _buildSettingsCard(
                      'Preferenze',
                      Icons.tune_outlined,
                      [
                        _buildDropdownTile('Lingua', _language, {'it': 'Italiano', 'en': 'English'}, (v) => setState(() => _language = v!)),
                        _buildActionTile('Tema', 'Sistema', Icons.brightness_6_outlined, () {}),
                        _buildActionTile('Valuta', 'Euro (€)', Icons.euro_outlined, () {}),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Payments
                    _buildSettingsCard(
                      'Pagamenti',
                      Icons.payment_outlined,
                      [
                        _buildActionTile('Metodi di pagamento', '•••• 4242', Icons.credit_card_outlined, () {}),
                        _buildActionTile('Stripe Connect', 'Collegato', Icons.account_balance_outlined, () {}, trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                          child: Text('Attivo', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                        )),
                        _buildActionTile('Storico transazioni', 'Visualizza tutte', Icons.receipt_long_outlined, () {}),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Security
                    _buildSettingsCard(
                      'Sicurezza',
                      Icons.security_outlined,
                      [
                        _buildActionTile('Cambia password', 'Ultima modifica: 30 giorni fa', Icons.key_outlined, () {}),
                        _buildActionTile('Autenticazione a due fattori', 'Non attiva', Icons.smartphone_outlined, () {}),
                        _buildActionTile('Sessioni attive', '2 dispositivi', Icons.devices_outlined, () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TaskMat v1.0.0', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('© 2026 TaskMat. Tutti i diritti riservati.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('Termini di servizio')),
                TextButton(onPressed: () {}, child: const Text('Privacy Policy')),
                TextButton(onPressed: () {}, child: const Text('Contattaci')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal.shade600, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.teal.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false, Widget? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: isDestructive ? Colors.red : Colors.grey.shade600, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : null)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownTile(String title, String value, Map<String, String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
