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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  // Email regex pattern
  static final _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
  // Phone regex (Italian format: +39, 3xx, or 0xx)
  static final _phoneRegex = RegExp(r'^(\+39)?\s?[03]\d{8,10}$');

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
    if (!_formKey.currentState!.validate()) return;
    
    await ref.read(authProvider.notifier).updateProfile(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profilo aggiornato!')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica Dati Personali'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check))
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildField(
              label: 'Nome Completo', 
              controller: _nameCtrl, 
              icon: Icons.person_outline,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nome richiesto' : null,
            ),
            const SizedBox(height: 24),
            _buildField(
              label: 'Email', 
              controller: _emailCtrl, 
              icon: Icons.email_outlined, 
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email richiesta';
                if (!_emailRegex.hasMatch(v)) return 'Email non valida';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildField(
              label: 'Telefono', 
              controller: _phoneCtrl, 
              icon: Icons.phone_outlined, 
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return null; // Phone optional
                final cleaned = v.replaceAll(' ', '');
                if (!_phoneRegex.hasMatch(cleaned)) return 'Formato: +39 3xx... o 0xx...';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label, 
    required TextEditingController controller, 
    required IconData icon, 
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
