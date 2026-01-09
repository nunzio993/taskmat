import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';

/// Model for a category from the database
class Category {
  final String slug;
  final String displayName;

  Category({required this.slug, required this.displayName});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      slug: json['slug'],
      displayName: json['display_name'],
    );
  }
}

/// Provider that fetches enabled categories from the API
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.get('/categories');
  final List<dynamic> data = response.data;
  return data.map((json) => Category.fromJson(json)).toList();
});

/// Helper to get icon for a category slug
IconData getCategoryIcon(String slug) {
  switch (slug.toLowerCase()) {
    case 'pulizie':
      return Icons.cleaning_services;
    case 'traslochi':
      return Icons.local_shipping;
    case 'riparazioni':
      return Icons.build;
    case 'giardinaggio':
      return Icons.yard;
    case 'montaggio':
      return Icons.handyman;
    case 'consegne':
      return Icons.delivery_dining;
    case 'imbiancatura':
      return Icons.format_paint;
    case 'idraulica':
      return Icons.plumbing;
    case 'elettricista':
      return Icons.electrical_services;
    case 'generale':
      return Icons.handshake;
    default:
      return Icons.category;
  }
}
