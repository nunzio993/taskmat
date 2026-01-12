import 'package:flutter/material.dart';

/// Find Work page for helpers to browse available tasks
class FindWorkPage extends StatelessWidget {
  const FindWorkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Filters sidebar
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
                Text('Filtri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const SizedBox(height: 24),
                
                // Category filter
                Text('Categoria', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('Tutte', true),
                    _buildFilterChip('Pulizie', false),
                    _buildFilterChip('Traslochi', false),
                    _buildFilterChip('Montaggio', false),
                    _buildFilterChip('Riparazioni', false),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Distance filter
                Text('Distanza', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                Slider(
                  value: 10,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '10 km',
                  activeColor: Colors.teal.shade600,
                  onChanged: (v) {},
                ),
                Text('Entro 10 km', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                
                // Budget filter
                Text('Budget minimo', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: 'any',
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'any', child: Text('Qualsiasi')),
                    DropdownMenuItem(value: '20', child: Text('Min. €20')),
                    DropdownMenuItem(value: '50', child: Text('Min. €50')),
                    DropdownMenuItem(value: '100', child: Text('Min. €100')),
                  ],
                  onChanged: (v) {},
                ),
                const SizedBox(height: 24),
                
                // Urgency filter
                Text('Urgenza', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: false,
                  onChanged: (v) {},
                  title: const Text('Solo urgenti'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Resetta filtri'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          
          // Right: Task grid
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text('24 task disponibili', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    const Spacer(),
                    // Sort dropdown
                    DropdownButton<String>(
                      value: 'recent',
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'recent', child: Text('Più recenti')),
                        DropdownMenuItem(value: 'price_high', child: Text('Prezzo più alto')),
                        DropdownMenuItem(value: 'price_low', child: Text('Prezzo più basso')),
                        DropdownMenuItem(value: 'distance', child: Text('Più vicini')),
                      ],
                      onChanged: (v) {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Task grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => _buildTaskCard(index),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade600 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTaskCard(int index) {
    final tasks = [
      ('Pulizia appartamento', 'Pulizie', '€50', '2.3 km', false),
      ('Montaggio IKEA', 'Montaggio', '€35', '1.8 km', true),
      ('Trasloco piccolo', 'Traslochi', '€120', '4.5 km', false),
      ('Riparazione rubinetto', 'Riparazioni', '€40', '0.8 km', false),
      ('Giardinaggio', 'Giardinaggio', '€60', '3.2 km', true),
      ('Consegna mobili', 'Consegne', '€45', '5.1 km', false),
    ];
    final task = tasks[index];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(task.$2, style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              if (task.$5) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('URGENTE', style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
              const Spacer(),
              Text(task.$4, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Text(task.$1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Text(task.$3, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Invia offerta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
