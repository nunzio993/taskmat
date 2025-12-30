import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_provider.dart';

class HelperRegistrationScreen extends ConsumerStatefulWidget {
  const HelperRegistrationScreen({super.key});

  @override
  ConsumerState<HelperRegistrationScreen> createState() => _HelperRegistrationScreenState();
}

class _HelperRegistrationScreenState extends ConsumerState<HelperRegistrationScreen> {
  int _currentStep = 0;
  
  // Controllers
  final _bioCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController(); // Comma separated for now
  final _zoneCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  List<Step> get _steps => [
    Step(
      title: const Text('Profile'),
      content: Column(
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.camera_alt)),
          const SizedBox(height: 8),
          const Text('Upload Profile Photo'),
          const SizedBox(height: 16),
          TextField(
            controller: _bioCtrl,
            decoration: const InputDecoration(labelText: 'Short Bio', border: OutlineInputBorder()),
            maxLines: 3,
          ),
        ],
      ),
      isActive: _currentStep >= 0,
    ),
    Step(
      title: const Text('Skills & Rates'),
      content: Column(
        children: [
          TextField(
            controller: _skillsCtrl,
            decoration: const InputDecoration(labelText: 'Key Skills (e.g. Plumbing, IT)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rateCtrl,
            decoration: const InputDecoration(labelText: 'Hourly Rate (€)', border: OutlineInputBorder(), prefixText: '€ '),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      isActive: _currentStep >= 1,
    ),
    Step(
      title: const Text('Zone'),
      content: Column(
        children: [
          TextField(
            controller: _zoneCtrl,
            decoration: const InputDecoration(labelText: 'Operating City / Zone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map)),
          ),
           const SizedBox(height: 8),
           const Text('You will be matched with tasks in this area.', style: TextStyle(color: Colors.grey)),
        ],
      ),
      isActive: _currentStep >= 2,
    ),
    Step(
      title: const Text('Verification'),
      content: Column(
        children: [
           ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Upload ID Document'),
            trailing: const Icon(Icons.upload_file),
            onTap: () {}, // Pending implementation
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
           ),
           const SizedBox(height: 16),
           SwitchListTile(
             title: const Text('I agree to the Provider Terms'),
             value: true, 
             onChanged: (v) {},
           ),
        ],
      ),
      isActive: _currentStep >= 3,
    ),
  ];

  Future<void> _handleComplete() async {
    // Generate a dummy password or ask for it? For MVP assuming flow requires email/pass previously or here.
    // Ideally Helper Registration should also ask for Email/Password earlier.
    // For now we hardcode or ask user. Let's assume we use a hardcoded helper test email for this specific flow 
    // OR better, we should have asked for email/pass in step 1.
    // Let's use a placeholder implementation that assumes email/pass are collected or we use auto-generated.
    const tempPass = "password"; 
    final email = "helper_${DateTime.now().millisecondsSinceEpoch}@example.com"; // Unique email for testing
    
    await ref.read(authProvider.notifier).register(
       email,
       tempPass,
       'helper',
       _bioCtrl.text.isNotEmpty ? "New Helper" : "New Helper", // Ideally name is collected
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
       if (next is AsyncError) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(next.error.toString()),
             backgroundColor: Theme.of(context).colorScheme.error,
           ),
         );
       }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Become a Helper')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < _steps.length - 1) {
            setState(() => _currentStep++);
          } else {
            _handleComplete();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            context.pop();
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == _steps.length - 1 ? 'Submit Application' : 'Next'),
                  ),
                ),
                const SizedBox(width: 16),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: _steps,
      ),
    );
  }
}
