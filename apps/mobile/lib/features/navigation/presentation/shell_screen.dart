
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_provider.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value;
    final navItems = _buildNavItems(session?.role);
    final selectedIndex = _calculateSelectedIndex(context, session?.role);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 640) {
            // Wide screen: Show NavigationRail
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (idx) => _onItemTapped(idx, context, session?.role),
                  labelType: NavigationRailLabelType.all,
                  destinations: navItems.map((item) => NavigationRailDestination(
                    icon: item.icon,
                    selectedIcon: item.selectedIcon,
                    label: Text(item.label),
                  )).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            );
          }
          // Mobile: Show content directly, BottomBar handles nav below
          return child;
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width > 640 
          ? null 
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context, session?.role),
              destinations: navItems,
            ),
    );
  }

  List<NavigationDestination> _buildNavItems(String? role) {
    if (role == 'helper') {
      return const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Find Work'),
        NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'My Jobs'),
        NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt), label: 'My Tasks'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Preferences'),
      ];
    }
    // Client (Default)
    return const [
      NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'My Tasks'),
      NavigationDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake), label: 'Be Helper'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Preferences'),
    ];
  }

  int _calculateSelectedIndex(BuildContext context, String? role) {
    final String location = GoRouterState.of(context).matchedLocation;
    
    if (role == 'helper') {
      // Helper: Home(0), Find Work(1), My Jobs(2), My Tasks(3), Profile(4), Preferences(5)
      if (location.startsWith('/home')) return 0;
      if (location.startsWith('/find-work')) return 1;
      if (location.startsWith('/my-jobs')) return 2;
      if (location.startsWith('/my-tasks')) return 3;
      if (location.startsWith('/profile')) return 4;
      if (location.startsWith('/preferences')) return 5;
      return 0;
    }
    
    // Client: Home(0), My Tasks(1), Become Helper(2), Profile(3), Preferences(4)
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/my-tasks')) return 1;
    if (location.startsWith('/register-helper')) return 2;
    if (location.startsWith('/profile')) return 3;
    if (location.startsWith('/preferences')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, String? role) {
    if (role == 'helper') {
      // Helper: Home(0), Find Work(1), My Jobs(2), My Tasks(3), Profile(4), Preferences(5)
      switch (index) {
        case 0: context.go('/home'); break;
        case 1: context.go('/find-work'); break;
        case 2: context.go('/my-jobs'); break;
        case 3: context.go('/my-tasks'); break;
        case 4: context.go('/profile'); break;
        case 5: context.go('/preferences'); break;
      }
    } else {
      // Client: Home(0), My Tasks(1), Become Helper(2), Profile(3), Preferences(4)
      switch (index) {
        case 0: context.go('/home'); break;
        case 1: context.go('/my-tasks'); break;
        case 2: context.go('/register-helper'); break;
        case 3: context.go('/profile'); break;
        case 4: context.go('/preferences'); break;
      }
    }
  }
}
