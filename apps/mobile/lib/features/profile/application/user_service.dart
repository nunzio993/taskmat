import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api_client.dart';

part 'user_service.g.dart';

// Models
class Address {
  final int id;
  final String name;
  final String addressLine;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.addressLine,
    required this.city,
    required this.postalCode,
    this.country = "IT",
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      name: json['name'],
      addressLine: json['address_line'],
      city: json['city'],
      postalCode: json['postal_code'],
      country: json['country'] ?? 'IT',
      isDefault: json['is_default'] ?? false,
    );
  }
}

class PaymentMethod {
  final int id;
  final String cardBrand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;
  final String providerTokenId;

  PaymentMethod({
    required this.id,
    required this.cardBrand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
    required this.providerTokenId,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      cardBrand: json['card_brand'],
      last4: json['last4'],
      expMonth: json['exp_month'],
      expYear: json['exp_year'],
      isDefault: json['is_default'] ?? false,
      providerTokenId: json['provider_token_id'],
    );
  }
}


class PublicUserStats {
  final int tasksCompleted;
  final int reviewsCount;
  final double averageRating;
  final String cancelRateLabel;

  PublicUserStats({
    required this.tasksCompleted,
    required this.reviewsCount,
    required this.averageRating,
    required this.cancelRateLabel,
  });

  factory PublicUserStats.fromJson(Map<String, dynamic> json) {
    return PublicUserStats(
      tasksCompleted: json['tasks_completed'] ?? 0,
      reviewsCount: json['reviews_count'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      cancelRateLabel: json['cancel_rate_label'] ?? 'Unknown',
    );
  }
}

class PublicUser {
  final int id;
  final String? name;
  final String role;
  final String? bio;
  final List<String> languages;
  final double? hourlyRate;
  final List<String> skills;
  final PublicUserStats stats;

  PublicUser({
    required this.id,
    this.name,
    required this.role,
    this.bio,
    this.languages = const [],
    this.hourlyRate,
    this.skills = const [],
    required this.stats,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      bio: json['bio'],
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      stats: PublicUserStats.fromJson(json['stats'] ?? {}),
    );
  }
}

class PublicReview {
  final int id;
  final String fromUserName;
  final int stars;
  final String? comment;
  final DateTime createdAt;

  PublicReview({
    required this.id,
    required this.fromUserName,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  factory PublicReview.fromJson(Map<String, dynamic> json) {
    return PublicReview(
      id: json['id'],
      fromUserName: json['from_user_name'],
      stars: json['stars'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}


@riverpod
class UserService extends _$UserService {
  @override
  FutureOr<void> build() {}

  Future<List<Address>> getAddresses() async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/profile/addresses');
    return (response.data as List).map((e) => Address.fromJson(e)).toList();
  }

  Future<Address> addAddress(Map<String, dynamic> data) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.post('/profile/addresses', data: data);
    return Address.fromJson(response.data);
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/profile/payment-methods');
    return (response.data as List).map((e) => PaymentMethod.fromJson(e)).toList();
  }

  Future<PaymentMethod> addPaymentMethod(Map<String, dynamic> data) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.post('/profile/payment-methods', data: data);
    return PaymentMethod.fromJson(response.data);
  }

  Future<PublicUser> getPublicProfile(int userId) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/users/$userId/public');
    return PublicUser.fromJson(response.data);
  }

  Future<List<PublicReview>> getPublicReviews(int userId, {int page = 1, int size = 10}) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/users/$userId/reviews', queryParameters: {'page': page, 'size': size});
    // Response is { items: [], total: ... }
    final items = response.data['items'] as List;
    return items.map((e) => PublicReview.fromJson(e)).toList();
  }

  // Review System Methods
  
  Future<ReviewStatus> getTaskReviewStatus(int taskId) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/tasks/$taskId/reviews/status');
    return ReviewStatus.fromJson(response.data);
  }

  Future<void> submitReview(int taskId, {required int stars, String? comment, List<String>? tags}) async {
    final dio = ref.read(apiClientProvider);
    await dio.post('/tasks/$taskId/reviews', data: {
      'stars': stars,
      if (comment != null) 'comment': comment,
      if (tags != null) 'tags': tags,
    });
  }

  Future<void> updateReview(int taskId, {String? comment, List<String>? tags}) async {
    final dio = ref.read(apiClientProvider);
    await dio.patch('/tasks/$taskId/reviews/me', data: {
      if (comment != null) 'comment': comment,
      if (tags != null) 'tags': tags,
    });
  }

  /// Upload a profile avatar image
  Future<Map<String, dynamic>> uploadAvatar(XFile image) async {
    final dio = ref.read(apiClientProvider);
    
    final bytes = await image.readAsBytes();
    final fileName = image.name.isNotEmpty ? image.name : 'avatar.jpg';
    
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      ),
    });
    
    final response = await dio.post('/profile/avatar', data: formData);
    return response.data;
  }
}

@riverpod
Future<ReviewStatus> taskReviewStatus(Ref ref, int taskId) {
  return ref.read(userServiceProvider.notifier).getTaskReviewStatus(taskId);
}

// Review Status Model
class ReviewStatus {
  final int taskId;
  final String taskStatus;
  final bool canReview;
  final bool hasReviewed;
  final bool otherReviewed;
  final bool reviewsVisible;
  final bool editAllowed;
  final ReviewData? myReview;
  final ReviewData? otherReview;

  ReviewStatus({
    required this.taskId,
    required this.taskStatus,
    required this.canReview,
    required this.hasReviewed,
    required this.otherReviewed,
    required this.reviewsVisible,
    required this.editAllowed,
    this.myReview,
    this.otherReview,
  });

  factory ReviewStatus.fromJson(Map<String, dynamic> json) {
    return ReviewStatus(
      taskId: json['task_id'],
      taskStatus: json['task_status'],
      canReview: json['can_review'] ?? false,
      hasReviewed: json['has_reviewed'] ?? false,
      otherReviewed: json['other_reviewed'] ?? false,
      reviewsVisible: json['reviews_visible'] ?? false,
      editAllowed: json['edit_allowed'] ?? false,
      myReview: json['my_review'] != null ? ReviewData.fromJson(json['my_review']) : null,
      otherReview: json['other_review'] != null ? ReviewData.fromJson(json['other_review']) : null,
    );
  }
}

class ReviewData {
  final int id;
  final int stars;
  final String? comment;
  final List<String> tags;
  final String fromRole;
  final String? fromUserName;
  final DateTime createdAt;

  ReviewData({
    required this.id,
    required this.stars,
    this.comment,
    required this.tags,
    required this.fromRole,
    this.fromUserName,
    required this.createdAt,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    return ReviewData(
      id: json['id'],
      stars: json['stars'],
      comment: json['comment'],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      fromRole: json['from_role'],
      fromUserName: json['from_user_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Provider to fetch user stats by ID
@riverpod
Future<PublicUserStats?> userStats(Ref ref, int userId) async {
  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/users/$userId/public');
    final data = response.data;
    if (data['stats'] != null) {
      return PublicUserStats.fromJson(data['stats']);
    }
    return null;
  } catch (e) {
    return null;
  }
}

