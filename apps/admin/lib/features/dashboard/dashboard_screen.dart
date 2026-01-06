import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';

// Provider for dashboard stats
final statsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/stats');
  return DashboardStats.fromJson(response.data);
});

class DashboardStats {
  final int totalUsers;
  final int totalHelpers;
  final int completedTasks;
  final int pendingTasks;
  final int totalRevenueCents;
  final int activeCategories;
  
  DashboardStats({
    required this.totalUsers,
    required this.totalHelpers,
    required this.completedTasks,
    required this.pendingTasks,
    required this.totalRevenueCents,
    required this.activeCategories,
  });
  
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['total_users'] ?? 0,
      totalHelpers: json['total_helpers'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      pendingTasks: json['pending_tasks'] ?? 0,
      totalRevenueCents: json['total_revenue_cents'] ?? 0,
      activeCategories: json['active_categories'] ?? 0,
    );
  }
  
  String get formattedRevenue {
    final euros = totalRevenueCents / 100;
    return '€${euros.toStringAsFixed(2)}';
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Panoramica del sistema',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(statsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Aggiorna'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Stats Cards
          statsAsync.when(
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    _buildStatCard(
                      icon: Icons.people,
                      label: 'Utenti Totali',
                      value: stats.totalUsers.toString(),
                      subtitle: '${stats.totalHelpers} helper',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      icon: Icons.task_alt,
                      label: 'Task Completate',
                      value: stats.completedTasks.toString(),
                      subtitle: '${stats.pendingTasks} in attesa',
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      icon: Icons.euro,
                      label: 'Revenue Totale',
                      value: stats.formattedRevenue,
                      subtitle: 'Fee piattaforma',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      icon: Icons.category,
                      label: 'Categorie Attive',
                      value: stats.activeCategories.toString(),
                      subtitle: 'su 7 totali',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
            loading: () => Row(
              children: List.generate(4, (_) => Expanded(
                child: Container(
                  height: 120,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )),
            ),
            error: (e, _) => Text('Errore: $e'),
          ),
          const SizedBox(height: 32),
          
          // Quick Actions
          Text(
            'Azioni Rapide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionCard(
                context,
                icon: Icons.category,
                title: 'Gestisci Categorie',
                subtitle: 'Fee e impostazioni per categoria',
                onTap: () => context.go('/categories'),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                context,
                icon: Icons.settings,
                title: 'Impostazioni Globali',
                subtitle: 'Timeout, limiti e configurazioni',
                onTap: () => context.go('/settings'),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                context,
                icon: Icons.history,
                title: 'Storico Modifiche',
                subtitle: 'Audit trail delle policy',
                onTap: () => context.go('/history'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required MaterialColor color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color.shade600, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.teal.shade600, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
