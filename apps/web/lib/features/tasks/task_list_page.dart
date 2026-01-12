import 'package:flutter/material.dart';

/// Task list page showing all user's tasks
class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters
          Row(
            children: [
              // Filter tabs
              _buildFilterTab('Tutti', true),
              _buildFilterTab('Pubblicati', false),
              _buildFilterTab('In corso', false),
              _buildFilterTab('Completati', false),
              const Spacer(),
              // Search
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cerca task...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Nuovo Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Task table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('Task', style: _headerStyle)),
                        Expanded(flex: 2, child: Text('Categoria', style: _headerStyle)),
                        Expanded(flex: 2, child: Text('Stato', style: _headerStyle)),
                        Expanded(flex: 1, child: Text('Prezzo', style: _headerStyle)),
                        Expanded(flex: 2, child: Text('Data', style: _headerStyle)),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Table rows
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTaskRow('Pulizia appartamento 80mq', 'Pulizie', 'posted', '€50', '12 Gen 2026'),
                        _buildTaskRow('Montaggio armadio PAX IKEA', 'Montaggio', 'assigned', '€35', '11 Gen 2026'),
                        _buildTaskRow('Piccolo trasloco (3° piano)', 'Traslochi', 'in_progress', '€120', '10 Gen 2026'),
                        _buildTaskRow('Riparazione rubinetto cucina', 'Riparazioni', 'completed', '€40', '9 Gen 2026'),
                        _buildTaskRow('Tinteggiatura camera', 'Imbiancatura', 'completed', '€180', '5 Gen 2026'),
                        _buildTaskRow('Montaggio scaffali', 'Montaggio', 'completed', '€25', '3 Gen 2026'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade600,
  );

  Widget _buildFilterTab(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? Colors.teal.shade600 : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskRow(String title, String category, String status, String price, String date) {
    final statusConfig = _getStatusConfig(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Task title
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusConfig.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Text(category, style: TextStyle(color: Colors.grey.shade600)),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusConfig.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusConfig.label,
                style: TextStyle(color: statusConfig.color, fontWeight: FontWeight.w600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Price
          Expanded(
            flex: 1,
            child: Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(date, style: TextStyle(color: Colors.grey.shade600)),
          ),
          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.visibility_outlined, color: Colors.grey.shade500, size: 20),
                  tooltip: 'Visualizza',
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 20),
                  tooltip: 'Altre azioni',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _getStatusConfig(String status) {
    switch (status) {
      case 'posted': return (label: 'Pubblicato', color: Colors.blue);
      case 'assigned': return (label: 'Assegnato', color: Colors.orange);
      case 'in_progress': return (label: 'In corso', color: Colors.teal);
      case 'completed': return (label: 'Completato', color: Colors.green);
      default: return (label: status, color: Colors.grey);
    }
  }
}
