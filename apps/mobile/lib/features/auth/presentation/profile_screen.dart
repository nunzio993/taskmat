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
    if (session == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          actions: [
             IconButton(icon: const Icon(Icons.support_agent), onPressed: () {}, tooltip: 'Support'),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ProfileSummaryCard(
                session: session,
                onEdit: () {},
                onLogout: () => ref.read(authProvider.notifier).logout(),
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: EdgeInsets.symmetric(horizontal: 20),
              tabs: [
                Tab(text: 'Public'),
                Tab(text: 'Private'),
                Tab(text: 'Payments'),
                Tab(text: 'Security'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  PublicTab(),
                  PrivateTab(),
                  PaymentsTab(),
                  SecurityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

