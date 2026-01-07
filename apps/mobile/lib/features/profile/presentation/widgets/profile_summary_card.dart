import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/user_service.dart';
import '../../../../core/api_client.dart';

class ProfileSummaryCard extends ConsumerStatefulWidget {
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
  ConsumerState<ProfileSummaryCard> createState() => _ProfileSummaryCardState();
}

class _ProfileSummaryCardState extends ConsumerState<ProfileSummaryCard> {
  bool _isUploading = false;

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cambia Foto Profilo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal.shade800)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt, 'Fotocamera', ImageSource.camera),
                _buildSourceOption(Icons.photo_library, 'Galleria', ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      await ref.read(userServiceProvider.notifier).uploadAvatar(image);
      ref.invalidate(authProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Foto aggiornata!'), backgroundColor: Colors.green.shade600),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildSourceOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.teal.shade600),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  String? _getAvatarUrl() {
    if (widget.session.avatarUrl == null) return null;
    final avatarUrl = widget.session.avatarUrl!;
    if (avatarUrl.startsWith('http')) return avatarUrl;
    if (avatarUrl.startsWith('/static')) {
      final baseUrl = ref.read(apiClientProvider).options.baseUrl;
      return '$baseUrl$avatarUrl';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isHelper = widget.session.role == 'helper';
    final avatarUrl = _getAvatarUrl();
    
    // Fetch user stats from public profile
    final statsAsync = ref.watch(userStatsProvider(widget.session.id));
    
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
                    child: _isUploading
                      ? CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.teal.shade100,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : avatarUrl != null
                        ? CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(avatarUrl),
                            onBackgroundImageError: (_, __) {},
                            child: null,
                          )
                        : CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.teal.shade100,
                            child: Text(
                              widget.session.name.isNotEmpty ? widget.session.name[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 32, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadAvatar,
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
                            onTap: () => context.push('/u/${widget.session.id}'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.session.name,
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
                          onTap: widget.onEdit,
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
                        widget.session.role.toUpperCase(),
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
                onPressed: widget.onLogout,
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
