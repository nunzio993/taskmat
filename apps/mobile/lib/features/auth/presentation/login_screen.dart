
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
      _emailError = _emailLoginCtrl.text.contains('@') ? null : 'Invalid email';
      _passError = _passLoginCtrl.text.isNotEmpty ? null : 'Required';
    });

    if (_emailError == null && _passError == null) {
      try {
        await ref.read(authProvider.notifier).login(
          _emailLoginCtrl.text,
          _passLoginCtrl.text,
        );
      } catch (e) {
        if (!mounted) return;
        // Error is handled by state update -> disabled button
        // But we explicitly show snackbar here for better reliability
         String message = e.toString();
         if (e is DioException) {
            final dioError = e;
            if (dioError.response?.data != null && dioError.response?.data is Map) {
               message = dioError.response!.data['detail'] ?? message;
            } else if (dioError.response?.statusCode == 400) {
              message = "Invalid email or password.";
           }
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(message),
            actions: [
              if (message.contains('Invalid'))
                TextButton(
                  onPressed: () {
                    context.pop();
                    _tabController.animateTo(1); // Switch to Register tab
                  },
                  child: const Text('Go to Sign Up'),
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
    // 1. Reset errors
    setState(() {
       _firstNameRegError = _firstNameRegCtrl.text.isNotEmpty ? null : 'Required';
       _lastNameRegError = _lastNameRegCtrl.text.isNotEmpty ? null : 'Required';
       _emailRegError = _emailRegCtrl.text.contains('@') ? null : 'Invalid email';
       _passRegError = _passRegCtrl.text.length >= 6 ? null : 'Min 6 chars';
       _confirmPassRegError = _confirmPassRegCtrl.text == _passRegCtrl.text ? null : 'Passwords do not match';
       _cityError = _cityCtrl.text.isNotEmpty ? null : 'Required';
    });

    if (_firstNameRegError != null || _lastNameRegError != null || _emailRegError != null || _passRegError != null || 
        _confirmPassRegError != null || _cityError != null) {
        return;
    }

     if (!_acceptedTerms) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept terms and privacy policy')));
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
                // Parse Pydantic validation errors
                final List errors = data['detail'];
                message = errors.map((err) => "${err['loc'].last}: ${err['msg']}").join('\n');
              }
           }
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Failed'),
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
    setState(() {}); // Trigger rebuild to show text
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // DESKTOP: Split View
            return Row(
              children: [
                // Right: Branding (Visuals)
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?q=80&w=2574&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                        opacity: 0.2, // Blend with color
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.handshake, size: 80, color: Colors.white),
                          const SizedBox(height: 24),
                          Text(
                            'TaskMate',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                           Text(
                            'Your personal task assistant.\nAnytime, Anywhere.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Left: Auth Form
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.all(48),
                      child: _buildAuthColumn(context),
                    ),
                  ),
                ),
              ],
            );
          }
          
          // MOBILE: Standard View
          return Center(
             child: SingleChildScrollView(
               padding: const EdgeInsets.all(24.0),
               child: _buildAuthColumn(context),
             ),
          );
        },
      ),
    );
  }

  Widget _buildAuthColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (MediaQuery.of(context).size.width <= 800) ...[
          // Mobile Logo
          const Icon(Icons.handshake_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            'TaskMate',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 48),
        ],

        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Log In'),
            Tab(text: 'Sign Up (Client)'),
          ],
        ),
        const SizedBox(height: 24),
        
        // Content based on tab
        Builder(
          builder: (_) {
             if (_tabController.index == 0) {
               return _buildLoginForm();
             } else {
               return _buildRegisterForm();
             }
          },
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        // Helper Link Removed (Now handled inside app)
        
        // Developer Tools
        const SizedBox(height: 24),
        const Text('Developer Quick Login', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             TextButton(
               onPressed: () => _handleDevLogin('client'),
               child: const Text('Dev Client'),
             ),
             TextButton(
               onPressed: () => _handleDevLogin('helper'),
               child: const Text('Dev Helper'),
             ),
          ],
        )
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        const SizedBox(height: 16),
        TextField(
          controller: _emailLoginCtrl,
          decoration: InputDecoration(
            labelText: 'Email or Phone', 
            prefixIcon: const Icon(Icons.person_outline),
            errorText: _emailError,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passLoginCtrl,
          decoration: InputDecoration(
            labelText: 'Password', 
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            errorText: _passError,
            border: const OutlineInputBorder(),
          ),
          obscureText: _obscurePassword,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {}, 
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);
            final isLoading = authState.isLoading;

            return ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Log In'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstNameRegCtrl,
                  decoration: InputDecoration(
                    labelText: 'First Name', 
                    prefixIcon: const Icon(Icons.person_outline), 
                    border: const OutlineInputBorder(),
                    errorText: _firstNameRegError,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _lastNameRegCtrl,
                  decoration: InputDecoration(
                    labelText: 'Last Name', 
                    prefixIcon: const Icon(Icons.person_outline), 
                    border: const OutlineInputBorder(),
                    errorText: _lastNameRegError,
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
              border: const OutlineInputBorder(),
              errorText: _emailRegError,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityCtrl,
                  decoration: InputDecoration(
                    labelText: 'City / Zip', 
                    prefixIcon: const Icon(Icons.location_city), 
                    border: const OutlineInputBorder(),
                    errorText: _cityError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passRegCtrl,
            decoration: InputDecoration(
              labelText: 'Password', 
              prefixIcon: const Icon(Icons.lock_outline), 
              border: const OutlineInputBorder(),
              errorText: _passRegError,
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPassRegCtrl,
            decoration: InputDecoration(
              labelText: 'Confirm Password', 
              prefixIcon: const Icon(Icons.lock_outline), 
              border: const OutlineInputBorder(),
              errorText: _confirmPassRegError,
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
            title: const Text('I accept Terms & Privacy Policy', style: TextStyle(fontSize: 12)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              final isLoading = authState.isLoading;

              return ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Create Client Account'),
              );
            },
          ),
        ],
      ),
    );
  }
}
