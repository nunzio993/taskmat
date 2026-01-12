import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // TODO: Implement actual login
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
                      'Bentornato!',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Accedi per gestire i tuoi task e\ncontinuare dove avevi lasciato.',
                      style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9), height: 1.6),
                    ),
                    const Spacer(),
                    // Trust features
                    _buildFeatureRow(Icons.verified_user, 'Helper verificati'),
                    const SizedBox(height: 16),
                    _buildFeatureRow(Icons.security, 'Pagamenti sicuri'),
                    const SizedBox(height: 16),
                    _buildFeatureRow(Icons.star, 'Recensioni reali'),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
          
          // Right side - Login form
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Accedi', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Inserisci le tue credenziali', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 40),
                        
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
                        const SizedBox(height: 20),
                        
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Password richiesta' : null,
                        ),
                        const SizedBox(height: 12),
                        
                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text('Password dimenticata?', style: TextStyle(color: Colors.teal.shade600)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Login button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Accedi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Signup link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Non hai un account?', style: TextStyle(color: Colors.grey.shade600)),
                            TextButton(
                              onPressed: () => context.go('/signup'),
                              child: Text('Registrati', style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w600)),
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
        ],
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
