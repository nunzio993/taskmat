import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../profile/application/user_service.dart';
import '../../../../reviews/presentation/review_dialog.dart';
import '../../../domain/task.dart';
import '../../../application/tasks_provider.dart';

/// Widget that displays review status and action button for a completed task
class TaskReviewButton extends ConsumerWidget {
  final Task task;

  const TaskReviewButton({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show for completed tasks
    if (task.status != 'completed') {
      return const SizedBox.shrink();
    }

    return FutureBuilder<ReviewStatus>(
      future: ref.read(userServiceProvider.notifier).getTaskReviewStatus(task.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingButton();
        }

        if (snapshot.hasError) {
          // On error, show the review button anyway (fallback)
          print('Review status error: ${snapshot.error}');
          return _buildReviewButton(context, ref);
        }

        final status = snapshot.data;
        if (status == null) {
          // No data, show button as fallback
          return _buildReviewButton(context, ref);
        }

        if (status.hasReviewed) {
          // Already reviewed
          return _buildReviewedBadge(context, status);
        }

        if (status.canReview) {
          // Can leave a review
          return _buildReviewButton(context, ref);
        }

        // Can't review (task not completed?)
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildReviewedBadge(BuildContext context, ReviewStatus status) {
    final myReview = status.myReview;
    final stars = myReview?.stars ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(stars, (i) => 
            Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600)
          ),
          if (status.reviewsVisible)
            Icon(Icons.check_circle, size: 14, color: Colors.green.shade400)
          else
            Tooltip(
              message: 'In attesa della recensione dell\'altra parte',
              child: Icon(Icons.hourglass_empty, size: 14, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.amber.shade500,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (_) => ReviewDialog(
              taskId: task.id,
              targetUserName: task.assignedHelperName ?? 'Helper',
              isReviewingAsClient: true,
            ),
          );

          if (result == true) {
            // Trigger refresh
            ref.invalidate(myCreatedTasksProvider);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_outline_rounded, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'Recensisci',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
