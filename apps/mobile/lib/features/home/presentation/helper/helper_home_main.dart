import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tasks_provider.dart';
import 'widgets/status_header_section.dart';
import 'widgets/helper_kpis_section.dart';
import 'widgets/active_jobs_section.dart';
import 'widgets/inbox_preview_section.dart';
import 'widgets/opportunities_preview_section.dart';

/// Helper Dashboard - Main home view for helpers
/// Shows operational overview without duplicating Find Work
class HelperHomeMain extends ConsumerWidget {
  const HelperHomeMain({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: Colors.teal.shade600,
      onRefresh: () async {
        ref.invalidate(myAssignedTasksProvider);
        ref.invalidate(helperEarningsProvider);
        ref.invalidate(helperRecentThreadsProvider);
        ref.invalidate(nearbyTasksProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            StatusHeaderSection(),
            SizedBox(height: 20),
            HelperKpisSection(),
            SizedBox(height: 24),
            ActiveJobsSection(),
            SizedBox(height: 24),
            InboxPreviewSection(),
            SizedBox(height: 24),
            OpportunitiesPreviewSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
