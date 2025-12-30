import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _orderUpdates = true;
  bool _promos = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          _buildSectionHeader('Channels'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Get real-time updates on your device'),
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Order summaries and receipts'),
            value: _emailEnabled,
            onChanged: (v) => setState(() => _emailEnabled = v),
          ),
           SwitchListTile(
            title: const Text('SMS Notifications'),
            subtitle: const Text('Text messages for critical updates'),
            value: _smsEnabled,
            onChanged: (v) => setState(() => _smsEnabled = v),
          ),
          
          _buildSectionHeader('Types'),
          SwitchListTile(
            title: const Text('Order Updates'),
            value: _orderUpdates,
            onChanged: (v) => setState(() => _orderUpdates = v),
          ),
          SwitchListTile(
            title: const Text('Promotions & Tips'),
            value: _promos,
            onChanged: (v) => setState(() => _promos = v),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(), 
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary, 
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
