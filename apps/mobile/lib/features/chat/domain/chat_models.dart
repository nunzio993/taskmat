import '../../home/domain/task.dart';

class ChatThread {
  final int id;
  final int taskId;
  final int clientId;
  final int helperId;
  final DateTime createdAt;
  final List<TaskMessage> messages;
  
  // Helper details for display
  final String? helperName;
  final String? helperAvatarUrl;
  final double? helperRating;
  final int? helperReviewCount;

  ChatThread({
    required this.id,
    required this.taskId,
    required this.clientId,
    required this.helperId,
    required this.createdAt,
    this.messages = const [],
    this.helperName,
    this.helperAvatarUrl,
    this.helperRating,
    this.helperReviewCount,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'],
      taskId: json['task_id'],
      clientId: json['client_id'],
      helperId: json['helper_id'],
      createdAt: DateTime.parse(json['created_at']),
      messages: (json['messages'] as List?)?.map((e) => TaskMessage.fromJson(e)).toList() ?? [],
      helperName: json['helper_name'],
      helperAvatarUrl: json['helper_avatar_url'],
      helperRating: (json['helper_rating'] as num?)?.toDouble(),
      helperReviewCount: json['helper_review_count'],
    );
  }
}
