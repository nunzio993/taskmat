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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                     CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        session.name.isNotEmpty ? session.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 28, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    if (session.role == 'helper')
                      Positioned(
                        right: 0, 
                        bottom: 0, 
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          child: const Icon(Icons.verified, size: 12, color: Colors.white),
                        ),
                      )
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        session.role.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                      if (session.role == 'helper') ...[
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            Text(' 4.9 (12 reviews)', style: TextStyle(fontSize: 12)),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: onLogout,
                      tooltip: 'Logout',
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
