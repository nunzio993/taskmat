import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNavBar(context),
            _buildHeroSection(context),
            _buildFeaturesSection(context),
            _buildHowItWorksSection(context),
            _buildCTASection(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
      color: Colors.white,
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.handshake, color: Colors.teal.shade600, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'TaskMat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Nav links
          _buildNavLink('Come funziona', () {}),
          const SizedBox(width: 32),
          _buildNavLink('Per gli Helper', () {}),
          const SizedBox(width: 32),
          _buildNavLink('FAQ', () {}),
          const SizedBox(width: 40),
          // Auth buttons
          OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal.shade600,
              side: BorderSide(color: Colors.teal.shade600),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Accedi'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.go('/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 0,
            ),
            child: const Text('Registrati'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade700, Colors.teal.shade500],
        ),
      ),
      child: Row(
        children: [
          // Left: Text content
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Servizi locali,\nsubito.',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pubblica un task, ricevi proposte da helper verificati, paga solo a lavoro completato.',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.go('/signup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Pubblica un task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/signup'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Diventa Helper', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                // Trust badges
                Row(
                  children: [
                    _buildTrustBadge(Icons.verified_user, 'Helper verificati'),
                    const SizedBox(width: 32),
                    _buildTrustBadge(Icons.security, 'Pagamenti sicuri'),
                    const SizedBox(width: 32),
                    _buildTrustBadge(Icons.star, 'Recensioni reali'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 80),
          // Right: Illustration/mockup
          Expanded(
            flex: 4,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_iphone, size: 120, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'App mockup',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEATURES SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Text(
            'Cosa puoi fare con TaskMat',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Micro-servizi locali per ogni esigenza',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 64),
          Row(
            children: [
              Expanded(child: _buildFeatureCard(Icons.cleaning_services, 'Pulizie', 'Casa, ufficio, post-trasloco')),
              const SizedBox(width: 24),
              Expanded(child: _buildFeatureCard(Icons.local_shipping, 'Traslochi', 'Piccoli traslochi e trasporti')),
              const SizedBox(width: 24),
              Expanded(child: _buildFeatureCard(Icons.handyman, 'Montaggio', 'Mobili IKEA e non solo')),
              const SizedBox(width: 24),
              Expanded(child: _buildFeatureCard(Icons.plumbing, 'Riparazioni', 'Piccoli lavori domestici')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildFeatureCard(Icons.grass, 'Giardinaggio', 'Manutenzione verde')),
              const SizedBox(width: 24),
              Expanded(child: _buildFeatureCard(Icons.delivery_dining, 'Consegne', 'Ritiri e consegne locali')),
              const SizedBox(width: 24),
              Expanded(child: _buildFeatureCard(Icons.format_paint, 'Imbiancatura', 'Tinteggiatura pareti')),
              const SizedBox(width: 24),
              Expanded(child: _buildFeatureCard(Icons.more_horiz, 'E altro...', 'Esplora tutte le categorie')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.teal.shade600, size: 32),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOW IT WORKS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHowItWorksSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Come funziona',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 64),
          Row(
            children: [
              Expanded(child: _buildStep('1', 'Descrivi il task', 'Spiega cosa ti serve, dove e quando', Icons.edit_note)),
              _buildStepConnector(),
              Expanded(child: _buildStep('2', 'Ricevi offerte', 'Gli helper inviano proposte con il loro prezzo', Icons.inbox)),
              _buildStepConnector(),
              Expanded(child: _buildStep('3', 'Scegli l\'helper', 'Valuta profili e recensioni', Icons.person_search)),
              _buildStepConnector(),
              Expanded(child: _buildStep('4', 'Paga a lavoro fatto', 'Il pagamento è trattenuto fino al completamento', Icons.lock)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle, IconData icon) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.teal.shade600, size: 36),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.teal.shade600,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 60,
      height: 2,
      color: Colors.teal.shade200,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CTA SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pronto a iniziare?',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pubblica il tuo primo task o diventa un helper oggi stesso.',
                  style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => context.go('/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Registrati gratis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 48),
      color: Colors.grey.shade900,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & description
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.handshake, color: Colors.teal.shade400, size: 24),
                        const SizedBox(width: 8),
                        const Text('TaskMat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Marketplace per micro-servizi locali. Collega chi cerca aiuto con chi lo offre.',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 64),
              // Links
              Expanded(child: _buildFooterColumn('Prodotto', ['Come funziona', 'Categorie', 'Prezzi', 'FAQ'])),
              Expanded(child: _buildFooterColumn('Azienda', ['Chi siamo', 'Blog', 'Careers', 'Contatti'])),
              Expanded(child: _buildFooterColumn('Legale', ['Privacy', 'Termini', 'Cookie', 'Regole community'])),
            ],
          ),
          const SizedBox(height: 48),
          Divider(color: Colors.grey.shade700),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('© 2026 TaskMat. Tutti i diritti riservati.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(link, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        )),
      ],
    );
  }
}
