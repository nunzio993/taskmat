import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_provider.dart';

class EditPersonalProfileScreen extends ConsumerStatefulWidget {
  const EditPersonalProfileScreen({super.key});

  @override
  ConsumerState<EditPersonalProfileScreen> createState() => _EditPersonalProfileScreenState();
}

class _EditPersonalProfileScreenState extends ConsumerState<EditPersonalProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final session = ref.read(authProvider).value!;
    _nameCtrl = TextEditingController(text: session.name);
    _emailCtrl = TextEditingController(text: session.email);
    _phoneCtrl = TextEditingController(text: session.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(authProvider.notifier).updateProfile(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Personal Info'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildField(label: 'Full Name', controller: _nameCtrl, icon: Icons.person_outline),
          const SizedBox(height: 24),
          _buildField(label: 'Email Address', controller: _emailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 24),
          _buildField(label: 'Phone Number', controller: _phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, required IconData icon, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
