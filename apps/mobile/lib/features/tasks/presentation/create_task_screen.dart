import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../application/create_task_controller.dart';
import 'package:mobile/core/constants/categories.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Task Details
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String _category = 'Generale';
  String _urgency = 'medium';
  
  // Location - Map Picker
  LatLng _selectedLocation = const LatLng(41.9028, 12.4964);
  final MapController _mapController = MapController();
  bool _useMapPicker = true;
  
  // Location - Address Form
  final _streetController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _provinceController = TextEditingController();
  final _addressExtraController = TextEditingController();
  String? _placeId;
  String? _formattedAddress;
  
  // Access Notes (helper-only)
  final _accessNotesController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_selectedLocation, 15);
      }
    } catch (e) {
      debugPrint('Error getting position: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _provinceController.dispose();
    _addressExtraController.dispose();
    _accessNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text);
    if (price == null) return;
    final priceCents = (price * 100).toInt();

    // Build address data
    final addressData = {
      'street': _streetController.text,
      'street_number': _streetNumberController.text,
      'city': _cityController.text,
      'postal_code': _postalCodeController.text,
      'province': _provinceController.text,
      'address_extra': _addressExtraController.text,
      'place_id': _placeId,
      'formatted_address': _formattedAddress,
      'access_notes': _accessNotesController.text,
    };

    final success = await ref.read(createTaskControllerProvider.notifier).createTask(
      title: _titleController.text,
      description: _descController.text,
      category: _category,
      priceCents: priceCents,
      urgency: _urgency,
      lat: _selectedLocation.latitude,
      lon: _selectedLocation.longitude,
      addressData: addressData,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Task creata con successo!'), backgroundColor: Colors.green.shade600),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createTaskControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Crea Richiesta', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade600),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
                // Header
                Text('Descrivi la tua richiesta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                const SizedBox(height: 8),
                Text('Trova un helper in pochi minuti', style: TextStyle(color: Colors.teal.shade500)),
                const SizedBox(height: 24),
                
                // ═══════════════════════════════════════════════════════════
                // TASK DETAILS
                // ═══════════════════════════════════════════════════════════
                _buildSectionHeader('Dettagli Task', Icons.assignment_outlined),
                const SizedBox(height: 16),
                _buildCard(
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Titolo',
                      hint: 'Es: Riparare rubinetto cucina',
                      icon: Icons.title,
                      validator: (v) => v == null || v.isEmpty ? 'Inserisci un titolo' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descController,
                      label: 'Descrizione',
                      hint: 'Descrivi cosa deve essere fatto...',
                      icon: Icons.description,
                      maxLines: 4,
                      validator: (v) => v == null || v.isEmpty ? 'Inserisci una descrizione' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final categoriesAsync = ref.watch(categoriesProvider);
                                return categoriesAsync.when(
                                  data: (categories) {
                                    final categoryNames = categories.map((c) => c.displayName).toList();
                                    if (categoryNames.isEmpty) return const SizedBox(); // Handle empty
                                    
                                    // Reset if current selection not in list
                                    if (!categoryNames.contains(_category) && categoryNames.isNotEmpty) {
                                      // Defer state update to avoid build error, or just let user pick
                                      // Ideally we set it to first item but safe to leave as is if backend matches
                                    }

                                    return _buildDropdown(
                                      label: 'Categoria',
                                      value: categoryNames.contains(_category) ? _category : categoryNames.first,
                                      items: categoryNames,
                                      onChanged: (v) => setState(() => _category = v!),
                                    );
                                  },
                                  loading: () => const LinearProgressIndicator(),
                                  error: (_, __) => const Text('Errore caricamento'),
                                );
                              },
                            ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Urgenza',
                            value: _urgency,
                            items: ['low', 'medium', 'high'],
                            itemLabels: {'low': 'Bassa', 'medium': 'Media', 'high': 'Alta'},
                            onChanged: (v) => setState(() => _urgency = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Budget',
                      hint: '0.00',
                      icon: Icons.euro,
                      prefixText: '€ ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Richiesto';
                        if (double.tryParse(v) == null) return 'Numero non valido';
                        return null;
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // ═══════════════════════════════════════════════════════════
                // LOCATION
                // ═══════════════════════════════════════════════════════════
                _buildSectionHeader('Posizione', Icons.location_on_outlined),
                const SizedBox(height: 16),
                
                // Toggle Map/Address
                _buildCard(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton(
                            label: 'Mappa',
                            icon: Icons.map,
                            selected: _useMapPicker,
                            onTap: () => setState(() => _useMapPicker = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildToggleButton(
                            label: 'Indirizzo',
                            icon: Icons.home,
                            selected: !_useMapPicker,
                            onTap: () => setState(() => _useMapPicker = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_useMapPicker) ...[
                      // Map Picker
                      Row(
                        children: [
                          Expanded(
                            child: Text('Tocca la mappa per posizionare', style: TextStyle(fontSize: 12, color: Colors.teal.shade500)),
                          ),
                          TextButton.icon(
                            onPressed: _fetchLocation,
                            icon: Icon(Icons.my_location, size: 18, color: Colors.teal.shade600),
                            label: Text('Posizione attuale', style: TextStyle(color: Colors.teal.shade600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _selectedLocation,
                              initialZoom: 15.0,
                              onTap: (pos, latlng) => setState(() => _selectedLocation = latlng),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.taskmate.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation,
                                    width: 50,
                                    height: 50,
                                    child: Icon(Icons.location_on, color: Colors.teal.shade600, size: 50),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Address Form
                      _buildTextField(
                        controller: _streetController,
                        label: 'Via *',
                        hint: 'Es: Via Roma',
                        icon: Icons.route,
                        validator: (v) => v == null || v.isEmpty ? 'Richiesto' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: _buildTextField(
                              controller: _streetNumberController,
                              label: 'Civico *',
                              hint: '123',
                              validator: (v) => v == null || v.isEmpty ? 'Richiesto' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'Città *',
                              hint: 'Roma',
                              validator: (v) => v == null || v.isEmpty ? 'Richiesto' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _postalCodeController,
                              label: 'CAP',
                              hint: '00100',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _provinceController,
                              label: 'Provincia',
                              hint: 'RM',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _addressExtraController,
                        label: 'Scala / Piano / Interno',
                        hint: 'Es: Scala B, Piano 3, Int. 12',
                        icon: Icons.apartment,
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // ═══════════════════════════════════════════════════════════
                // ACCESS NOTES (helper-only)
                // ═══════════════════════════════════════════════════════════
                _buildSectionHeader('Note per l\'Helper', Icons.info_outline),
                const SizedBox(height: 16),
                _buildCard(
                  children: [
                    Text(
                      '⚠️ Visibile solo all\'helper assegnato dopo conferma',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _accessNotesController,
                      label: 'Istruzioni Accesso',
                      hint: 'Es: Citofono "Rossi", entrata laterale, codice cancello 1234',
                      icon: Icons.vpn_key_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('PUBBLICA RICHIESTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal.shade600),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: icon != null ? Icon(icon, color: Colors.teal.shade400) : null,
        labelStyle: TextStyle(color: Colors.teal.shade600),
        hintStyle: TextStyle(color: Colors.teal.shade300),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal.shade400, width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    Map<String, String>? itemLabels,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.teal.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal.shade400, width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(itemLabels?[item] ?? item),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Colors.teal.shade400 : Colors.teal.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? Colors.teal.shade700 : Colors.teal.shade400),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.teal.shade700 : Colors.teal.shade500,
            )),
          ],
        ),
      ),
    );
  }
}
