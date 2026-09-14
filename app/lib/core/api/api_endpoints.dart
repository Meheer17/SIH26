import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Configurable base URL depending on platform (emulator vs physical device vs web)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else {
      // LAN IP for mobile clients / physical devices (e.g. AC2001) / emulators
      return 'http://192.168.31.202:8000/api/v1';
    }
  }

  // API Routes
  static String get health => '$baseUrl/health';
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get profileMe => '$baseUrl/auth/me';
  static String get adminUsers => '$baseUrl/admin/users';
  static String adminMapRoles(String userId) => '$baseUrl/admin/users/$userId/roles';
  static String get consentGrant => '$baseUrl/consent/grant';
  static String get myConsents => '$baseUrl/consent/my-consents';
  static String consentRevoke(String consentId) => '$baseUrl/consent/revoke/$consentId';
  
  // Dynamic Endpoint Helper
  static String endpoint(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }
}

