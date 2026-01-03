import 'package:flutter/material.dart';
import '../../../auth/application/auth_provider.dart';

class ProfileSummaryCard extends StatelessWidget {
  final UserSession session;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const ProfileSummaryCard({
    super.key, 
    required this.session,
    required this.onEdit,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isHelper = session.role == 'helper';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with edit option
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.teal.shade200, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        session.name.isNotEmpty ? session.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 32, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Name, Role, Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Name (editable)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onEdit,
                          child: Icon(Icons.edit, size: 18, color: Colors.teal.shade400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHelper ? Colors.teal.shade100 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isHelper ? Colors.teal.shade700 : Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rating (if available)
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '4.9',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                        ),
                        Text(
                          ' (12 recensioni)',
                          style: TextStyle(fontSize: 12, color: Colors.teal.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Logout Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onLogout,
                icon: Icon(Icons.logout, size: 18, color: Colors.red.shade400),
                label: Text('Esci', style: TextStyle(color: Colors.red.shade400)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
