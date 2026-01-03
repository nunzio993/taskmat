import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/application/auth_provider.dart';
import '../../../application/tasks_provider.dart';

/// Sezione "Guadagna come Helper" per conversione utenti
class BecomeHelperSection extends ConsumerStatefulWidget {
  const BecomeHelperSection({super.key});

  @override
  ConsumerState<BecomeHelperSection> createState() => _BecomeHelperSectionState();
}

class _BecomeHelperSectionState extends ConsumerState<BecomeHelperSection> {
  // Simulator state
  double _tasksPerWeek = 3;
  String _selectedCategory = 'Tutte';

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                        'Guadagna aiutando vicino a te',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      Text(
                        'Attiva il profilo helper in pochi minuti',
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
          
          // Come funziona - 4 step
          _buildHowItWorks(context),
          
          const SizedBox(height: 24),

          // Earnings Estimator
          _buildEarningsEstimator(context),
          
          const SizedBox(height: 24),
          
          // Market Preview (sanificato)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MarketPreviewWidget(),
          ),
          
          const SizedBox(height: 24),

          // Readiness Checklist
           _buildReadinessChecklist(context, isAlreadyHelper),

          const SizedBox(height: 24),

          // Trust Bullets
          _buildTrustBullets(context),

          const SizedBox(height: 24),
          
          // Primary CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                elevation: 4,
              ),
              child: Text(
                isAlreadyHelper ? 'Vai alla Home Helper' : 'Attiva profilo helper',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (!isAlreadyHelper)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Mantieni anche la modalità cliente',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildStep(context, 1, 'Imposta categorie', Icons.tune)),
          _buildArrow(),
          Expanded(child: _buildStep(context, 2, 'Cerca task vicine', Icons.map)),
          _buildArrow(),
          Expanded(child: _buildStep(context, 3, 'Invia offerta', Icons.send)),
          _buildArrow(),
          Expanded(child: _buildStep(context, 4, 'Guadagna', Icons.savings)),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int number, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.teal.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: Icon(icon, color: Colors.teal.shade600, size: 20)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.teal.shade800,
            fontWeight: FontWeight.w600,
            height: 1.2
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Icon(Icons.arrow_right_alt, color: Colors.teal.shade200, size: 20),
    );
  }

  Widget _buildEarningsEstimator(BuildContext context) {
    // Category-based avg task values
    final categoryValues = {
      'Tutte': 35.0,
      'Pulizie': 40.0,
      'Traslochi': 80.0,
      'Giardinaggio': 45.0,
      'Montaggio': 35.0,
      'Idraulica': 60.0,
    };
    
    final weeklyTasks = _tasksPerWeek;
    final avgTaskValue = categoryValues[_selectedCategory] ?? 35.0;
    final weeklyMin = (weeklyTasks * avgTaskValue * 0.8).round();
    final weeklyMax = (weeklyTasks * avgTaskValue * 1.2).round();
    final monthlyMin = weeklyMin * 4;
    final monthlyMax = weeklyMax * 4;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate, color: Colors.teal.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text('Stimatore Guadagni', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal.shade800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text('BETA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade600))
              )
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Text('Task / settimana:', style: TextStyle(fontSize: 13, color: Colors.teal.shade600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('${_tasksPerWeek.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade700)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.teal.shade400,
              thumbColor: Colors.teal.shade600,
              inactiveTrackColor: Colors.teal.shade100,
            ),
            child: Slider(
              value: _tasksPerWeek,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) => setState(() => _tasksPerWeek = val),
            ),
          ),
          Divider(color: Colors.teal.shade100),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('Settimanale', style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
                  const SizedBox(height: 4),
                  Text(
                    '€$weeklyMin - €$weeklyMax', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade700)
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: Colors.teal.shade200),
              Column(
                children: [
                  Text('Mensile', style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
                  const SizedBox(height: 4),
                  Text(
                    '€$monthlyMin - €$monthlyMax', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade700)
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '* Stima basata su dati aggregati della tua zona',
            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.teal.shade400),
          )
        ],
      ),
    );
  }

  Widget _buildReadinessChecklist(BuildContext context, bool isVerified) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: Colors.teal.shade600, size: 20),
              const SizedBox(width: 8),
              Text('Requisiti per iniziare:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal.shade800)),
            ],
          ),
          const SizedBox(height: 12),
          _buildCheckItem('Contatto verificato', true),
          _buildCheckItem('Categorie impostate', isVerified),
          _buildCheckItem('Account Stripe connesso', false),
          _buildCheckItem('Termini accettati', false),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool checked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: checked ? Colors.green.shade50 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              checked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: checked ? Colors.green.shade600 : Colors.grey.shade400,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              decoration: checked ? TextDecoration.lineThrough : null,
              color: checked ? Colors.grey.shade500 : Colors.teal.shade700,
              fontSize: 13,
              fontWeight: checked ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (!checked)
            Icon(Icons.chevron_right, color: Colors.teal.shade300, size: 18),
        ],
      ),
    );
  }

  Widget _buildTrustBullets(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustItem(Icons.shield_outlined, 'Pagamenti\nProtetti'),
          _buildTrustItem(Icons.star_outline, 'Sistema\nRecensioni'),
          _buildTrustItem(Icons.support_agent, 'Supporto\nDedicato'),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal.shade700, size: 24),
        const SizedBox(height: 6),
        Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.teal.shade800, height: 1.2)),
      ],
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
          // Fallback if low volume
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Column(
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
                ),
                // Overlay CTA if needed, but we have external CTA. 
                // Let's make it interactive (clicking prompts to register)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                         // Prompt registration
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Diventa Helper per vedere i dettagli!')),
                         );
                      },
                      child: Container(),
                    ),
                  ),
                )
              ],
            ),
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
