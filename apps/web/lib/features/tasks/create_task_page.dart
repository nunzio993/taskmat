import 'package:flutter/material.dart';

/// Create task wizard for desktop
class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  int _currentStep = 0;
  String? _selectedCategory;
  String _urgency = 'normal';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Steps indicator
          Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nuovo Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const SizedBox(height: 8),
                Text('Compila tutti i passaggi', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 32),
                _buildStepIndicator(0, 'Categoria', Icons.category),
                _buildStepIndicator(1, 'Descrizione', Icons.edit_note),
                _buildStepIndicator(2, 'Posizione', Icons.location_on),
                _buildStepIndicator(3, 'Budget', Icons.euro),
              ],
            ),
          ),
          const SizedBox(width: 24),
          
          // Right: Step content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step content
                  Expanded(child: _buildStepContent()),
                  
                  // Navigation buttons
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                          child: const Text('Indietro'),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentStep < 3) {
                            setState(() => _currentStep++);
                          } else {
                            // Submit
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task pubblicato!')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Text(_currentStep < 3 ? 'Continua' : 'Pubblica Task'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.teal.shade600 : (isActive ? Colors.teal.shade100 : Colors.grey.shade100),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted 
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Icon(icon, color: isActive ? Colors.teal.shade600 : Colors.grey.shade400, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? Colors.teal.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildDescriptionStep();
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildBudgetStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCategoryStep() {
    final categories = [
      ('Pulizie', Icons.cleaning_services),
      ('Traslochi', Icons.local_shipping),
      ('Montaggio', Icons.handyman),
      ('Riparazioni', Icons.plumbing),
      ('Giardinaggio', Icons.grass),
      ('Consegne', Icons.delivery_dining),
      ('Imbiancatura', Icons.format_paint),
      ('Altro', Icons.more_horiz),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Di cosa hai bisogno?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('Seleziona la categoria più adatta al tuo task', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: categories.map((cat) => _buildCategoryCard(cat.$1, cat.$2)).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String name, IconData icon) {
    final isSelected = _selectedCategory == name;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = name),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.teal.shade600 : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: isSelected ? Colors.teal.shade600 : Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Descrivi il task', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('Più dettagli inserisci, migliori saranno le offerte', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Titolo',
            hintText: 'Es. Pulizia appartamento 80mq',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Descrizione dettagliata',
            hintText: 'Descrivi cosa ti serve, dimensioni, particolarità...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),
        Text('Urgenza', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildUrgencyOption('low', 'Bassa', 'Entro 1 settimana'),
            const SizedBox(width: 16),
            _buildUrgencyOption('normal', 'Normale', 'Entro 2-3 giorni'),
            const SizedBox(width: 16),
            _buildUrgencyOption('high', 'Alta', 'Entro 24 ore'),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgencyOption(String value, String label, String subtitle) {
    final isSelected = _urgency == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _urgency = value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.teal.shade600 : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.teal.shade700 : Colors.grey.shade800)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dove serve?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('L\'indirizzo esatto sarà visibile solo all\'helper assegnato', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Indirizzo',
            hintText: 'Via, numero civico',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'Città',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'CAP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Note accesso (opzionale)',
            hintText: 'Es. Citofono "Rossi", 3° piano senza ascensore',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget e tempistiche', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Text('Indica quanto sei disposto a pagare per questo task', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Budget (€)',
            hintText: 'Es. 50',
            prefixIcon: const Icon(Icons.euro),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Il prezzo minimo per questa categoria è €10. Gli helper potranno proporti un prezzo diverso.',
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Summary
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Riepilogo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800)),
              const SizedBox(height: 16),
              _buildSummaryRow('Categoria', _selectedCategory ?? '-'),
              _buildSummaryRow('Titolo', _titleController.text.isEmpty ? '-' : _titleController.text),
              _buildSummaryRow('Città', _cityController.text.isEmpty ? '-' : _cityController.text),
              _buildSummaryRow('Urgenza', _urgency == 'high' ? 'Alta' : (_urgency == 'low' ? 'Bassa' : 'Normale')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
