import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_provider.dart';
import '../../profile/presentation/widgets/profile_summary_card.dart';
import '../../profile/presentation/tabs/public_tab.dart';
import '../../profile/presentation/tabs/private_tab.dart';
import '../../profile/presentation/tabs/payments_tab.dart';
import '../../profile/presentation/tabs/security_tab.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value;
    if (session == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text('Il mio Profilo', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.teal.shade600),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Colors.teal.shade600),
              onPressed: () {},
              tooltip: 'Impostazioni',
            ),
          ],
        ),
        body: Column(
          children: [
            // Profile Header Card
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ProfileSummaryCard(
                  session: session,
                  onEdit: () {},
                  onLogout: () => ref.read(authProvider.notifier).logout(),
                ),
              ),
            ),
            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                labelColor: Colors.teal.shade700,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                indicatorColor: Colors.teal.shade600,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Pubblico'),
                  Tab(text: 'Privato'),
                  Tab(text: 'Pagamenti'),
                  Tab(text: 'Sicurezza'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: const TabBarView(
                  children: [
                    PublicTab(),
                    PrivateTab(),
                    PaymentsTab(),
                    SecurityTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
