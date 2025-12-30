import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/user_service.dart';

// Provider to fetch addresses
final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) async {
  final service = ref.read(userServiceProvider.notifier);
  return service.getAddresses();
});

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: addressesAsync.when(
        data: (addresses) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: addresses.length,
          itemBuilder: (context, index) {
            final addr = addresses[index];
            return _buildAddressCard(
              context,
              icon: addr.name.toLowerCase() == 'work' ? Icons.work : Icons.home,
              label: addr.name,
              address: '${addr.addressLine}, ${addr.city} ${addr.postalCode}',
              isDefault: addr.isDefault,
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, {required IconData icon, required String label, required String address, bool isDefault = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(address),
        trailing: isDefault 
          ? const Chip(label: Text('Default', style: TextStyle(fontSize: 10))) 
          : null,
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final zipController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Label (e.g. Home, Work)')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: zipController, decoration: const InputDecoration(labelText: 'Postal Code')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(userServiceProvider.notifier).addAddress({
                  'name': nameController.text,
                  'address_line': addressController.text,
                  'city': cityController.text,
                  'postal_code': zipController.text,
                  'country': 'IT',
                  'is_default': false
                });
                ref.invalidate(addressesProvider); // Refresh list
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }, 
            child: const Text('Save')
          ),
        ],
      ),
    );
  }
}
