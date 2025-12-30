import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile/features/home/application/task_service.dart';

class OfferDialog extends ConsumerStatefulWidget {
  final int taskId;
  final int currentPriceCents;

  const OfferDialog({
    super.key,
    required this.taskId,
    required this.currentPriceCents,
  });

  @override
  ConsumerState<OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends ConsumerState<OfferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _msgController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = (widget.currentPriceCents / 100).toStringAsFixed(2);
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final price = (double.parse(_priceController.text) * 100).round();
      await ref.read(taskServiceProvider.notifier).createOffer(
        widget.taskId, 
        price, 
        _msgController.text
      );
      if (!mounted) return;
      Navigator.of(context).pop(true); // Return true on success
    } catch (e) {
      if (!mounted) return;
      // Detailed error for debugging
      final msg = (e is DioException) 
          ? 'Error: ${e.response?.data ?? e.message}' 
          : 'Error: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Make an Offer'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (€)'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _msgController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message (Optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isLoading ? null : _submitOffer, 
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send Offer')
        ),
      ],
    );
  }
}
