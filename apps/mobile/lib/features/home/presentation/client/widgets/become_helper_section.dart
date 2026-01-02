import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/application/auth_provider.dart';
import '../../../application/tasks_provider.dart';

/// Sezione "Guadagna come Helper" per conversione utenti
class BecomeHelperSection extends ConsumerWidget {
  const BecomeHelperSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull;
    final isAlreadyHelper = session?.role == 'helper';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.teal.shade100.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.monetization_on, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guadagna come Helper!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      Text(
                        'Aiuta gli altri e guadagna',
                        style: TextStyle(
                          color: Colors.teal.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Come funziona - 3 step
          _buildHowItWorks(context),
          
          const SizedBox(height: 16),
          
          // Market Preview (sanificato)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MarketPreviewWidget(),
          ),
          
          const SizedBox(height: 20),
          
          // CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: ElevatedButton(
              onPressed: () {
                if (isAlreadyHelper) {
                  // Porta a Home Helper
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sei già un Helper! Usa il toggle per vedere la Home Helper.')),
                  );
                } else {
                  context.push('/register-helper');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isAlreadyHelper ? 'Vai alla Home Helper' : 'Attiva Profilo Helper',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStep(context, 1, 'Cerca le task', Icons.search)),
          _buildArrow(),
          Expanded(child: _buildStep(context, 2, 'Offri il tuo aiuto', Icons.handshake)),
          _buildArrow(),
          Expanded(child: _buildStep(context, 3, 'Completa e guadagna', Icons.paid)),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int number, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.teal.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(child: Icon(icon, color: Colors.teal.shade600, size: 22)),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.teal.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Icon(Icons.arrow_forward, color: Colors.teal.shade300, size: 18),
    );
  }
}

/// Market Preview Widget - mostra task sanificate (NO descrizione, NO indirizzo)
class MarketPreviewWidget extends ConsumerWidget {
  const MarketPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(sanitizedMarketPreviewProvider);
    
    return tasksAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Nuove opportunità disponibili ogni giorno!',
              style: TextStyle(color: Colors.teal.shade700),
              textAlign: TextAlign.center,
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task disponibili ora:',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ...tasks.take(3).map((task) => _buildSanitizedTaskRow(context, task)),
          ],
        );
      },
    );
  }

  Widget _buildSanitizedTaskRow(BuildContext context, SanitizedTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icona categoria
          Icon(_getCategoryIcon(task.category), color: Colors.teal, size: 20),
          const SizedBox(width: 10),
          
          // Categoria
          Expanded(
            child: Text(
              task.category,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          
          // Prezzo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '€${(task.priceCents / 100).toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Distanza
          Text(
            task.distanceBand,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Tempo
          Text(
            task.postedAge,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pulizie':
        return Icons.cleaning_services;
      case 'traslochi':
        return Icons.local_shipping;
      case 'giardinaggio':
        return Icons.grass;
      case 'montaggio mobili':
        return Icons.handyman;
      case 'idraulica':
        return Icons.plumbing;
      case 'elettricità':
        return Icons.electrical_services;
      case 'imbiancatura':
        return Icons.format_paint;
      case 'baby-sitting':
        return Icons.child_care;
      default:
        return Icons.work;
    }
  }
}
