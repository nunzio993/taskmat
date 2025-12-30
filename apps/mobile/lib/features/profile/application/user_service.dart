import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}
