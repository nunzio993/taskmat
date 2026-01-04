import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/user_service.dart';

class PublicTab extends ConsumerStatefulWidget {
  const PublicTab({super.key});

  @override
  ConsumerState<PublicTab> createState() => _PublicTabState();
}

class _PublicTabState extends ConsumerState<PublicTab> {
  bool _isEditing = false;
  late TextEditingController _bioCtrl;
  late List<String> _selectedLanguages;
  
  final List<String> _availableLanguages = ['Italiano', 'English', 'Español', 'Français', 'Deutsch'];

  @override
  void initState() {
    super.initState();
    final session = ref.read(authProvider).value!;
    _bioCtrl = TextEditingController(text: session.bio ?? '');
    _selectedLanguages = List<String>.from(session.languages);
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() async {
    if (_isEditing) {
      // Save both bio and languages
      await ref.read(authProvider.notifier).updateProfile(
        bio: _bioCtrl.text,
        languages: _selectedLanguages,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Profilo pubblico salvato'), backgroundColor: Colors.green.shade600),
        );
      }
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).value!;
    final isHelper = session.role == 'helper';
    final isClient = session.role == 'client';
    
    // Fetch real stats from API
    final statsAsync = ref.watch(userStatsProvider(session.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section Header with Edit Button
        _buildSectionHeader('Informazioni Pubbliche', _isEditing, _toggleEdit),
        const SizedBox(height: 16),
        
        // ═══════════════════════════════════════════════════════════════
        // EDITABLE SECTION
        // ═══════════════════════════════════════════════════════════════
        _buildCard(
          title: 'Bio',
          icon: Icons.person_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _bioCtrl,
                enabled: _isEditing,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Scrivi qualcosa su di te...',
                  hintStyle: TextStyle(color: Colors.teal.shade300),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  filled: true,
                  fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Languages
        _buildCard(
          title: 'Lingue Parlate',
          icon: Icons.language,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableLanguages.map((lang) {
              final isSelected = _selectedLanguages.contains(lang);
              return FilterChip(
                label: Text(lang),
                selected: isSelected,
                selectedColor: Colors.teal.shade100,
                backgroundColor: Colors.teal.shade50.withValues(alpha: 0.3),
                checkmarkColor: Colors.teal.shade700,
                side: BorderSide(color: isSelected ? Colors.teal.shade400 : Colors.teal.shade200),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.teal.shade800 : Colors.teal.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: _isEditing ? (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(lang);
                    } else if (_selectedLanguages.length > 1) {
                      _selectedLanguages.remove(lang);
                    }
                  });
                } : null,
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // ═══════════════════════════════════════════════════════════════
        // READ-ONLY SECTION - REAL DATA FROM API
        // ═══════════════════════════════════════════════════════════════
        _buildSectionHeader('Statistiche', false, null),
        const SizedBox(height: 16),
        
        // Rating & Reviews from API
        _buildCard(
          title: 'Reputazione',
          icon: Icons.star_outline,
          child: statsAsync.when(
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)),
              ),
            ),
            error: (_, __) => Column(
              children: [
                _buildStatRow(Icons.star, 'Rating Medio', '—', Colors.grey.shade400),
                Divider(color: Colors.teal.shade100),
                _buildStatRow(Icons.rate_review, 'Recensioni', '—', Colors.grey.shade400),
              ],
            ),
            data: (stats) {
              final rating = stats?.averageRating ?? 0.0;
              final reviewCount = stats?.reviewsCount ?? 0;
              
              return Column(
                children: [
                  _buildStatRow(
                    Icons.star, 
                    'Rating Medio', 
                    reviewCount > 0 ? '${rating.toStringAsFixed(1)} ⭐' : 'Nuovo utente',
                    reviewCount > 0 ? Colors.amber.shade600 : Colors.grey.shade500,
                  ),
                  Divider(color: Colors.teal.shade100),
                  _buildStatRow(Icons.rate_review, 'Recensioni', '$reviewCount', Colors.teal.shade600),
                ],
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Role-specific Stats from API
        if (isClient)
          _buildCard(
            title: 'Statistiche Cliente',
            icon: Icons.assignment_outlined,
            child: statsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)),
                ),
              ),
              error: (_, __) => Column(
                children: [
                  _buildStatRow(Icons.check_circle, 'Task Completate', '—', Colors.grey.shade400),
                ],
              ),
              data: (stats) {
                final completed = stats?.tasksCompleted ?? 0;
                return Column(
                  children: [
                    _buildStatRow(Icons.check_circle, 'Task Completate', '$completed', Colors.green.shade600),
                  ],
                );
              },
            ),
          ),
        
        if (isHelper)
          _buildCard(
            title: 'Statistiche Helper',
            icon: Icons.handyman_outlined,
            child: statsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)),
                ),
              ),
              error: (_, __) => Column(
                children: [
                  _buildStatRow(Icons.check_circle, 'Lavori Completati', '—', Colors.grey.shade400),
                ],
              ),
              data: (stats) {
                final completed = stats?.tasksCompleted ?? 0;
                return Column(
                  children: [
                    _buildStatRow(Icons.check_circle, 'Lavori Completati', '$completed', Colors.green.shade600),
                  ],
                );
              },
            ),
          ),
        
        // ═══════════════════════════════════════════════════════════════
        // HELPER ONLY: Services Display (read-only from Preferences)
        // ═══════════════════════════════════════════════════════════════
        if (isHelper) ...[
          const SizedBox(height: 24),
          _buildSectionHeader('Servizi Offerti', false, null),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Categorie Abilitate',
            icon: Icons.category_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modificabili nelle Preferenze',
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade400, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: session.categories.map((cat) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getCategoryIcon(cat), size: 16, color: Colors.teal.shade600),
                          const SizedBox(width: 6),
                          Text(cat, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isEditing, VoidCallback? onToggle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        if (onToggle != null)
          TextButton.icon(
            onPressed: onToggle,
            icon: Icon(isEditing ? Icons.check : Icons.edit, size: 18, color: Colors.teal.shade600),
            label: Text(
              isEditing ? 'Salva' : 'Modifica',
              style: TextStyle(color: Colors.teal.shade600),
            ),
          ),
      ],
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: Colors.teal.shade600))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cleaning': return Icons.cleaning_services;
      case 'moving': return Icons.local_shipping;
      case 'gardening': return Icons.grass;
      case 'plumbing': return Icons.plumbing;
      case 'electrical': return Icons.electrical_services;
      case 'painting': return Icons.format_paint;
      default: return Icons.work;
    }
  }
}
