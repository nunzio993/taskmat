
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:latlong2/latlong.dart';
import '../../features/home/domain/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final LatLng? userLocation;

  const TaskCard({super.key, required this.task, required this.onTap, this.userLocation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   if (task.client != null) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: task.client?.avatarUrl != null ? NetworkImage(task.client!.avatarUrl!) : null,
                        child: task.client?.avatarUrl == null 
                           ? Text(task.client?.displayName.isNotEmpty == true ? task.client!.displayName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 10)) 
                           : null,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          task.client?.displayName ?? 'User', 
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(task.client?.avgRating.toStringAsFixed(1) ?? '0.0', style: Theme.of(context).textTheme.labelSmall),
                      Text(' (${task.client?.reviewCount})', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
                   ],
                   const Spacer(),
                   _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForCategory(task.category),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${task.category} • $_timeAgo',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPriceTag(context),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                 const SizedBox(height: 12),
                 Text(
                   task.description,
                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                     color: Theme.of(context).colorScheme.onSurface,
                   ),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
              ],
              if (_distanceString != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                         const SizedBox(width: 4),
                         Text(
                           _distanceString!,
                           style: Theme.of(context).textTheme.labelSmall?.copyWith(
                             color: Theme.of(context).colorScheme.primary,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                      ],
                    ),
                  )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceTag(BuildContext context) {
    return Text(
      '€${(task.priceCents / 100).toStringAsFixed(0)}',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color textColor;

    switch (task.status) {
      case 'posted':
        bgColor = isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50;
        textColor = Colors.blue;
        break;
      case 'locked':
      case 'assigned':
        bgColor = isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50;
        textColor = Colors.orange;
        break;
      case 'completed':
        bgColor = isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50;
        textColor = Colors.green;
        break;
      default:
        bgColor = isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade100;
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        task.status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'cleaning': return Icons.cleaning_services;
      case 'delivery': return Icons.local_shipping;
      case 'repair': return Icons.build;
      default: return Icons.work_outline;
    }
  }

  String get _timeAgo {
    return timeago.format(task.createdAt, allowFromNow: true);
  }

  String? get _distanceString {
    if (userLocation == null) return null;
    final distance = const Distance().as(LengthUnit.Kilometer, userLocation!, LatLng(task.lat, task.lon));
    if (distance < 1.0) {
       final meters = const Distance().as(LengthUnit.Meter, userLocation!, LatLng(task.lat, task.lon));
       return '${meters.toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
}
