import 'package:flutter/material.dart';

/// My Jobs page for helpers showing their assigned tasks
class MyJobsPage extends StatelessWidget {
  const MyJobsPage({super.key});

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
              _buildFilterTab('Tutti', true),
              _buildFilterTab('Assegnati', false),
              _buildFilterTab('In corso', false),
              _buildFilterTab('Da confermare', false),
              _buildFilterTab('Completati', false),
              const Spacer(),
              Text('6 lavori totali', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 24),

          // Jobs list
          Expanded(
            child: ListView(
              children: [
                _buildJobCard(
                  'Pulizia appartamento 80mq',
                  'Mario Rossi',
                  'in_progress',
                  '€50',
                  'Oggi, 14:00',
                  'Via Roma 123, Milano',
                ),
                _buildJobCard(
                  'Montaggio armadio PAX',
                  'Laura Bianchi',
                  'assigned',
                  '€35',
                  'Domani, 10:00',
                  'Via Verdi 45, Milano',
                ),
                _buildJobCard(
                  'Piccolo trasloco',
                  'Giuseppe Verdi',
                  'in_confirmation',
                  '€120',
                  'Ieri',
                  'Via Dante 67, Milano',
                ),
                _buildJobCard(
                  'Riparazione rubinetto',
                  'Anna Neri',
                  'completed',
                  '€40',
                  '3 giorni fa',
                  'Via Manzoni 12, Milano',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildJobCard(String title, String clientName, String status, String price, String date, String address) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: statusConfig.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 20),
          
          // Job info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusConfig.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(statusConfig.label, style: TextStyle(color: statusConfig.color, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(clientName, style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(address, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          
          // Price and actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Chat'),
                  ),
                  const SizedBox(width: 8),
                  if (status == 'in_progress')
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white),
                      child: const Text('Completa'),
                    ),
                  if (status == 'in_confirmation')
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600, foregroundColor: Colors.white),
                      child: const Text('In attesa'),
                    ),
                  if (status == 'assigned')
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white),
                      child: const Text('Inizia'),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _getStatusConfig(String status) {
    switch (status) {
      case 'assigned': return (label: 'Assegnato', color: Colors.orange);
      case 'in_progress': return (label: 'In corso', color: Colors.teal);
      case 'in_confirmation': return (label: 'Da confermare', color: Colors.purple);
      case 'completed': return (label: 'Completato', color: Colors.green);
      default: return (label: status, color: Colors.grey);
    }
  }
}
