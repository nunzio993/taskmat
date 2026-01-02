import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_provider.dart';
import 'client/client_home_main.dart';
import 'helper/helper_home_main.dart';

/// HomeScreen with automatic routing and manual toggle between Client/Helper modes
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool? _manualModeOverride; // null = auto, true = helper, false = client

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).valueOrNull;
    final isHelper = session?.role == 'helper';
    
    // Default: show helper view if user is a helper, client view otherwise
    // User can manually override via toggle
    final showHelperView = _manualModeOverride ?? isHelper;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.task_alt, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            const Text('TaskMate'),
          ],
        ),
        actions: [
          // Mode toggle (only show for helpers who can switch between modes)
          if (isHelper)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildModeToggle(showHelperView),
            ),
        ],
      ),
      body: showHelperView 
        ? const HelperHomeMain()
        : const ClientHomeMain(),
    );
  }

  Widget _buildModeToggle(bool showHelperView) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: 'Cliente',
            isSelected: !showHelperView,
            onTap: () => setState(() => _manualModeOverride = false),
          ),
          const SizedBox(width: 4),
          _buildToggleButton(
            label: 'Helper',
            isSelected: showHelperView,
            onTap: () => setState(() => _manualModeOverride = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? Colors.teal.shade600
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
              ? Colors.white
              : Colors.teal.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
