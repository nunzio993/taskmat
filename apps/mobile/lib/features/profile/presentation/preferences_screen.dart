import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_provider.dart';
import 'widgets/readiness_checklist.dart';
import '../../../core/constants/categories.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  // Availability Schedule State
  bool _scheduleEnabled = false;
  final Map<int, List<TimeOfDay>> _weeklySchedule = {};
  
  // Helper preferences
  int _maxActiveTasks = 3;
  double _minClientRating = 0;
  bool _hideHighCancel = false;
  bool _paymentVerifiedOnly = false;
  String _defaultOfferNote = '';
  
  // Client preferences
  String _defaultCategory = 'General';
  String _defaultUrgency = 'medium';
  String _offerSortBy = 'price';
  bool _verifiedHelpersOnly = false;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Preferenze', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.teal.shade600),
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return Center(child: Text('Effettua il login', style: TextStyle(color: Colors.teal.shade400)));
          }
          
          final isHelper = session.role == 'helper';
          final isClient = session.role == 'client';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ═══════════════════════════════════════════════════════════
              // COMMON SECTION
              // ═══════════════════════════════════════════════════════════
              _buildSectionHeader(Icons.settings, 'Impostazioni Generali'),
              const SizedBox(height: 12),
              _buildCommonNotificationsSection(session),
              const SizedBox(height: 16),
              _buildLanguageSection(),
              const SizedBox(height: 16),
              _buildPrivacySection(),
              
              const SizedBox(height: 32),
              
              // ═══════════════════════════════════════════════════════════
              // HELPER SECTION
              // ═══════════════════════════════════════════════════════════
              if (isHelper) ...[
                _buildSectionHeader(Icons.handyman, 'Impostazioni Helper'),
                const SizedBox(height: 12),
                _buildMatchingSection(session),
                const SizedBox(height: 16),
                _buildAvailabilitySection(session),
                const SizedBox(height: 16),
                _buildMessagingSection(),
                const SizedBox(height: 16),
                _buildQualityFiltersSection(),
                const SizedBox(height: 16),
                _buildStripeStatusSection(session),
                const SizedBox(height: 32),
              ],
              
              // ═══════════════════════════════════════════════════════════
              // CLIENT SECTION
              // ═══════════════════════════════════════════════════════════
              if (isClient) ...[
                _buildSectionHeader(Icons.person, 'Impostazioni Cliente'),
                const SizedBox(height: 12),
                _buildTaskDefaultsSection(),
                const SizedBox(height: 16),
                _buildOffersViewSection(),
              ],
              
              const SizedBox(height: 48),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400))),
        error: (e, st) => Center(child: Text('Errore: $e', style: TextStyle(color: Colors.red.shade600))),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.teal.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal.shade800,
          )),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, IconData? icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Colors.teal.shade600),
                  const SizedBox(width: 8),
                ],
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON SECTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCommonNotificationsSection(UserSession session) {
    return _buildCard(
      title: 'Notifiche',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          _buildSwitchTile(
            'Notifiche Push',
            'Ricevi notifiche per messaggi e aggiornamenti',
            session.notifications['chat'] ?? true,
            (v) {},
          ),
          Divider(color: Colors.teal.shade100),
          _buildSwitchTile(
            'Ore di Silenzio',
            'Non disturbare dalle 22:00 alle 08:00',
            false,
            (v) {},
          ),
          Divider(color: Colors.teal.shade100),
          _buildSwitchTile(
            'Email Riepilogo',
            'Ricevi email settimanali',
            false,
            (v) {},
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    return _buildCard(
      title: 'Lingua e Formato',
      icon: Icons.language,
      child: Column(
        children: [
          _buildDropdownTile(
            'Lingua App',
            'Italiano',
            ['Italiano', 'English', 'Español'],
            (v) {},
          ),
          Divider(color: Colors.teal.shade100),
          _buildDropdownTile(
            'Formato Ora',
            '24h',
            ['24h', '12h'],
            (v) {},
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return _buildCard(
      title: 'Privacy',
      icon: Icons.lock_outline,
      child: Column(
        children: [
          _buildSwitchTile(
            'Info Minime',
            'Mostra dettagli completi solo dopo assegnazione',
            true,
            (v) {},
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER SECTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMatchingSection(UserSession session) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return _buildCard(
      title: 'Matching',
      icon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categorie Servizi', style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = session.categories.contains(cat.displayName);
                return FilterChip(
                  avatar: Icon(getCategoryIcon(cat.slug), size: 16),
                  label: Text(cat.displayName),
                  selected: isSelected,
                  selectedColor: Colors.teal.shade100,
                  checkmarkColor: Colors.teal.shade700,
                  onSelected: (selected) {
                    final newCats = List<String>.from(session.categories);
                    if (selected) {
                      newCats.add(cat.displayName);
                    } else if (newCats.length > 1) {
                      newCats.remove(cat.displayName);
                    }
                    ref.read(authProvider.notifier).updateProfile(categories: newCats);
                  },
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Errore: $e', style: TextStyle(color: Colors.red.shade600)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Raggio Operativo', style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('${session.matchingRadius.toInt()} km', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.teal.shade400,
              thumbColor: Colors.teal.shade600,
              overlayColor: Colors.teal.shade100,
              inactiveTrackColor: Colors.teal.shade100,
            ),
            child: Slider(
              value: session.matchingRadius,
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (val) => ref.read(authProvider.notifier).updateProfile(matchingRadius: val),
            ),
          ),
          const SizedBox(height: 16),
          Text('Urgenza Accettata', style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['NOW', 'TODAY', 'SLOT'].map((urgency) {
              final isSelected = session.urgencyFilters.contains(urgency);
              return FilterChip(
                label: Text(urgency),
                selected: isSelected,
                selectedColor: Colors.teal.shade100,
                checkmarkColor: Colors.teal.shade700,
                onSelected: (selected) {
                  final newFilters = Set<String>.from(session.urgencyFilters);
                  if (selected) newFilters.add(urgency); else newFilters.remove(urgency);
                  ref.read(authProvider.notifier).updateProfile(urgencyFilters: newFilters);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prezzo Minimo', style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500)),
              Text('€${session.minPrice.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.teal.shade400,
              thumbColor: Colors.teal.shade600,
              inactiveTrackColor: Colors.teal.shade100,
            ),
            child: Slider(
              value: session.minPrice,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (val) => ref.read(authProvider.notifier).updateProfile(minPrice: val),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Task Attive Max', style: TextStyle(color: Colors.grey.shade600)),
                Text('$_maxActiveTasks', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection(UserSession session) {
    final bool canGoOnline = (session.readiness['stripe'] ?? false) && 
                             (session.readiness['profile'] ?? false) && 
                             (session.readiness['categories'] ?? false);

    return _buildCard(
      title: 'Disponibilità',
      icon: Icons.access_time,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manual Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: session.isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: session.isAvailable ? Colors.green.shade300 : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.isAvailable ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: session.isAvailable ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                    if (session.isAvailable)
                      Text('Ricevi task nella tua zona', style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                  ],
                ),
                Switch(
                  value: session.isAvailable,
                  activeColor: Colors.green,
                  onChanged: canGoOnline ? (val) => ref.read(authProvider.notifier).updateProfile(isAvailable: val) : null,
                ),
              ],
            ),
          ),
          
          if (!canGoOnline) ...[
            const SizedBox(height: 12),
            ReadinessChecklist(
              readiness: session.readiness,
              onCompleteProfile: () {},
              onConnectStripe: () {},
            ),
          ],
          
          const SizedBox(height: 20),
          Divider(color: Colors.teal.shade100),
          const SizedBox(height: 12),
          
          // Schedule Toggle
          _buildSwitchTile(
            'Orari Programmati',
            'Imposta la tua disponibilità settimanale',
            _scheduleEnabled,
            (v) => setState(() => _scheduleEnabled = v),
          ),
          
          if (_scheduleEnabled) ...[
            const SizedBox(height: 16),
            _buildWeeklySchedule(),
          ],
          
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Auto-Offline',
            'Vai offline automaticamente dopo 8 ore',
            false,
            (v) {},
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    final days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Orari Settimanali', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: 18, color: Colors.teal.shade600),
                label: Text('Eccezione', style: TextStyle(color: Colors.teal.shade600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...days.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(entry.value, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade700)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Text('09:00 - 18:00', style: TextStyle(color: Colors.teal.shade600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.teal.shade400),
                    onPressed: () {},
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessagingSection() {
    return _buildCard(
      title: 'Messaggistica',
      icon: Icons.message_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nota Default Offerta', style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Es: Disponibile subito!',
              hintStyle: TextStyle(color: Colors.teal.shade300),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
              ),
            ),
            maxLines: 2,
            onChanged: (v) => setState(() => _defaultOfferNote = v),
          ),
          const SizedBox(height: 16),
          Text('Risposte Rapide', style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTemplateChip('Quando ti serve?'),
              _buildTemplateChip('Posso vedere foto?'),
              _buildTemplateChip('Arrivo in 30 min'),
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.teal.shade400),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Text(text, style: TextStyle(color: Colors.teal.shade700, fontSize: 13)),
    );
  }

  Widget _buildQualityFiltersSection() {
    return _buildCard(
      title: 'Filtri Qualità',
      icon: Icons.star_outline,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rating Min Cliente', style: TextStyle(color: Colors.teal.shade600)),
              Text(_minClientRating > 0 ? '⭐ ${_minClientRating.toStringAsFixed(1)}+' : 'Tutti', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.teal.shade400,
              thumbColor: Colors.teal.shade600,
              inactiveTrackColor: Colors.teal.shade100,
            ),
            child: Slider(
              value: _minClientRating,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (val) => setState(() => _minClientRating = val),
            ),
          ),
          Divider(color: Colors.teal.shade100),
          _buildSwitchTile(
            'Nascondi Alto Cancellazione',
            'Nascondi clienti con >30% cancellazioni',
            _hideHighCancel,
            (v) => setState(() => _hideHighCancel = v),
          ),
          Divider(color: Colors.teal.shade100),
          _buildSwitchTile(
            'Solo Pagamento Verificato',
            'Mostra solo clienti con carta verificata',
            _paymentVerifiedOnly,
            (v) => setState(() => _paymentVerifiedOnly = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStripeStatusSection(UserSession session) {
    final stripeReady = session.readiness['stripe'] ?? false;
    
    return _buildCard(
      title: 'Stripe Connect',
      icon: Icons.account_balance,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: stripeReady ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stripeReady ? Colors.green.shade200 : Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              stripeReady ? Icons.check_circle : Icons.warning,
              color: stripeReady ? Colors.green.shade600 : Colors.orange.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stripeReady ? 'Account Connesso' : 'Setup Incompleto',
                    style: TextStyle(fontWeight: FontWeight.bold, color: stripeReady ? Colors.green.shade700 : Colors.orange.shade700),
                  ),
                  Text(
                    stripeReady ? 'Puoi ricevere pagamenti' : 'Completa la configurazione',
                    style: TextStyle(fontSize: 12, color: stripeReady ? Colors.green.shade600 : Colors.orange.shade600),
                  ),
                ],
              ),
            ),
            if (!stripeReady)
              TextButton(
                onPressed: () {},
                child: Text('Configura', style: TextStyle(color: Colors.teal.shade600)),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLIENT SECTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTaskDefaultsSection() {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return _buildCard(
      title: 'Default Task',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          categoriesAsync.when(
            data: (categories) => _buildDropdownTile(
              'Categoria Default',
              _defaultCategory,
              categories.map((c) => c.displayName).toList(),
              (v) => setState(() => _defaultCategory = v ?? categories.first.displayName),
            ),
            loading: () => const Center(child: SizedBox(height: 48, child: CircularProgressIndicator())),
            error: (e, _) => Text('Errore categorie: $e'),
          ),
          Divider(color: Colors.teal.shade100),
          _buildDropdownTile(
            'Urgenza Default',
            _defaultUrgency.toUpperCase(),
            ['LOW', 'MEDIUM', 'HIGH'],
            (v) => setState(() => _defaultUrgency = v?.toLowerCase() ?? 'medium'),
          ),
          Divider(color: Colors.teal.shade100),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Template Task', style: TextStyle(color: Colors.teal.shade700)),
            trailing: Icon(Icons.chevron_right, color: Colors.teal.shade400),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return _buildCard(
      title: 'Pagamenti',
      icon: Icons.payment,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.credit_card, color: Colors.teal.shade600),
            title: const Text('Metodo di Pagamento'),
            subtitle: const Text('Visa ****4242'),
            trailing: Icon(Icons.chevron_right, color: Colors.teal.shade400),
            onTap: () {},
          ),
          Divider(color: Colors.teal.shade100),
          _buildSwitchTile(
            'Conferma Biometrica',
            'Richiedi impronta per pagamenti',
            false,
            (v) {},
          ),
        ],
      ),
    );
  }

  Widget _buildOffersViewSection() {
    return _buildCard(
      title: 'Visualizzazione Offerte',
      icon: Icons.visibility_outlined,
      child: Column(
        children: [
          _buildDropdownTile(
            'Ordina Per',
            _offerSortBy == 'price' ? 'Prezzo' : (_offerSortBy == 'rating' ? 'Rating' : 'Data'),
            ['Prezzo', 'Rating', 'Data'],
            (v) {
              final mapping = {'Prezzo': 'price', 'Rating': 'rating', 'Data': 'date'};
              setState(() => _offerSortBy = mapping[v] ?? 'price');
            },
          ),
          Divider(color: Colors.teal.shade100),
          _buildSwitchTile(
            'Solo Helper Verificati',
            'Mostra solo helper con profilo verificato',
            _verifiedHelpersOnly,
            (v) => setState(() => _verifiedHelpersOnly = v),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade800)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.teal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String label, String value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.teal.shade700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              underline: const SizedBox(),
              isDense: true,
              style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w500),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
