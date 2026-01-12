import 'package:flutter/material.dart';

/// Dashboard home page with overview widgets
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bentornato! 👋',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ecco un riepilogo delle tue attività',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Nuovo Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Task Attivi', '3', Icons.assignment, Colors.blue)),
              const SizedBox(width: 24),
              Expanded(child: _buildStatCard('In Attesa', '2', Icons.hourglass_empty, Colors.orange)),
              const SizedBox(width: 24),
              Expanded(child: _buildStatCard('Completati', '12', Icons.check_circle, Colors.green)),
              const SizedBox(width: 24),
              Expanded(child: _buildStatCard('Messaggi', '5', Icons.chat_bubble, Colors.purple)),
            ],
          ),
          const SizedBox(height: 32),

          // Two column layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent tasks
              Expanded(
                flex: 3,
                child: _buildRecentTasksCard(),
              ),
              const SizedBox(width: 24),
              // Activity feed
              Expanded(
                flex: 2,
                child: _buildActivityFeed(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasksCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Text('Task Recenti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Vedi tutti')),
            ],
          ),
          const SizedBox(height: 16),
          _buildTaskRow('Pulizia appartamento', 'posted', '€50', 'Oggi'),
          const Divider(),
          _buildTaskRow('Montaggio armadio IKEA', 'assigned', '€35', 'Ieri'),
          const Divider(),
          _buildTaskRow('Piccolo trasloco', 'in_progress', '€120', '2 giorni fa'),
          const Divider(),
          _buildTaskRow('Riparazione rubinetto', 'completed', '€40', '3 giorni fa'),
        ],
      ),
    );
  }

  Widget _buildTaskRow(String title, String status, String price, String date) {
    final statusConfig = _getStatusConfig(status);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusConfig.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(statusConfig.label, style: TextStyle(fontSize: 11, color: statusConfig.color, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    Text(date, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 16)),
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

  Widget _buildActivityFeed() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attività Recente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 16),
          _buildActivityItem(Icons.person, 'Mario R. ha inviato un\'offerta', '5 min fa', Colors.blue),
          _buildActivityItem(Icons.check, 'Task "Pulizia" completato', '2 ore fa', Colors.green),
          _buildActivityItem(Icons.chat, 'Nuovo messaggio da Laura', '3 ore fa', Colors.purple),
          _buildActivityItem(Icons.star, 'Hai ricevuto una recensione', 'Ieri', Colors.amber),
          _buildActivityItem(Icons.payments, 'Pagamento ricevuto: €50', 'Ieri', Colors.teal),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String text, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 14)),
                Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
