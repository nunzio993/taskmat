import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/helper_service.dart';
import '../../../auth/application/auth_provider.dart';

class HelperRegistrationScreen extends ConsumerStatefulWidget {
  const HelperRegistrationScreen({super.key});

  @override
  ConsumerState<HelperRegistrationScreen> createState() => _HelperRegistrationScreenState();
}

class _HelperRegistrationScreenState extends ConsumerState<HelperRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  final _bioController = TextEditingController();
  
  final List<String> _availableSkills = [
    'Plumbing', 'Electrical', 'Cleaning', 'Moving', 'Gardening', 'Painting', 'Assembly'
  ];
  final List<String> _selectedSkills = [];
  
  String? _uploadedDocPath;
  String? _uploadedDocType;
  bool _isLoading = false;

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });

      try {
        await ref.read(helperServiceProvider.notifier).uploadDocument(image.path, type);
        setState(() {
          _uploadedDocPath = image.path;
          _uploadedDocType = type;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please select at least one skill')),
      );
      return;
    }
    if (_uploadedDocPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please upload an ID document')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Update Profile
      final rate = double.tryParse(_rateController.text);
      await ref.read(helperServiceProvider.notifier).updateProfile(
        skills: _selectedSkills,
        hourlyRate: rate,
        bio: _bioController.text,
        isAvailable: true,
      );

      // 2. Request Verification
      await ref.read(helperServiceProvider.notifier).verify();

      // 3. Upgrade Role
      await ref.read(authProvider.notifier).becomeHelper();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request submitted!')),
      );
      Navigator.of(context).pop(); // Go back to profile

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become a Helper')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select your Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: _availableSkills.map((skill) {
                      return FilterChip(
                        label: Text(skill),
                        selected: _selectedSkills.contains(skill),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedSkills.add(skill);
                            } else {
                              _selectedSkills.remove(skill);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Hourly Rate (€)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 25.0'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Bio / Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Tell us about your experience...'),
                  ),
                  const SizedBox(height: 24),

                  const Text('Verification Document (ID Card)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _uploadedDocPath != null 
                    ? Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          const Expanded(child: Text("Document Uploaded")),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _uploadedDocPath = null;
                                _uploadedDocType = null;
                              });
                            },
                          )
                        ],
                      )
                    : OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload ID Card'),
                        onPressed: () => _pickImage('id_card'),
                      ),
                  
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _submitVerification,
                      child: const Text('Submit for Verification'),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }
}
