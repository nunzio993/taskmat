import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';

/// A reusable widget to display user avatars with network image support.
/// Falls back to initials if no avatar URL is available.
class UserAvatar extends ConsumerWidget {
  final String? avatarUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.name,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  String? _getFullAvatarUrl(WidgetRef ref) {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;
    
    if (avatarUrl!.startsWith('http')) {
      return avatarUrl;
    } else if (avatarUrl!.startsWith('/static')) {
      final baseUrl = ref.read(apiClientProvider).options.baseUrl;
      return '$baseUrl$avatarUrl';
    }
    return null;
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullUrl = _getFullAvatarUrl(ref);
    final bgColor = backgroundColor ?? Colors.teal.shade100;
    final fgColor = foregroundColor ?? Colors.teal.shade700;

    if (fullUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: NetworkImage(fullUrl),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
