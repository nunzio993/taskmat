
class Task {
  final int id;
  final String title;
  final String description;
  final int priceCents;
  final double lat;
  final double lon;
  final String status;
  final String category;
  final String urgency;
  final DateTime createdAt;
  final int? clientId;
  final UserProfile? client;
  final int? selectedOfferId;
  final int version;
  final List<TaskProof> proofs;
  final List<TaskOffer> offers;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.lat,
    required this.lon,
    required this.status,
    required this.category,
    required this.urgency,
    required this.createdAt,
    this.clientId,
    this.client,
    this.selectedOfferId,
    this.version = 1,
    this.proofs = const [],
    this.offers = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      priceCents: json['price_cents'],
      lat: json['lat'],
      lon: json['lon'],
      status: json['status'],
      category: json['category'] ?? 'General',
      urgency: json['urgency'] ?? 'medium',
      createdAt: DateTime.parse(json['created_at']),
      clientId: json['client_id'],
      client: json['client'] != null ? UserProfile.fromJson(json['client']) : null,
      selectedOfferId: json['selected_offer_id'],
      version: json['version'] ?? 1,
      proofs: (json['proofs'] as List?)?.map((e) => TaskProof.fromJson(e)).toList() ?? [],
      offers: (json['offers'] as List?)?.map((e) => TaskOffer.fromJson(e)).toList() ?? [],
    );
  }
}

class UserProfile {
  final int id;
  final String displayName;
  final String? avatarUrl;
  final double avgRating;
  final int reviewCount;

  UserProfile({
    required this.id, 
    required this.displayName, 
    this.avatarUrl, 
    required this.avgRating, 
    required this.reviewCount
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      displayName: json['display_name'] ?? 'User',
      avatarUrl: json['avatar_url'],
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
    );
  }
}

class TaskProof {
  final int id;
  final String kind;
  final String storageKey;
  final DateTime createdAt;

  TaskProof({required this.id, required this.kind, required this.storageKey, required this.createdAt});

  factory TaskProof.fromJson(Map<String, dynamic> json) {
    return TaskProof(
      id: json['id'],
      kind: json['kind'],
      storageKey: json['storage_key'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class TaskOffer {
  final int id;
  final int taskId;
  final int helperId;
  final int priceCents;
  final String message;
  final String status;
  final String? helperName;
  final String? helperAvatarUrl;
  final double? helperRating;

  TaskOffer({
    required this.id,
    required this.taskId,
    required this.helperId,
    required this.priceCents,
    required this.message,
    required this.status,
    this.helperName,
    this.helperAvatarUrl,
    this.helperRating,
  });

  factory TaskOffer.fromJson(Map<String, dynamic> json) {
    return TaskOffer(
      id: json['id'],
      taskId: json['task_id'],
      helperId: json['helper_id'],
      priceCents: json['price_cents'],
      message: json['message'] ?? '',
      status: json['status'],
      helperName: json['helper_name'], // Assuming flattened or need adjustment if nested
      helperAvatarUrl: json['helper_avatar_url'],
      helperRating: (json['helper_rating'] as num?)?.toDouble(),
    );
  }
}

class TaskMessage {
  final int id;
  final int senderId;
  final String body;
  final DateTime createdAt;
  final String type;
  final Map<String, dynamic> payload;

  TaskMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.type = 'text',
    this.payload = const {},
  });

  factory TaskMessage.fromJson(Map<String, dynamic> json) {
    return TaskMessage(
      id: json['id'],
      senderId: json['sender_id'],
      body: json['body'],
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'] ?? 'text',
      payload: json['payload'] ?? {},
    );
  }
}
