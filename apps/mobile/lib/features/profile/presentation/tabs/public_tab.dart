import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_provider.dart';

class PublicTab extends ConsumerStatefulWidget {
  const PublicTab({super.key});

  @override
  ConsumerState<PublicTab> createState() => _PublicTabState();
}

class _PublicTabState extends ConsumerState<PublicTab> {
  bool _isEditing = false;
  late TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final session = ref.read(authProvider).value!;
    _bioCtrl = TextEditingController(text: session.bio ?? '');
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() async {
    if (_isEditing) {
      // Save changes
      await ref.read(authProvider.notifier).updateProfile(bio: _bioCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Public Profile Saved')));
      }
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).value!;
    final isHelper = session.role == 'helper';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Public Info', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: _toggleEdit,
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              label: Text(_isEditing ? 'Save' : 'Edit'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bioCtrl,
          enabled: _isEditing,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Bio',
            alignLabelWithHint: true,
          ),
        ),
        if (isHelper) ...[
          const SizedBox(height: 24),
          const Text('Portfolio', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildPortfolioItem(Colors.grey[300]!),
                _buildPortfolioItem(Colors.grey[400]!),
                if (_isEditing) _buildAddItem(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPortfolioItem(Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.image, color: Colors.white),
    );
  }

  Widget _buildAddItem() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Icon(Icons.add)),
    );
  }
}
