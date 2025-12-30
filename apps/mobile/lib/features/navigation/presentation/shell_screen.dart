
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
    final selectedIndex = _calculateSelectedIndex(context);

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
                    label: Text(item.label!),
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
          : BottomNavigationBar(
              items: navItems,
              currentIndex: selectedIndex,
              onTap: (idx) => _onItemTapped(idx, context, session?.role),
              type: BottomNavigationBarType.fixed,
            ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(String? role) {
    if (role == 'helper') {
      return const [
        // Helpers see Dashboard/Home too
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
        // Helpers can also be clients, so they need 'My Tasks'
        BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'My Tasks'),
        // Helper specific work view (replaces 'Become Helper')
        BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Jobs'),
        // Profile
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }
    // Client (Default)
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'My Tasks'),
      BottomNavigationBarItem(icon: Icon(Icons.handshake_outlined), activeIcon: Icon(Icons.handshake), label: 'Become Helper'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    
    // Index 1: My Tasks (Client View - for everyone)
    if (location.startsWith('/my-tasks')) return 1;
    
    // Index 2: Helper Actions (Jobs for Helper, Register for Client)
    if (location.startsWith('/my-jobs')) return 2;
    if (location.startsWith('/register-helper')) return 2;
    
    // Index 3: Profile
    if (location.startsWith('/profile')) return 3;
    
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, String? role) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        // Everyone goes to My Tasks (Client view)
        context.go('/my-tasks');
        break;
      case 2:
        // Role specific action
        if (role == 'helper') {
          context.go('/my-jobs');
        } else {
          context.go('/register-helper');
        }
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
