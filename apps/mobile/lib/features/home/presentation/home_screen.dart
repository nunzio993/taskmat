import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_provider.dart';
import '../application/tasks_provider.dart';
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
    
    // Check if helper has active job (assigned/in_progress/in_confirmation)
    final hasActiveHelperJob = ref.watch(hasActiveHelperJobProvider).valueOrNull ?? false;
    
    // Determine which view to show
    final showHelperView = _manualModeOverride ?? (isHelper && hasActiveHelperJob);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.task_alt, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('TaskMate'),
          ],
        ),
        actions: [
          // Mode toggle (only show if user is helper or has potential to be)
          if (isHelper || session != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildModeToggle(showHelperView, isHelper),
            ),
        ],
      ),
      body: showHelperView 
        ? const HelperHomeMain()
        : const ClientHomeMain(),
    );
  }

  Widget _buildModeToggle(bool showHelperView, bool isHelper) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
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
            onTap: isHelper 
              ? () => setState(() => _manualModeOverride = true)
              : null, // Disabled if not helper
            enabled: isHelper,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
              ? Theme.of(context).colorScheme.onPrimary
              : enabled 
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
