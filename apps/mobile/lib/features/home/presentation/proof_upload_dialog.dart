import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/home/application/task_service.dart';

class ProofUploadDialog extends ConsumerStatefulWidget {
  final int taskId;
  const ProofUploadDialog({super.key, required this.taskId});

  @override
  ConsumerState<ProofUploadDialog> createState() => _ProofUploadDialogState();
}

class _ProofUploadDialogState extends ConsumerState<ProofUploadDialog> {
  XFile? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = picked);
    }
  }

  Future<void> _submit() async {
    if (_image == null) return;
    setState(() => _isLoading = true);
    
    try {
      await ref.read(taskServiceProvider.notifier).uploadProof(widget.taskId, _image!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Proof of Completion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Please upload a photo to prove the task is done.', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb 
                  ? Image.network(_image!.path, height: 150, fit: BoxFit.cover)
                  : Image.file(File(_image!.path), height: 150, fit: BoxFit.cover),
            )
          else
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Select Photo'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(20)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _image != null && !_isLoading ? _submit : null,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Text('Upload & Done'),
        ),
      ],
    );
  }
}
