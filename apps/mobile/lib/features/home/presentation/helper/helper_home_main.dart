import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/task.dart';
import '../../application/tasks_provider.dart';

/// Helper Dashboard - Main home view for helpers
/// Shows operational overview without duplicating Find Work
class HelperHomeMain extends ConsumerWidget {
  const HelperHomeMain({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: Colors.teal.shade600,
      onRefresh: () async {
        ref.invalidate(myAssignedTasksProvider);
        ref.invalidate(helperEarningsProvider);
        ref.invalidate(helperRecentThreadsProvider);
        ref.invalidate(nearbyTasksProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusHeaderSection(),
            const SizedBox(height: 20),
            _KPIsSection(),
            const SizedBox(height: 24),
            _ActiveJobsSection(),
            const SizedBox(height: 24),
            _InboxPreviewSection(),
            const SizedBox(height: 24),
            _OpportunitiesPreviewSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ============================================
// STATUS HEADER SECTION
// ============================================

class _StatusHeaderSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(helperAvailabilityProvider);
    final alertsAsync = ref.watch(helperAlertsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAvailable 
                ? [Colors.teal.shade50, Colors.teal.shade100.withValues(alpha: 0.5)]
                : [Colors.grey.shade100, Colors.grey.shade200.withValues(alpha: 0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAvailable ? Colors.teal.shade200 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.teal.shade600 : Colors.grey.shade500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAvailable ? Icons.check_circle : Icons.pause_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAvailable ? 'Sei disponibile' : 'In pausa',
                      style: TextStyle(
                        color: isAvailable ? Colors.teal.shade800 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isAvailable 
                        ? 'I clienti possono vedere le tue offerte'
                        : 'Non riceverai nuove richieste',
                      style: TextStyle(
                        color: isAvailable ? Colors.teal.shade600 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAvailable,
                activeTrackColor: Colors.teal.shade600,
                onChanged: (_) => ref.read(helperAvailabilityProvider.notifier).toggle(),
              ),
            ],
          ),
        ),
        alertsAsync.when(
          data: (alerts) {
            if (alerts.isEmpty) return const SizedBox.shrink();
            return Column(
              children: alerts.map((alert) => Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(alert, style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: () => context.push('/preferences'),
                      child: Text('Risolvi', style: TextStyle(color: Colors.orange.shade700)),
                    ),
                  ],
                ),
              )).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ============================================
// KPIs SECTION
// ============================================

class _KPIsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(helperEarningsProvider);
    
    return earningsAsync.when(
      data: (earnings) => Row(
        children: [
          Expanded(child: _buildKpiCard(
            icon: Icons.today,
            label: 'Oggi',
            value: '€${(earnings.todayCents / 100).toStringAsFixed(0)}',
            color: Colors.teal,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(
            icon: Icons.date_range,
            label: 'Settimana',
            value: '€${(earnings.weekCents / 100).toStringAsFixed(0)}',
            color: Colors.teal,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(
            icon: Icons.account_balance_wallet,
            label: 'In Attesa',
            value: '€${(earnings.pendingPayoutCents / 100).toStringAsFixed(0)}',
            color: Colors.orange,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(
            icon: Icons.star,
            label: '${earnings.reviewCount} rec.',
            value: earnings.rating.toStringAsFixed(1),
            color: Colors.amber,
          )),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Errore caricamento KPI'),
    );
  }
  
  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color.shade600, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(color: color.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}

// ============================================
// ACTIVE JOBS SECTION
// ============================================

class _ActiveJobsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myAssignedTasksProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work, color: Colors.teal.shade600, size: 22),
            const SizedBox(width: 8),
            Text('Incarichi Attivi', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 17)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/my-jobs'), child: Text('Vedi tutti', style: TextStyle(color: Colors.teal.shade600))),
          ],
        ),
        const SizedBox(height: 12),
        jobsAsync.when(
          data: (jobs) {
            final activeJobs = jobs.where((t) => 
              ['assigned', 'in_progress', 'in_confirmation'].contains(t.status.toLowerCase())
            ).toList();
            
            activeJobs.sort((a, b) {
              const priority = {'in_confirmation': 0, 'in_progress': 1, 'assigned': 2};
              return (priority[a.status.toLowerCase()] ?? 3).compareTo(priority[b.status.toLowerCase()] ?? 3);
            });
            
            if (activeJobs.isEmpty) return _buildEmptyState(context);
            return Column(children: activeJobs.take(5).map((job) => _buildJobCard(context, job)).toList());
          },
          loading: () => Center(child: Padding(padding: const EdgeInsets.all(32), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)))),
          error: (e, _) => Text('Errore: $e'),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.teal.shade100.withValues(alpha: 0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.2), blurRadius: 8)]),
            child: Icon(Icons.search, size: 32, color: Colors.teal.shade400),
          ),
          const SizedBox(height: 14),
          Text('Nessun incarico attivo', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Cerca nuove opportunità di lavoro', style: TextStyle(color: Colors.teal.shade500, fontSize: 13)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => context.go('/find-work'),
            icon: const Icon(Icons.search),
            label: const Text('Trova lavoro'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
  
  Widget _buildJobCard(BuildContext context, Task job) {
    final statusInfo = _getStatusInfo(job.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: statusInfo.color.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/my-jobs?selectedJobId=${job.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(width: 4, height: 50, decoration: BoxDecoration(color: statusInfo.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusInfo.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(statusInfo.label, style: TextStyle(color: statusInfo.color, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text('€${(job.priceCents / 100).toStringAsFixed(0)}', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(job.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.open_in_new, color: Colors.teal.shade400, size: 20), onPressed: () => context.go('/my-jobs?selectedJobId=${job.id}'), tooltip: 'Apri job'),
                    IconButton(icon: Icon(Icons.chat_bubble_outline, color: Colors.teal.shade400, size: 20), onPressed: () => context.go('/my-jobs?selectedJobId=${job.id}&openChat=true'), tooltip: 'Chat'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  ({String label, Color color}) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'in_confirmation': return (label: 'DA CONFERMARE', color: Colors.purple.shade600);
      case 'in_progress': return (label: 'IN LAVORO', color: Colors.teal.shade600);
      case 'assigned': return (label: 'ASSEGNATO', color: Colors.orange.shade600);
      default: return (label: status.toUpperCase(), color: Colors.grey);
    }
  }
}

// ============================================
// INBOX PREVIEW SECTION
// ============================================

class _InboxPreviewSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(helperRecentThreadsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inbox, color: Colors.teal.shade600, size: 22),
            const SizedBox(width: 8),
            Text('Messaggi', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 17)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/my-jobs'), child: Text('Vedi tutti', style: TextStyle(color: Colors.teal.shade600))),
          ],
        ),
        const SizedBox(height: 12),
        threadsAsync.when(
          data: (threads) {
            if (threads.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_outlined, color: Colors.grey.shade400), const SizedBox(width: 10), Text('Nessun messaggio', style: TextStyle(color: Colors.grey.shade500))]),
              );
            }
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.shade100)),
              child: Column(children: threads.take(5).map((thread) => _buildThreadItem(context, thread)).toList()),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Errore caricamento messaggi'),
        ),
      ],
    );
  }
  
  Widget _buildThreadItem(BuildContext context, RecentThread thread) {
    final diff = DateTime.now().difference(thread.lastMessageAt);
    final timeAgo = diff.inMinutes < 60 ? '${diff.inMinutes}m' : (diff.inHours < 24 ? '${diff.inHours}h' : '${diff.inDays}g');
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/my-jobs?selectedJobId=${thread.taskId}&openChat=true'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.teal.shade50))),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal.shade100,
                backgroundImage: thread.otherUserAvatar != null ? NetworkImage(thread.otherUserAvatar!) : null,
                child: thread.otherUserAvatar == null ? Text(thread.otherUserName.isNotEmpty ? thread.otherUserName[0] : '?', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: Text(thread.otherUserName, style: TextStyle(fontWeight: thread.hasUnread ? FontWeight.bold : FontWeight.w500, color: Colors.grey.shade800, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)), Text(timeAgo, style: TextStyle(color: Colors.grey.shade500, fontSize: 11))]),
                    const SizedBox(height: 2),
                    Text(thread.lastMessage, style: TextStyle(color: thread.hasUnread ? Colors.grey.shade800 : Colors.grey.shade500, fontSize: 13, fontWeight: thread.hasUnread ? FontWeight.w500 : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (thread.hasUnread) Container(margin: const EdgeInsets.only(left: 8), width: 10, height: 10, decoration: BoxDecoration(color: Colors.teal.shade600, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// OPPORTUNITIES PREVIEW SECTION
// ============================================

class _OpportunitiesPreviewSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(nearbyTasksProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.explore, color: Colors.teal.shade600, size: 22),
            const SizedBox(width: 8),
            Text('Opportunità Vicine', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 17)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/find-work'), child: Text('Vedi tutte', style: TextStyle(color: Colors.teal.shade600))),
          ],
        ),
        const SizedBox(height: 12),
        tasksAsync.when(
          data: (tasks) {
            final postedTasks = tasks.where((t) => t.status == 'posted').take(5).toList();
            if (postedTasks.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, color: Colors.grey.shade400), const SizedBox(width: 10), Text('Nessuna opportunità al momento', style: TextStyle(color: Colors.grey.shade500))]),
              );
            }
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.shade100)),
              child: Column(children: postedTasks.map((task) => _buildTaskItem(context, task)).toList()),
            );
          },
          loading: () => Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)))),
          error: (_, __) => const Text('Errore caricamento opportunità'),
        ),
      ],
    );
  }
  
  Widget _buildTaskItem(BuildContext context, Task task) {
    final diff = DateTime.now().difference(task.createdAt);
    final timeAgo = diff.inMinutes < 60 ? '${diff.inMinutes} min fa' : (diff.inHours < 24 ? '${diff.inHours} ore fa' : '${diff.inDays} giorni fa');
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/find-work?focusTaskId=${task.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.teal.shade50))),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(_getCategoryIcon(task.category), color: Colors.teal.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        if (task.urgency.toLowerCase() == 'urgent')
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text('URGENTE', style: TextStyle(color: Colors.red.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        Text(task.category, style: TextStyle(color: Colors.teal.shade600, fontSize: 12)),
                        Text(' • $timeAgo', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.teal.shade600, borderRadius: BorderRadius.circular(8)),
                child: Text('€${(task.priceCents / 100).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pulizie': return Icons.cleaning_services;
      case 'traslochi': return Icons.local_shipping;
      case 'giardinaggio': return Icons.grass;
      case 'montaggio mobili': return Icons.handyman;
      case 'idraulica': return Icons.plumbing;
      default: return Icons.work;
    }
  }
}
