import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'client';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // TODO: Implement actual signup
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side - Branding
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.teal.shade700, Colors.teal.shade500],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    InkWell(
                      onTap: () => context.go('/'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.handshake, size: 28, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Text('TaskMat', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Inizia ora',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Crea un account per pubblicare task\no iniziare a lavorare come helper.',
                      style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9), height: 1.6),
                    ),
                    const Spacer(),
                    // Features
                    _buildFeatureRow(Icons.flash_on, 'Registrazione in 30 secondi'),
                    const SizedBox(height: 16),
                    _buildFeatureRow(Icons.money_off, 'Nessun abbonamento'),
                    const SizedBox(height: 16),
                    _buildFeatureRow(Icons.shield, 'Dati protetti'),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
          
          // Right side - Signup form
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(64),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Crea account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Inserisci i tuoi dati per iniziare', style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 32),
                          
                          // Role selector
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _buildRoleButton('client', 'Cerco aiuto', Icons.search)),
                                Expanded(child: _buildRoleButton('helper', 'Offro servizi', Icons.handyman)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: const Icon(Icons.person_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Nome richiesto' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Email richiesta' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              helperText: 'Min. 8 caratteri, 1 lettera, 1 numero',
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password richiesta';
                              if (v.length < 8) return 'Minimo 8 caratteri';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Signup button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Registrati', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Terms
                          Text(
                            'Registrandoti accetti i Termini di Servizio e la Privacy Policy.',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Hai già un account?', style: TextStyle(color: Colors.grey.shade600)),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                child: Text('Accedi', style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.teal.shade600 : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.teal.shade700 : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15)),
      ],
    );
  }
}
