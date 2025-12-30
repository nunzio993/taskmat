import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/task.dart';

class TaskLocationMapWidget extends StatelessWidget {
  final Task task;

  const TaskLocationMapWidget({super.key, required this.task});

  void _openFullScreenMap(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Task Location'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(task.lat, task.lon),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(task.lat, task.lon),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text('Location', style: Theme.of(context).textTheme.titleMedium),
             TextButton.icon(
               onPressed: () => _openFullScreenMap(context), 
               icon: const Icon(Icons.fullscreen), 
               label: const Text('Expand'),
               style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
             ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openFullScreenMap(context),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                   FlutterMap(
                     options: MapOptions(
                       initialCenter: LatLng(task.lat, task.lon),
                       initialZoom: 14.0,
                       interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Disable interaction
                     ),
                     children: [
                       TileLayer(
                         urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                         userAgentPackageName: 'com.example.app',
                       ),
                       MarkerLayer(
                         markers: [
                           Marker(
                             point: LatLng(task.lat, task.lon),
                             width: 40,
                             height: 40,
                             child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                           ),
                         ],
                       ),
                     ],
                   ),
                   // Overlay to ensure tap is caught if map eats it (though InteractiveFlag.none should suffice)
                   Positioned.fill(
                     child: Container(color: Colors.transparent), 
                   ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
