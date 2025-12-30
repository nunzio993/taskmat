import 'package:flutter/material.dart';

class SecurityTab extends StatelessWidget {
  const SecurityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Active Sessions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildSessionItem(context, 'iPhone 13', 'Rome, IT', 'Current Device', true),
        _buildSessionItem(context, 'Chrome on Windows', 'Milan, IT', 'Last active 2h ago', false),
        
        const Divider(height: 48),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSessionItem(BuildContext context, String device, String location, String status, bool isCurrent) {
    return ListTile(
      leading: Icon(isCurrent ? Icons.phone_iphone : Icons.laptop),
      title: Text(device),
      subtitle: Text('$location • $status'),
      trailing: isCurrent 
        ? const Chip(label: Text('This Device', style: TextStyle(fontSize: 10))) 
        : IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () {}),
    );
  }
}
