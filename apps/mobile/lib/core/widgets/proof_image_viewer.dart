import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../../features/home/domain/task.dart';

/// A widget that displays a proof image thumbnail with tap-to-fullscreen capability
class ProofImageThumbnail extends ConsumerWidget {
  final TaskProof proof;
  final double size;
  final BorderRadius? borderRadius;

  const ProofImageThumbnail({
    super.key,
    required this.proof,
    this.size = 80,
    this.borderRadius,
  });

  String _getImageUrl(WidgetRef ref) {
    final storageKey = proof.storageKey;
    
    if (storageKey.startsWith('http')) {
      return storageKey;
    } else if (storageKey.startsWith('/static')) {
      final baseUrl = ref.read(apiClientProvider).options.baseUrl;
      return '$baseUrl$storageKey';
    }
    return storageKey;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageKey = proof.storageKey;
    
    // Debug print to understand the issue
    print('ProofImageThumbnail: storageKey = "$storageKey"');
    
    Widget imageWidget;
    
    if (storageKey.startsWith('http') || storageKey.startsWith('/static')) {
      final imageUrl = _getImageUrl(ref);
      print('ProofImageThumbnail: Loading network image from: $imageUrl');
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey.shade400, size: size * 0.4),
                if (size > 60) ...[
                  const SizedBox(height: 4),
                  Text('Errore', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ],
            ),
          );
        },
      );
    } else if (storageKey.startsWith('/') && !kIsWeb) {
      // Local file path (mobile only)
      imageWidget = Image.file(
        File(storageKey),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: Icon(Icons.broken_image, color: Colors.grey.shade400),
          );
        },
      );
    } else {
      // Fallback placeholder
      imageWidget = Container(
        width: size,
        height: size,
        color: Colors.grey.shade200,
        child: Icon(Icons.image, color: Colors.grey.shade400),
      );
    }

    return GestureDetector(
      onTap: () => _openFullscreen(context, ref),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: imageWidget,
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenImageViewer(
          proof: proof,
          imageUrl: _getImageUrl(ref),
        ),
      ),
    );
  }
}

/// Fullscreen image viewer with zoom and pan capability
class _FullscreenImageViewer extends StatelessWidget {
  final TaskProof proof;
  final String imageUrl;

  const _FullscreenImageViewer({
    required this.proof,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Foto ${proof.kind == 'photo' ? '' : proof.kind}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                'Impossibile caricare l\'immagine',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ],
          );
        },
      );
    } else if (!kIsWeb && imageUrl.startsWith('/')) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text(
                'File non trovato',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          );
        },
      );
    }
    
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
        SizedBox(height: 16),
        Text(
          'Formato non supportato',
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
  }
}

/// A horizontal list of proof image thumbnails
class ProofImageList extends ConsumerWidget {
  final List<TaskProof> proofs;
  final double thumbnailSize;
  final double height;

  const ProofImageList({
    super.key,
    required this.proofs,
    this.thumbnailSize = 80,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (proofs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text('Nessuna foto', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: proofs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ProofImageThumbnail(
            proof: proofs[index],
            size: thumbnailSize,
          );
        },
      ),
    );
  }
}
