import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/application/user_service.dart';

/// Tag options based on role
const clientTags = ["Professionale", "Puntuale", "Cordiale", "Veloce", "Affidabile", "Comunicativo"];
const helperTags = ["Chiaro", "Rispettoso", "Disponibile", "Pagamento rapido", "Collaborativo"];

class ReviewDialog extends ConsumerStatefulWidget {
  final int taskId;
  final String targetUserName;
  final bool isReviewingAsClient; // true = client reviewing helper

  const ReviewDialog({
    super.key,
    required this.taskId,
    required this.targetUserName,
    required this.isReviewingAsClient,
  });

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  int _stars = 0;
  final _commentController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _isSubmitting = false;

  List<String> get _availableTags => widget.isReviewingAsClient ? clientTags : helperTags;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno 1 stella')),
      );
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isNotEmpty && comment.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il commento deve avere almeno 10 caratteri')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(userServiceProvider.notifier).submitReview(
        widget.taskId,
        stars: _stars,
        comment: comment.isNotEmpty ? comment : null,
        tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate review submitted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recensione inviata! ⭐'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lascia una Recensione',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'per ${widget.targetUserName}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stars Selection
              const Text('Come valuteresti l\'esperienza?', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _stars = starNum),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _stars >= starNum ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: _stars >= starNum ? Colors.amber : Colors.grey.shade300,
                      ),
                    ),
                  );
                }),
              ),
              if (_stars > 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getStarLabel(_stars),
                      style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Tags Selection
              const Text('Tag (opzionale, max 3)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected && _selectedTags.length < 3) {
                          _selectedTags.add(tag);
                        } else if (!selected) {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: Colors.teal.shade100,
                    checkmarkColor: Colors.teal.shade700,
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Comment
              const Text('Commento (opzionale)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Descrivi la tua esperienza...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Invia Recensione', style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 8),
              Text(
                'La recensione sarà visibile quando anche l\'altra parte lascerà la sua.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStarLabel(int stars) {
    switch (stars) {
      case 1: return 'Pessimo';
      case 2: return 'Scarso';
      case 3: return 'Nella media';
      case 4: return 'Buono';
      case 5: return 'Eccellente! ⭐';
      default: return '';
    }
  }
}
