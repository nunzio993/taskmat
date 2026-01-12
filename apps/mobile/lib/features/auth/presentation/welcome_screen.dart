import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.location_on,
      title: 'Trova aiuto vicino a te',
      description: 'Pubblica un task e ricevi proposte da helper verificati nella tua zona.',
    ),
    _OnboardingPage(
      icon: Icons.chat_bubble_outline,
      title: 'Scegli e comunica',
      description: 'Confronta offerte, leggi recensioni e parla direttamente con l\'helper.',
    ),
    _OnboardingPage(
      icon: Icons.lock_outline,
      title: 'Paga in sicurezza',
      description: 'Il pagamento viene trattenuto finché il lavoro non è completato.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToLogin() async {
    debugPrint('Going to login...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (mounted) {
      context.go('/login');
    }
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
                    const Text(
                      'Servizi locali,\nsubito.',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pubblica un task. Trova un helper nella tua zona. Fatto.',
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
            
            // Right: Onboarding + Button
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    // Swipeable pages
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! < 0 && _currentPage < _pages.length - 1) {
                            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          } else if (details.primaryVelocity! > 0 && _currentPage > 0) {
                            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pages.length,
                          onPageChanged: (index) => setState(() => _currentPage = index),
                          itemBuilder: (context, index) => _buildPage(_pages[index]),
                        ),
                      ),
                    ),
                    // Indicators (clickable)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) => 
                        GestureDetector(
                          onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 28 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? Colors.teal.shade600 : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Inizia ora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
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
  // MOBILE LAYOUT - Scrollable to prevent overflow
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Logo and title
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
                  Text('Servizi locali, subito.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),

                  // Pages - Fixed height
                  SizedBox(
                    height: 280,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemBuilder: (context, index) => _buildPage(_pages[index]),
                    ),
                  ),

                  // Page indicators (clickable)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) => 
                      GestureDetector(
                        onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? Colors.teal.shade600 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Value bullets
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _buildBullet('Helper verificati nella tua città'),
                        _buildBullet('Pagamenti sicuri in-app'),
                        _buildBullet('Recensioni reali da utenti reali'),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  const SizedBox(height: 16),

                  // Single CTA button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Inizia ora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(page.icon, size: 56, color: Colors.teal.shade600),
          ),
          const SizedBox(height: 20),
          Text(
            page.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            page.description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.teal.shade600, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
