import 'package:flutter/material.dart';

/// Profile page for desktop
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Profile card
          Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade100,
                      child: Icon(Icons.person, size: 50, color: Colors.teal.shade600),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Mario Rossi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Client', style: TextStyle(color: Colors.teal.shade700, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Helper', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(' (24 recensioni)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildProfileStat('Task completati', '12'),
                _buildProfileStat('Lavori eseguiti', '8'),
                _buildProfileStat('Membro da', 'Gen 2026'),
              ],
            ),
          ),
          const SizedBox(width: 24),
          
          // Right: Profile details
          Expanded(
            child: Column(
              children: [
                // Personal info
                _buildSection(
                  'Informazioni personali',
                  Icons.person_outline,
                  [
                    _buildInfoRow('Nome', 'Mario Rossi'),
                    _buildInfoRow('Email', 'mario.rossi@email.com'),
                    _buildInfoRow('Telefono', '+39 333 1234567'),
                    _buildInfoRow('Città', 'Milano'),
                  ],
                  onEdit: () {},
                ),
                const SizedBox(height: 24),
                
                // Bio
                _buildSection(
                  'Bio',
                  Icons.description_outlined,
                  [
                    const Text(
                      'Sono un professionista affidabile con esperienza in pulizie e piccole riparazioni domestiche. Disponibile e puntuale.',
                      style: TextStyle(height: 1.6),
                    ),
                  ],
                  onEdit: () {},
                ),
                const SizedBox(height: 24),
                
                // Categories (for helpers)
                _buildSection(
                  'Categorie di servizio',
                  Icons.category_outlined,
                  [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCategoryChip('Pulizie'),
                        _buildCategoryChip('Montaggio'),
                        _buildCategoryChip('Riparazioni'),
                        _buildCategoryChip('+ Aggiungi', isAdd: true),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Reviews
                _buildSection(
                  'Recensioni recenti',
                  Icons.star_outline,
                  [
                    _buildReview('Laura B.', 5, 'Ottimo lavoro, puntuale e preciso!', '2 giorni fa'),
                    const SizedBox(height: 16),
                    _buildReview('Giuseppe V.', 4, 'Buon lavoro, consigliato.', '1 settimana fa'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children, {VoidCallback? onEdit}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal.shade600, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifica'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, {bool isAdd = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isAdd ? Colors.grey.shade100 : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: isAdd ? Border.all(color: Colors.grey.shade300, style: BorderStyle.solid) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAdd ? Colors.grey.shade600 : Colors.teal.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildReview(String name, int stars, String text, String date) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade200,
          child: Text(name[0], style: TextStyle(color: Colors.grey.shade600)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ...List.generate(5, (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  )),
                  const Spacer(),
                  Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(text, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }
}
