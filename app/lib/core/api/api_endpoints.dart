import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Base URL pointing directly to host machine port 8000 (works on desktop, web, and physical Android via ADB reverse)
  static String get baseUrl {
    return 'http://127.0.0.1:8000/api/v1';
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

