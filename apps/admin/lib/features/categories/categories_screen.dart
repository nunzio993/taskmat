import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';

// Provider for categories
final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/categories');
  return (response.data as List).map((e) => Category.fromJson(e)).toList();
});

class Category {
  final int id;
  final String slug;
  final String displayName;
  final bool enabled;
  final double feePercent;
  final int feeMinCents;
  final int? feeMaxCents;
  final int serviceFloorCents;
  final bool isVariableCost;
  final int? expenseCapMinCents;
  final int? expenseCapMaxCents;
  final bool expenseReceiptRequired;
  
  Category({
    required this.id,
    required this.slug,
    required this.displayName,
    required this.enabled,
    required this.feePercent,
    required this.feeMinCents,
    this.feeMaxCents,
    required this.serviceFloorCents,
    required this.isVariableCost,
    this.expenseCapMinCents,
    this.expenseCapMaxCents,
    required this.expenseReceiptRequired,
  });
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      slug: json['slug'],
      displayName: json['display_name'],
      enabled: json['enabled'],
      feePercent: double.parse(json['fee_percent'].toString()),
      feeMinCents: json['fee_min_cents'],
      feeMaxCents: json['fee_max_cents'],
      serviceFloorCents: json['service_floor_cents'],
      isVariableCost: json['is_variable_cost'],
      expenseCapMinCents: json['expense_cap_min_cents'],
      expenseCapMaxCents: json['expense_cap_max_cents'],
      expenseReceiptRequired: json['expense_receipt_required'],
    );
  }
}

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
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
                    'Categorie',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestisci fee e impostazioni per categoria',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(categoriesProvider),
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
            child: categoriesAsync.when(
              data: (categories) => _buildCategoriesTable(context, ref, categories),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesTable(BuildContext context, WidgetRef ref, List<Category> categories) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
            columns: const [
              DataColumn(label: Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Stato', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Fee %', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Fee Min', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Prezzo Min', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Costi Variabili', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Azioni', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: categories.map((cat) => DataRow(
              cells: [
                DataCell(Text(cat.displayName, style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cat.enabled ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cat.enabled ? 'Attivo' : 'Disattivo',
                    style: TextStyle(
                      color: cat.enabled ? Colors.green.shade700 : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )),
                DataCell(Text('${cat.feePercent.toStringAsFixed(1)}%')),
                DataCell(Text('€${(cat.feeMinCents / 100).toStringAsFixed(2)}')),
                DataCell(Text('€${(cat.serviceFloorCents / 100).toStringAsFixed(0)}')),
                DataCell(Icon(
                  cat.isVariableCost ? Icons.check_circle : Icons.cancel,
                  color: cat.isVariableCost ? Colors.teal : Colors.grey.shade400,
                  size: 20,
                )),
                DataCell(IconButton(
                  icon: Icon(Icons.edit, color: Colors.teal.shade600, size: 20),
                  onPressed: () => _showEditDialog(context, ref, cat),
                  tooltip: 'Modifica',
                )),
              ],
            )).toList(),
          ),
        ),
      ),
    );
  }
  
  void _showEditDialog(BuildContext context, WidgetRef ref, Category category) {
    final formKey = GlobalKey<FormState>();
    final feePercentController = TextEditingController(text: category.feePercent.toString());
    final feeMinController = TextEditingController(text: (category.feeMinCents / 100).toString());
    final serviceFloorController = TextEditingController(text: (category.serviceFloorCents / 100).toString());
    final reasonController = TextEditingController();
    bool enabled = category.enabled;
    bool isVariableCost = category.isVariableCost;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Modifica ${category.displayName}'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Categoria Attiva'),
                      value: enabled,
                      onChanged: (v) => setState(() => enabled = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: feePercentController,
                      decoration: const InputDecoration(
                        labelText: 'Fee Percentuale (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Obbligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: feeMinController,
                      decoration: const InputDecoration(
                        labelText: 'Fee Minima (€)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Obbligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: serviceFloorController,
                      decoration: const InputDecoration(
                        labelText: 'Prezzo Minimo Servizio (€)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Obbligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Costi Variabili (Materiali)'),
                      subtitle: const Text('Task può includere spese extra'),
                      value: isVariableCost,
                      onChanged: (v) => setState(() => isVariableCost = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo della modifica *',
                        hintText: 'Es: Adeguamento fee per nuova policy',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (v) => v == null || v.length < 5 ? 'Min 5 caratteri' : null,
                    ),
                  ],
                ),
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
                  await dio.put('/admin/categories/${category.slug}', data: {
                    'enabled': enabled,
                    'fee_percent': double.parse(feePercentController.text),
                    'fee_min_cents': (double.parse(feeMinController.text) * 100).round(),
                    'service_floor_cents': (double.parse(serviceFloorController.text) * 100).round(),
                    'is_variable_cost': isVariableCost,
                    'reason': reasonController.text,
                  });
                  
                  ref.refresh(categoriesProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoria aggiornata con successo')),
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
      ),
    );
  }
}
