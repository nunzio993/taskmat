import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/application/auth_provider.dart';
import 'package:mobile/features/profile/application/user_service.dart';

class PublicUserProfileScreen extends ConsumerStatefulWidget {
  final int userId;

  const PublicUserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<PublicUserProfileScreen> createState() => _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends ConsumerState<PublicUserProfileScreen> {
  late Future<PublicUser> _userFuture;
  late Future<List<PublicReview>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _userFuture = ref.read(userServiceProvider.notifier).getPublicProfile(widget.userId);
    _reviewsFuture = ref.read(userServiceProvider.notifier).getPublicReviews(widget.userId);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Profilo', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade600),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.teal.shade600),
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, size: 20), SizedBox(width: 8), Text('Segnala')])),
              const PopupMenuItem(value: 'block', child: Row(children: [Icon(Icons.block, size: 20), SizedBox(width: 8), Text('Blocca')])),
            ],
          ),
        ],
      ),
      body: FutureBuilder<PublicUser>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Errore nel caricamento', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          final user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Card
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: _buildHeader(user),
                ),
                const SizedBox(height: 8),
                // Overview Section
                _buildSection('Informazioni', _buildOverviewContent(user)),
                const SizedBox(height: 8),
                // Stats Section
                _buildSection('Statistiche', _buildStatsContent(user)),
                const SizedBox(height: 8),
                // Reviews Section
                _buildReviewsSection(user),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(PublicUser user) {
    final isHelper = user.role == 'helper';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.teal.shade200, width: 3),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.teal.shade100,
            child: Text(
              user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : '?',
              style: TextStyle(fontSize: 32, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name ?? 'Utente',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
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
                  isHelper ? 'HELPER' : 'CLIENTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHelper ? Colors.teal.shade700 : Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Rating
              if (user.stats.averageRating > 0 || user.stats.reviewsCount > 0)
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Text(
                      user.stats.averageRating.toStringAsFixed(1),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                    ),
                    Text(
                      ' (${user.stats.reviewsCount} recensioni)',
                      style: TextStyle(fontSize: 12, color: Colors.teal.shade500),
                    ),
                  ],
                )
              else
                Text('Nuovo utente', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildOverviewContent(PublicUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          Text(user.bio!, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
          const SizedBox(height: 12),
        ] else ...[
          Text('Nessuna bio disponibile', style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
        ],
        if (user.languages.isNotEmpty)
          _infoRow(Icons.language, 'Lingue', user.languages.join(', ')),
        if (user.role == 'helper' && user.skills.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoRow(Icons.handyman, 'Servizi', user.skills.join(', ')),
        ],
        if (user.role == 'helper' && user.hourlyRate != null) ...[
          const SizedBox(height: 8),
          _infoRow(Icons.euro, 'Tariffa', '€${user.hourlyRate!.toStringAsFixed(0)}/ora'),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.teal.shade400),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800))),
      ],
    );
  }

  Widget _buildStatsContent(PublicUser user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statCard(Icons.check_circle_outline, '${user.stats.tasksCompleted}', user.role == 'helper' ? 'Lavori' : 'Task'),
        _statCard(Icons.star_outline, '${user.stats.reviewsCount}', 'Recensioni'),
        _statCard(Icons.verified_user_outlined, user.stats.cancelRateLabel, 'Affidabilità'),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.teal.shade600),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.teal.shade500)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(PublicUser user) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recensioni', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          const SizedBox(height: 12),
          FutureBuilder<List<PublicReview>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Errore nel caricamento', style: TextStyle(color: Colors.red.shade300));
              }

              final reviews = snapshot.data!;
              if (reviews.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Nessuna recensione ancora', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: reviews.map((r) => _reviewCard(r)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(PublicReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.teal.shade100,
                child: Text(review.fromUserName[0].toUpperCase(), style: TextStyle(color: Colors.teal.shade700, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(review.fromUserName, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.stars ? Icons.star : Icons.star_border,
                  size: 14,
                  color: Colors.amber.shade600,
                )),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Segnala utente'),
        content: const Text('Vuoi segnalare questo utente per comportamento inappropriato?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Segnalazione inviata'), backgroundColor: Colors.teal.shade600),
              );
            },
            child: const Text('Segnala'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Blocca utente'),
        content: const Text('Vuoi bloccare questo utente? Non potrai più ricevere messaggi o offerte da lui.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Utente bloccato'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Blocca'),
          ),
        ],
      ),
    );
  }
}
