import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

part 'helper_service.g.dart';

class UserDocument {
  final int id;
  final String type;
  final String fileUrl;
  final String status;
  final String? rejectionReason;

  UserDocument({
    required this.id,
    required this.type,
    required this.fileUrl,
    required this.status,
    this.rejectionReason,
  });

  factory UserDocument.fromJson(Map<String, dynamic> json) {
    return UserDocument(
      id: json['id'],
      type: json['type'],
      fileUrl: json['file_url'],
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
    );
  }
}

@riverpod
class HelperService extends _$HelperService {
  @override
  FutureOr<void> build() {}

  Future<List<UserDocument>> getDocuments() async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/helper/documents');
    return (response.data as List).map((e) => UserDocument.fromJson(e)).toList();
  }

  Future<UserDocument> uploadDocument(String filePath, String type) async {
    final dio = ref.read(apiClientProvider);
    // MOCK UPLOAD: We just send the path as the URL for now
    // In real app, we would upload to S3 first, then send the URL
    final response = await dio.post('/helper/documents', data: {
      'file_url': 'mock_s3_url_${DateTime.now().millisecondsSinceEpoch}.jpg', 
      'type': type
    });
    return UserDocument.fromJson(response.data);
  }

  Future<void> updateProfile({
    List<String>? skills,
    double? hourlyRate,
    String? bio,
    bool? isAvailable,
  }) async {
    final dio = ref.read(apiClientProvider);
    final data = <String, dynamic>{};
    if (skills != null) data['skills'] = skills;
    if (hourlyRate != null) data['hourly_rate'] = hourlyRate;
    if (bio != null) data['bio'] = bio;
    if (isAvailable != null) data['is_available'] = isAvailable;

    await dio.patch('/helper/profile', data: data);
  }

  Future<void> verify() async {
    final dio = ref.read(apiClientProvider);
    await dio.post('/helper/verify');
  }
}
