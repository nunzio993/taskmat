import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_provider.dart';
import '../widgets/readiness_checklist.dart';

class PreferencesTab extends ConsumerWidget {
  const PreferencesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value!;
    final isHelper = session.role == 'helper';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isHelper) ...[
          _buildAvailabilitySection(context, ref, session),
          const Divider(height: 32),
          _buildMatchingSection(context, ref, session),
          const Divider(height: 32),
          _buildFiltersSection(context, ref, session),
          const Divider(height: 32),
        ],
        _buildNotificationsSection(context, ref, session),
        const SizedBox(height: 32), // Bottom padding
      ],
    );
  }

  // --- SECTIONS ---

  Widget _buildAvailabilitySection(BuildContext context, WidgetRef ref, UserSession session) {
    final bool isStripeReady = session.readiness['stripe'] ?? false;
    final bool isProfileReady = session.readiness['profile'] ?? false;
    final bool isCategoriesReady = session.readiness['categories'] ?? false;
    final bool canGoOnline = isStripeReady && isProfileReady && isCategoriesReady;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: session.isAvailable ? Colors.green.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: session.isAvailable ? Border.all(color: Colors.green) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.isAvailable ? 'You are ONLINE' : 'You are OFFLINE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: session.isAvailable ? Colors.green : null,
                    ),
                  ),
                  if (session.isAvailable)
                    const Text('Receiving tasks in your area', style: TextStyle(fontSize: 12)),
                ],
              ),
              Switch(
                value: session.isAvailable, 
                onChanged: canGoOnline 
                  ? (val) => ref.read(authProvider.notifier).updateProfile(isAvailable: val) 
                  : null,
              ),
            ],
          ),
        ),
        if (!canGoOnline) ...[
          const SizedBox(height: 16),
          ReadinessChecklist(
            readiness: session.readiness,
            onCompleteProfile: () {}, // Navigate to edit profile
            onConnectStripe: () {}, // Navigate to payments
          ),
        ],
        if (session.isAvailable) ...[
          const SizedBox(height: 16),
          const Text('Quick Pause', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPauseChip(ref, '30m'),
              const SizedBox(width: 8),
              _buildPauseChip(ref, '1h'),
              const SizedBox(width: 8),
              _buildPauseChip(ref, 'Until tomorrow'),
            ],
          ),
        ]
      ],
    );
  }

  Widget _buildMatchingSection(BuildContext context, WidgetRef ref, UserSession session) {
    final categories = ['Cleaning', 'Moving', 'Plumbing', 'Electrical', 'Gardening'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Matching Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        const Text('Service Categories'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: categories.map((cat) {
            final isSelected = session.categories.contains(cat);
            return FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (bool selected) {
                final newCats = List<String>.from(session.categories);
                if (selected) {
                  if (newCats.length < 5) newCats.add(cat);
                } else {
                  newCats.remove(cat);
                }
                ref.read(authProvider.notifier).updateProfile(categories: newCats);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Operations Radius: ${session.matchingRadius.toInt()} km'),
        Slider(
          value: session.matchingRadius,
          min: 1,
          max: 50,
          divisions: 49,
          label: '${session.matchingRadius.toInt()} km',
          onChanged: (val) {
             ref.read(authProvider.notifier).updateProfile(matchingRadius: val);
          },
        ),
      ],
    );
  }

  Widget _buildFiltersSection(BuildContext context, WidgetRef ref, UserSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Task Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Text('Accept Urgency', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['NOW', 'TODAY', 'SLOT'].map((urgency) {
            final isSelected = session.urgencyFilters.contains(urgency);
            return FilterChip(
              label: Text(urgency),
              selected: isSelected,
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
            const Text('Min Price'),
            Text('€ ${session.minPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: session.minPrice,
          min: 0,
          max: 100,
          divisions: 20,
          label: '€ ${session.minPrice.toInt()}',
          onChanged: (val) => ref.read(authProvider.notifier).updateProfile(minPrice: val),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context, WidgetRef ref, UserSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        // Client/Helper Common
        SwitchListTile(
          title: const Text('Chat Messages'),
          value: session.notifications['chat'] ?? true, 
          onChanged: (v) {}
        ),
        
        if (session.role == 'helper') ...[
          SwitchListTile(
            title: const Text('New Matching Tasks'),
            subtitle: const Text('Get alerted for tasks in your area'),
            value: session.notifications['match'] ?? true,
            activeColor: Colors.green,
            onChanged: (v) {}
          ),
          SwitchListTile(
            title: const Text('Task Updates'),
            value: session.notifications['updates'] ?? true,
            onChanged: (v) {}
          ),
        ]
      ],
    );
  }

  Widget _buildPauseChip(WidgetRef ref, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        // Mock pause logic: turn off availability
        ref.read(authProvider.notifier).updateProfile(isAvailable: false);
      },
      avatar: const Icon(Icons.pause, size: 16),
    );
  }
}
