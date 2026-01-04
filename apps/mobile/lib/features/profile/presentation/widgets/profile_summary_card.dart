import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/user_service.dart';

class ProfileSummaryCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isHelper = session.role == 'helper';
    
    // Fetch user stats from public profile
    final statsAsync = ref.watch(userStatsProvider(session.id));
    
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
                          child: GestureDetector(
                            onTap: () => context.push('/u/${session.id}'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    session.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade800,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.teal.shade300,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.open_in_new, size: 16, color: Colors.teal.shade400),
                              ],
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
                    // Rating (from API)
                    statsAsync.when(
                      loading: () => Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.teal.shade400),
                            ),
                          ),
                        ],
                      ),
                      error: (_, __) => Row(
                        children: [
                          Icon(Icons.star_border, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Nuovo utente',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      data: (stats) {
                        if (stats == null || stats.reviewsCount == 0) {
                          return Row(
                            children: [
                              Icon(Icons.star_border, size: 16, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                'Nuovo utente',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                            const SizedBox(width: 4),
                            Text(
                              stats.averageRating.toStringAsFixed(1),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                            ),
                            Text(
                              ' (${stats.reviewsCount} ${stats.reviewsCount == 1 ? "recensione" : "recensioni"})',
                              style: TextStyle(fontSize: 12, color: Colors.teal.shade500),
                            ),
                          ],
                        );
                      },
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
