import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell layout with sidebar navigation for authenticated users
class DashboardShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const DashboardShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.grey.shade900,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.handshake, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'TaskMat',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Navigation items
          _buildNavItem(context, '/dashboard', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
          _buildNavItem(context, '/tasks', 'I miei Task', Icons.assignment_outlined, Icons.assignment),
          _buildNavItem(context, '/create-task', 'Nuovo Task', Icons.add_circle_outline, Icons.add_circle),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Divider(color: Colors.grey),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('HELPER', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          
          _buildNavItem(context, '/find-work', 'Trova Lavoro', Icons.search_outlined, Icons.search),
          _buildNavItem(context, '/my-jobs', 'I miei Lavori', Icons.work_outline, Icons.work),
          
          const Spacer(),
          
          // Bottom items
          _buildNavItem(context, '/messages', 'Messaggi', Icons.chat_bubble_outline, Icons.chat_bubble),
          _buildNavItem(context, '/profile', 'Profilo', Icons.person_outline, Icons.person),
          _buildNavItem(context, '/settings', 'Impostazioni', Icons.settings_outlined, Icons.settings),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String route, String label, IconData icon, IconData activeIcon) {
    final isActive = currentRoute == route || currentRoute.startsWith(route);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isActive ? Colors.teal.shade600.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? Colors.teal.shade400 : Colors.grey.shade400,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade400,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Breadcrumb / Title
          Text(
            _getPageTitle(currentRoute),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const Spacer(),
          
          // Notifications
          IconButton(
            onPressed: () {},
            icon: Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_outlined, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          
          // User menu
          PopupMenuButton(
            offset: const Offset(0, 50),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal.shade600, size: 20),
                ),
                const SizedBox(width: 8),
                Text('Utente', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500, size: 20),
              ],
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Il mio profilo')),
              const PopupMenuItem(value: 'settings', child: Text('Impostazioni')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Esci')),
            ],
          ),
        ],
      ),
    );
  }

  String _getPageTitle(String route) {
    switch (route) {
      case '/dashboard': return 'Dashboard';
      case '/tasks': return 'I miei Task';
      case '/create-task': return 'Nuovo Task';
      case '/find-work': return 'Trova Lavoro';
      case '/my-jobs': return 'I miei Lavori';
      case '/messages': return 'Messaggi';
      case '/profile': return 'Profilo';
      case '/settings': return 'Impostazioni';
      default: return 'TaskMat';
    }
  }
}
