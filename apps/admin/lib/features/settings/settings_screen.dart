import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';

// Provider for global settings
final settingsProvider = FutureProvider.autoDispose<List<GlobalSetting>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/settings');
  return (response.data as List).map((e) => GlobalSetting.fromJson(e)).toList();
});

class GlobalSetting {
  final String key;
  final dynamic value;
  final String? description;
  
  GlobalSetting({required this.key, required this.value, this.description});
  
  factory GlobalSetting.fromJson(Map<String, dynamic> json) {
    return GlobalSetting(
      key: json['key'],
      value: json['value'],
      description: json['description'],
    );
  }
  
  String get displayName {
    // Convert key to readable name
    return key.split('.').last.replaceAll('_', ' ').split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
  
  String get category {
    final parts = key.split('.');
    return parts.length > 1 ? parts.first : 'general';
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Impostazioni Globali',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configurazione sistema e policy',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(settingsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Aggiorna'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: settingsAsync.when(
              data: (settings) => _buildSettingsList(context, ref, settings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsList(BuildContext context, WidgetRef ref, List<GlobalSetting> settings) {
    // Group by category
    final grouped = <String, List<GlobalSetting>>{};
    for (final s in settings) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((entry) => _buildSettingsGroup(context, ref, entry.key, entry.value)).toList(),
      ),
    );
  }
  
  Widget _buildSettingsGroup(BuildContext context, WidgetRef ref, String category, List<GlobalSetting> settings) {
    final categoryName = category[0].toUpperCase() + category.substring(1);
    final icons = {
      'locks': Icons.lock_clock,
      'confirmation': Icons.check_circle,
      'chat': Icons.chat,
      'tasks': Icons.task,
      'task': Icons.task,
      'helper': Icons.person,
      'reviews': Icons.star,
    };
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icons[category] ?? Icons.settings, color: Colors.teal.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          ...settings.map((s) => _buildSettingItem(context, ref, s)),
        ],
      ),
    );
  }
  
  Widget _buildSettingItem(BuildContext context, WidgetRef ref, GlobalSetting setting) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  setting.displayName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                ),
                if (setting.description != null)
                  Text(
                    setting.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                const SizedBox(height: 4),
                Text(
                  setting.key,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              setting.value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.teal.shade600, size: 20),
            onPressed: () => _showEditDialog(context, ref, setting),
            tooltip: 'Modifica',
          ),
        ],
      ),
    );
  }
  
  void _showEditDialog(BuildContext context, WidgetRef ref, GlobalSetting setting) {
    final formKey = GlobalKey<FormState>();
    final valueController = TextEditingController(text: setting.value.toString());
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifica ${setting.displayName}'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  setting.key,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'Valore',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo della modifica *',
                    hintText: 'Es: Estensione timeout per nuova policy',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) => v == null || v.length < 5 ? 'Min 5 caratteri' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              try {
                final dio = ref.read(dioProvider);
                
                // Parse value to appropriate type
                dynamic parsedValue = valueController.text;
                if (parsedValue == 'true') parsedValue = true;
                else if (parsedValue == 'false') parsedValue = false;
                else if (int.tryParse(parsedValue) != null) parsedValue = int.parse(parsedValue);
                else if (double.tryParse(parsedValue) != null) parsedValue = double.parse(parsedValue);
                
                await dio.put('/admin/settings/${setting.key}', data: {
                  'value': parsedValue,
                  'reason': reasonController.text,
                });
                
                ref.refresh(settingsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impostazione aggiornata con successo')),
                  );
                }
              } on DioException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: ${e.response?.data?['detail'] ?? e.message}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
