import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain/task.dart';
import '../../../application/task_service.dart';
import '../../../../auth/application/auth_provider.dart';
import 'clarification_chat.dart';
import 'task_location_map.dart';

class HelperDetailPane extends ConsumerStatefulWidget {
  final Task task;
  final LatLng? userLocation;

  const HelperDetailPane({super.key, required this.task, this.userLocation});

  @override
  ConsumerState<HelperDetailPane> createState() => _HelperDetailPaneState();
}

class _HelperDetailPaneState extends ConsumerState<HelperDetailPane> {
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isMakingOffer = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with task price as suggested offer
    _priceCtrl.text = (widget.task.priceCents / 100).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
  
  // Basic validation check
  bool get _canOffer {
    final session = ref.read(authProvider).value;
    if (session == null || session.role != 'helper') return false;
    return widget.task.status == 'posted';
  }

  Future<void> _sendOffer() async {
    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Inserisci un prezzo valido'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }
    
    setState(() => _isMakingOffer = true);
    
    try {
      final priceCents = (price * 100).round();
      await ref.read(taskServiceProvider.notifier).createOffer(
        widget.task.id,
        priceCents,
        _noteCtrl.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Offerta inviata!'),
            backgroundColor: Colors.teal.shade600,
          ),
        );
        _noteCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMakingOffer = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     final task = widget.task;
     final isAvailable = task.status == 'posted';

     return Container(
       color: Colors.grey.shade50,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
            // Header
            _buildHeader(context, task),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unavailable Banner
                    if (!isAvailable)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                             Icon(Icons.lock, color: Colors.red.shade600),
                             const SizedBox(width: 12),
                             Expanded(
                               child: Text(
                                 "Questa task non è più disponibile.",
                                 style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                               ),
                             ),
                          ],
                        ),
                      ),
                      
                    // Description Card
                    _buildSectionCard(
                      title: 'Descrizione',
                      icon: Icons.description_outlined,
                      child: Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location Map
                    _buildSectionCard(
                      title: 'Posizione',
                      icon: Icons.location_on_outlined,
                      child: TaskLocationMapWidget(task: task),
                    ),
                    const SizedBox(height: 20),
                    
                    // Chat Section
                    _buildSectionCard(
                      title: 'Chiedi chiarimenti',
                      icon: Icons.chat_outlined,
                      headerAction: !isAvailable ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DISABILITATO',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ) : null,
                      child: ClarificationChatWidget(
                        task: task,
                        isEnabled: isAvailable,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Offer Section
                    _buildOfferSection(isAvailable),
                  ],
                ),
              ),
            ),
         ],
       ),
     );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? headerAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.teal.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.teal.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (headerAction != null) ...[
                  const Spacer(),
                  headerAction,
                ],
              ],
            ),
          ),
          Divider(height: 1, color: Colors.teal.shade50),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferSection(bool isAvailable) {
    final session = ref.watch(authProvider).value;
    final helperId = session?.id;
    
    // Check if helper already has an offer on this task
    TaskOffer? myOffer;
    if (helperId != null && widget.task.offers.isNotEmpty) {
      final found = widget.task.offers.where((o) => o.helperId == helperId);
      if (found.isNotEmpty) {
        myOffer = found.first;
      }
    }
    
    return Column(
      children: [
        // Show existing offer if present
        if (myOffer != null)
          _buildExistingOfferCard(myOffer),
        
        // Show offer form only if no offer yet and task is posted
        if (myOffer == null)
          _buildNewOfferForm(isAvailable),
      ],
    );
  }
  
  Widget _buildExistingOfferCard(TaskOffer offer) {
    MaterialColor statusColor;
    String statusLabel;
    IconData statusIcon;
    
    switch (offer.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'IN ATTESA';
        statusIcon = Icons.hourglass_top;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusLabel = 'ACCETTATA';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'RIFIUTATA';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = offer.status.toUpperCase();
        statusIcon = Icons.info;
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.shade50, statusColor.shade100.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.shade600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'La tua offerta',
                      style: TextStyle(
                        color: statusColor.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€${(offer.priceCents / 100).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: statusColor.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  if (offer.priceCents != widget.task.priceCents)
                    Text(
                      'Prezzo cliente: €${(widget.task.priceCents / 100).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: statusColor.shade500,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (offer.message.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer.message,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ),
          ],
          // Show retract button only for pending offers
          if (offer.status.toLowerCase() == 'pending') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement retract offer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funzione ritira offerta non ancora implementata')),
                  );
                },
                icon: const Icon(Icons.undo),
                label: const Text('Ritira offerta'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: statusColor.shade700,
                  side: BorderSide(color: statusColor.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildNewOfferForm(bool isAvailable) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.teal.shade100.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_offer, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offri il tuo aiuto!',
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Prezzo cliente: €${(widget.task.priceCents / 100).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.teal.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Accept at client price button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: isAvailable && !_isMakingOffer ? _acceptAtClientPrice : null,
              icon: const Icon(Icons.check_circle),
              label: Text('Accetta a €${(widget.task.priceCents / 100).toStringAsFixed(0)}'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.teal.shade200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('oppure', style: TextStyle(color: Colors.teal.shade500, fontSize: 12)),
              ),
              Expanded(child: Divider(color: Colors.teal.shade200)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Price Input
          TextField(
            controller: _priceCtrl,
            decoration: InputDecoration(
              labelText: 'Proponi un prezzo diverso',
              labelStyle: TextStyle(color: Colors.teal.shade600),
              prefixIcon: Icon(Icons.euro, color: Colors.teal.shade500),
              prefixText: '€ ',
              prefixStyle: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.teal.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.teal.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.teal.shade500, width: 2)),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: isAvailable,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          
          // Note Input
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Nota (opzionale)',
              labelStyle: TextStyle(color: Colors.teal.shade600),
              hintText: 'Posso aiutarti perché...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.teal.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.teal.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.teal.shade500, width: 2)),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            maxLines: 2,
            enabled: isAvailable,
          ),
          const SizedBox(height: 16),
          
          // Send Offer Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAvailable && !_isMakingOffer ? _sendOffer : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isMakingOffer 
                ? SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.teal.shade100),
                    ),
                  )
                : const Text('Invia offerta personalizzata', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _acceptAtClientPrice() async {
    setState(() => _isMakingOffer = true);
    
    try {
      await ref.read(taskServiceProvider.notifier).createOffer(
        widget.task.id,
        widget.task.priceCents,
        'Accetto al prezzo proposto',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Offerta inviata! Il cliente riceverà la tua proposta.'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMakingOffer = false);
      }
    }
  }
  
  Widget _buildHeader(BuildContext context, Task task) {
    return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: Colors.white,
         border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
         boxShadow: [
           BoxShadow(
             color: Colors.teal.withOpacity(0.05),
             blurRadius: 6,
             offset: const Offset(0, 2),
           ),
         ],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              children: [
                 // Client Info
                 Container(
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.teal.shade200, width: 2),
                   ),
                   child: CircleAvatar(
                     radius: 22,
                     backgroundColor: Colors.teal.shade50,
                     backgroundImage: task.client?.avatarUrl != null ? NetworkImage(task.client!.avatarUrl!) : null,
                     child: task.client?.avatarUrl == null 
                       ? Text(
                           task.client?.displayName.isNotEmpty == true ? task.client!.displayName[0] : '?',
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                         ) 
                       : null,
                   ),
                 ),
                 const SizedBox(width: 12),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Text(
                           task.client?.displayName ?? 'Cliente',
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                         ),
                         const SizedBox(width: 8),
                         Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                         Text(
                           task.client?.avgRating.toStringAsFixed(1) ?? 'N/A',
                           style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                         ),
                       ],
                     ),
                     Text(
                       'Pubblicato ${timeago.format(task.createdAt, locale: 'it')}',
                       style: TextStyle(color: Colors.teal.shade500, fontSize: 12),
                     ),
                   ],
                 ),
                 const Spacer(),
                 // Status Badge
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: task.status == 'posted' ? Colors.teal.shade50 : Colors.grey.shade100,
                     borderRadius: BorderRadius.circular(20),
                     border: Border.all(
                       color: task.status == 'posted' ? Colors.teal.shade400 : Colors.grey.shade300,
                     ),
                   ),
                   child: Text(
                     task.status == 'posted' ? 'DISPONIBILE' : task.status.toUpperCase(),
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 11,
                       color: task.status == 'posted' ? Colors.teal.shade700 : Colors.grey.shade600,
                     ),
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildChip(context, task.category, Icons.work_outline),
                if (widget.userLocation != null) ...[
                   const SizedBox(width: 8),
                   _buildChip(
                     context,
                     "${const Distance().as(LengthUnit.Kilometer, widget.userLocation!, LatLng(task.lat, task.lon)).toStringAsFixed(1)} km",
                     Icons.location_on,
                   ),
                ],
                const SizedBox(width: 8),
                // Price badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '€${(task.priceCents / 100).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            )
         ],
       ),
    );
  }
  
  Widget _buildChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(icon, size: 14, color: Colors.teal.shade600),
           const SizedBox(width: 4),
           Text(
             label,
             style: TextStyle(
               color: Colors.teal.shade700,
               fontSize: 12,
               fontWeight: FontWeight.w500,
             ),
           ),
        ],
      ),
    );
  }
}
