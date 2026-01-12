import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../application/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Login Controllers
  final _emailLoginCtrl = TextEditingController();
  final _passLoginCtrl = TextEditingController();
  
  // Register Controllers
  final _firstNameRegCtrl = TextEditingController();
  final _lastNameRegCtrl = TextEditingController();
  final _emailRegCtrl = TextEditingController();
  final _passRegCtrl = TextEditingController();
  final _confirmPassRegCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  
  // For validation errors
  String? _emailError;
  String? _passError;
  
  // Register validation errors
  String? _firstNameRegError;
  String? _lastNameRegError;
  String? _emailRegError;
  String? _passRegError;
  String? _confirmPassRegError;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailLoginCtrl.dispose();
    _passLoginCtrl.dispose();
    _firstNameRegCtrl.dispose();
    _lastNameRegCtrl.dispose();
    _emailRegCtrl.dispose();
    _passRegCtrl.dispose();
    _confirmPassRegCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = _emailLoginCtrl.text.contains('@') ? null : 'Email non valida';
      _passError = _passLoginCtrl.text.isNotEmpty ? null : 'Richiesta';
    });

    if (_emailError == null && _passError == null) {
      try {
        await ref.read(authProvider.notifier).login(
          _emailLoginCtrl.text,
          _passLoginCtrl.text,
        );
      } catch (e) {
        if (!mounted) return;
        String message = e.toString();
        if (e is DioException) {
          final dioError = e;
          if (dioError.response?.data != null && dioError.response?.data is Map) {
            message = dioError.response!.data['detail'] ?? message;
          } else if (dioError.response?.statusCode == 400) {
            message = "Email o password non validi.";
          }
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login fallito'),
            content: Text(message),
            actions: [
              if (message.contains('valid'))
                TextButton(
                  onPressed: () {
                    context.pop();
                    _tabController.animateTo(1);
                  },
                  child: const Text('Registrati'),
                ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _firstNameRegError = _firstNameRegCtrl.text.isNotEmpty ? null : 'Richiesto';
      _lastNameRegError = _lastNameRegCtrl.text.isNotEmpty ? null : 'Richiesto';
      _emailRegError = _emailRegCtrl.text.contains('@') ? null : 'Email non valida';
      _passRegError = _passRegCtrl.text.length >= 8 ? null : 'Min 8 caratteri';
      _confirmPassRegError = _confirmPassRegCtrl.text == _passRegCtrl.text ? null : 'Le password non coincidono';
      _cityError = _cityCtrl.text.isNotEmpty ? null : 'Richiesto';
    });

    if (_firstNameRegError != null || _lastNameRegError != null || _emailRegError != null || 
        _passRegError != null || _confirmPassRegError != null || _cityError != null) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accetta i termini e la privacy policy')),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).register(
        _emailRegCtrl.text,
        _passRegCtrl.text,
        'client',
        _firstNameRegCtrl.text,
        _lastNameRegCtrl.text,
      );
    } catch (e) {
      if (!mounted) return;
      
      String message = e.toString();
      if (e is DioException) {
        final dioError = e;
        if (dioError.response?.data != null && dioError.response?.data is Map) {
          final data = dioError.response!.data;
          if (data['detail'] is String) {
            message = data['detail'];
          } else if (data['detail'] is List) {
            final List errors = data['detail'];
            message = errors.map((err) => "${err['loc'].last}: ${err['msg']}").join('\n');
          }
        }
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registrazione fallita'),
          content: Text(message),
          actions: [TextButton(onPressed: () => context.pop(), child: const Text('OK'))],
        ),
      );
    }
  }

  void _handleDevLogin(String role) {
    if (role == 'helper') {
      _emailLoginCtrl.text = 'helper@test.it';
      _passLoginCtrl.text = 'testtt';
    } else {
      _emailLoginCtrl.text = 'test@test.it';
      _passLoginCtrl.text = 'testtt';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDE/DESKTOP LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWideLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            // Left: Branding
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.teal.shade700, Colors.teal.shade500],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.handshake, size: 32, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Text('TaskMat', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _tabController.index == 0 ? 'Bentornato!' : 'Inizia ora',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tabController.index == 0 
                          ? 'Accedi per gestire i tuoi task e continuare dove avevi lasciato.'
                          : 'Crea un account per pubblicare task o iniziare a lavorare.',
                      style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 32),
                    _buildWideBullet('Helper verificati nella tua città'),
                    _buildWideBullet('Pagamenti sicuri in-app'),
                    _buildWideBullet('Recensioni reali da utenti reali'),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            
            // Right: Form
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(48),
                  child: _buildAuthForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white.withOpacity(0.9), size: 20),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 15)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.handshake, size: 40, color: Colors.teal.shade600),
          ),
          const SizedBox(height: 12),
          Text('TaskMat', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
          const SizedBox(height: 32),
          _buildAuthForm(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED AUTH FORM
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.teal.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Accedi'),
              Tab(text: 'Registrati'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Form content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _tabController.index == 0 ? _buildLoginForm() : _buildRegisterForm(),
        ),

        const SizedBox(height: 24),
        
        // SEC-017: Dev tools only in debug mode
        if (kDebugMode) ...[
          const Text('Quick Test Login', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _handleDevLogin('client'),
                child: Text('Client', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _handleDevLogin('helper'),
                child: Text('Helper', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      children: [
        TextField(
          controller: _emailLoginCtrl,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _emailError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passLoginCtrl,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            errorText: _passError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          obscureText: _obscurePassword,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text('Password dimenticata?', style: TextStyle(color: Colors.teal.shade600)),
          ),
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);
            final isLoading = authState.isLoading;

            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Accedi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameRegCtrl,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  errorText: _firstNameRegError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastNameRegCtrl,
                decoration: InputDecoration(
                  labelText: 'Cognome',
                  errorText: _lastNameRegError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailRegCtrl,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _emailRegError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cityCtrl,
          decoration: InputDecoration(
            labelText: 'Città',
            prefixIcon: const Icon(Icons.location_city_outlined),
            errorText: _cityError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passRegCtrl,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            helperText: 'Minimo 6 caratteri',
            errorText: _passRegError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPassRegCtrl,
          decoration: InputDecoration(
            labelText: 'Conferma Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            errorText: _confirmPassRegError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _acceptedTerms,
          onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
          title: Text('Accetto i Termini e la Privacy Policy', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.teal.shade600,
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);
            final isLoading = authState.isLoading;

            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Crea Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ],
    );
  }
}
