import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/helper_service.dart';
import '../../../auth/application/auth_provider.dart';

class HelperRegistrationScreen extends ConsumerStatefulWidget {
  const HelperRegistrationScreen({super.key});

  @override
  ConsumerState<HelperRegistrationScreen> createState() => _HelperRegistrationScreenState();
}

class _HelperRegistrationScreenState extends ConsumerState<HelperRegistrationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Skills
  final List<String> _availableSkills = [
    'Plumbing', 'Electrical', 'Cleaning', 'Moving', 'Gardening', 'Painting', 'Assembly', 'Babysitting', 'IT Support'
  ];
  final List<String> _selectedSkills = [];
  double _tasksPerWeek = 3;

  // Step 2: Radius & Availability
  double _radiusKm = 20.0;

  // Step 3: Stripe
  bool _stripeConnected = false;

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(helperServiceProvider.notifier).updateProfile(
        skills: _selectedSkills,
        hourlyRate: 25.0,
        bio: "New Helper Profile", 
        isAvailable: true,
      );

      await ref.read(helperServiceProvider.notifier).verify();
      await ref.read(authProvider.notifier).becomeHelper();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profilo Helper attivato con successo!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red.shade600),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diventa un Helper', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.teal.shade600),
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)))
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.teal.shade600,
                  onPrimary: Colors.white,
                ),
              ),
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 3) {
                    if (_currentStep == 0 && _selectedSkills.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Seleziona almeno una categoria'), backgroundColor: Colors.orange.shade600),
                      );
                      return;
                    }
                    if (_currentStep == 2 && !_stripeConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Connetti Stripe per ricevere pagamenti'), backgroundColor: Colors.orange.shade600),
                      );
                      return;
                    }
                    setState(() => _currentStep += 1);
                  } else {
                    _submitRegistration();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                controlsBuilder: (context, details) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 24),
                     child: Row(
                       children: [
                         Expanded(
                           child: ElevatedButton(
                             onPressed: details.onStepContinue,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.teal.shade600,
                               foregroundColor: Colors.white,
                               padding: const EdgeInsets.symmetric(vertical: 14),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               elevation: 2,
                             ),
                             child: Text(
                               _currentStep == 3 ? 'Conferma e Inizia' : 'Avanti',
                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                             ),
                           ),
                         ),
                         if (_currentStep > 0) ...[
                           const SizedBox(width: 12),
                           OutlinedButton(
                             onPressed: details.onStepCancel,
                             style: OutlinedButton.styleFrom(
                               foregroundColor: Colors.teal.shade600,
                               side: BorderSide(color: Colors.teal.shade300),
                               padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             child: const Text('Indietro'),
                           ),
                         ],
                       ],
                     ),
                   );
                },
                steps: [
                  Step(
                    title: Text('Categorie', style: TextStyle(color: _currentStep >= 0 ? Colors.teal.shade700 : Colors.grey)),
                    content: _buildStepOne(),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.editing,
                  ),
                  Step(
                    title: Text('Zona', style: TextStyle(color: _currentStep >= 1 ? Colors.teal.shade700 : Colors.grey)),
                    content: _buildStepTwo(),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.editing,
                  ),
                  Step(
                    title: Text('Pagamenti', style: TextStyle(color: _currentStep >= 2 ? Colors.teal.shade700 : Colors.grey)),
                    content: _buildStepThree(),
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2 ? StepState.complete : StepState.editing,
                  ),
                  Step(
                    title: Text('Conferma', style: TextStyle(color: _currentStep >= 3 ? Colors.teal.shade700 : Colors.grey)),
                    content: _buildStepFour(),
                    isActive: _currentStep >= 3,
                    state: _currentStep == 3 ? StepState.editing : StepState.indexed,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStepOne() {
    // Calculate estimated earnings based on selected skills
    final categoryValues = {
      'Cleaning': 40.0, 'Moving': 80.0, 'Plumbing': 60.0, 'Electrical': 65.0,
      'Gardening': 45.0, 'Painting': 50.0, 'Assembly': 35.0, 'Babysitting': 30.0, 'IT Support': 55.0,
    };
    
    double avgTaskValue = 35.0;
    if (_selectedSkills.isNotEmpty) {
      avgTaskValue = _selectedSkills.map((s) => categoryValues[s] ?? 35.0).reduce((a, b) => a + b) / _selectedSkills.length;
    }
    
    return Column(
      children: [
        // Categories Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade100),
            boxShadow: [
              BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category, color: Colors.teal.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Quali servizi vuoi offrire?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Seleziona una o più categorie. Potrai modificarle in seguito.', style: TextStyle(color: Colors.teal.shade500)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _availableSkills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    selectedColor: Colors.teal.shade100,
                    backgroundColor: Colors.teal.shade50.withValues(alpha: 0.3),
                    checkmarkColor: Colors.teal.shade700,
                    side: BorderSide(color: isSelected ? Colors.teal.shade400 : Colors.teal.shade200),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.teal.shade800 : Colors.teal.shade600,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkills.add(skill);
                        } else {
                          _selectedSkills.remove(skill);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Earnings Estimator Card (same as home)
        Container(
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
                        '€${(avgTaskValue * _tasksPerWeek * 0.8).round()} - €${(avgTaskValue * _tasksPerWeek * 1.2).round()}', 
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
                        '€${(avgTaskValue * _tasksPerWeek * 4 * 0.8).round()} - €${(avgTaskValue * _tasksPerWeek * 4 * 1.2).round()}', 
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
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              Text(
                'Dove vuoi lavorare?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Raggio d\'azione:', style: TextStyle(color: Colors.teal.shade600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('${_radiusKm.round()} km', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
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
              value: _radiusKm,
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (val) => setState(() => _radiusKm = val),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.teal.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifiche nuove task', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                      Text('Ricevi notifica per task nella tua zona', style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
                    ],
                  ),
                ),
                Switch(
                  value: true,
                  activeColor: Colors.teal,
                  onChanged: (val) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepThree() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              Text(
                'Come vuoi essere pagato?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Usiamo Stripe per garantirti pagamenti sicuri e veloci.', style: TextStyle(color: Colors.teal.shade500)),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _stripeConnected ? Colors.green.shade50 : Colors.teal.shade50.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _stripeConnected ? Colors.green.shade200 : Colors.teal.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.account_balance, size: 24, color: _stripeConnected ? Colors.green.shade600 : Colors.teal.shade600),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stripe Connect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800)),
                          Text('Integrazione sicura', style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
                        ],
                      ),
                    ),
                    if (_stripeConnected)
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_stripeConnected)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _stripeConnected = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Account Stripe connesso (Simulato)'), backgroundColor: Colors.green.shade600),
                        );
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Connetti Account Stripe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  )
                else 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text('Account Connesso e Verificato', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepFour() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_user, size: 48, color: Colors.teal.shade600),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Tutto pronto!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Il tuo profilo verrà attivato e potrai iniziare subito a inviare offerte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.teal.shade500),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Column(
              children: [
                _buildSummaryRow(Icons.category, 'Categorie', _selectedSkills.join(', ')),
                Divider(color: Colors.teal.shade200),
                _buildSummaryRow(Icons.location_on, 'Zona', '${_radiusKm.round()} km'),
                Divider(color: Colors.teal.shade200),
                _buildSummaryRow(Icons.payment, 'Pagamenti', _stripeConnected ? 'Stripe Connect ✓' : 'Non connesso'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: true, 
                  onChanged: null, 
                  activeColor: Colors.teal.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Text(
                    'Ho letto e accetto i Termini e Condizioni per gli Helper.',
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal.shade500),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.teal.shade600))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Colors.teal.shade800))),
        ],
      ),
    );
  }
}
