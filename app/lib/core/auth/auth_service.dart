import 'dart:async';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class UserModel {
  final String id;
  final String fullName;
  final String emailOrPhone;
  final String primaryRole;
  final String appContext;
  final List<String> mappedRoles;
  final bool isActive;
  final bool isAdmin;
  final bool isVerified;
  final String? abhaId;

  UserModel({
    required this.id,
    required this.fullName,
    required this.emailOrPhone,
    required this.primaryRole,
    required this.appContext,
    required this.mappedRoles,
    required this.isActive,
    required this.isAdmin,
    this.isVerified = false,
    this.abhaId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      emailOrPhone: json['email_or_phone'] ?? json['emailOrPhone'] ?? '',
      primaryRole: json['primary_role'] ?? json['primaryRole'] ?? 'PATIENT',
      appContext: json['app_context'] ?? json['appContext'] ?? 'arogya_sathi',
      mappedRoles: List<String>.from(json['mapped_roles'] ?? json['mappedRoles'] ?? []),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      isAdmin: json['is_admin'] ?? json['isAdmin'] ?? false,
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      abhaId: json['abha_id'] ?? json['abhaId'],
    );
  }
}

class ConsentModel {
  final String id;
  final String userId;
  final String granteeId;
  final String granteeName;
  final String purpose;
  final List<String> scopes;
  final bool isRevoked;
  final String createdAt;
  final String expiresAt;

  ConsentModel({
    required this.id,
    required this.userId,
    required this.granteeId,
    required this.granteeName,
    required this.purpose,
    required this.scopes,
    required this.isRevoked,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ConsentModel.fromJson(Map<String, dynamic> json) {
    return ConsentModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      granteeId: json['grantee_id'] ?? '',
      granteeName: json['grantee_name'] ?? 'Specialist',
      purpose: json['purpose'] ?? '',
      scopes: List<String>.from(json['scopes'] ?? []),
      isRevoked: json['is_revoked'] ?? false,
      createdAt: json['created_at'] ?? '',
      expiresAt: json['expires_at'] ?? '',
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    // Interceptor binding: ApiClient retrieves JWT dynamically from here
    ApiClient.tokenProvider = () => _authToken;
    ApiClient.onRefreshToken = () => refreshSession();
  }

  final ApiClient _apiClient = ApiClient();
  String? _authToken;
  String? _refreshToken;
  UserModel? _currentUser;

  String? get token => _authToken;
  String? get refreshToken => _refreshToken;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null && _currentUser != null;

  /// Register User (returns registration info, needs verification)
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String emailOrPhone,
    required String password,
    required String primaryRole,
    required String appContext,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      body: {
        'full_name': fullName,
        'email_or_phone': emailOrPhone,
        'password': password,
        'primary_role': primaryRole,
        'app_context': appContext,
      },
    );
    return Map<String, dynamic>.from(response);
  }

  /// Verify OTP Code and activate login session
  Future<UserModel> verifyOtp({
    required String emailOrPhone,
    required String otpCode,
  }) async {
    final response = await _apiClient.post(
      'auth/verify-otp',
      body: {
        'email_or_phone': emailOrPhone,
        'otp_code': otpCode,
      },
    );

    _authToken = response['access_token'];
    _refreshToken = response['refresh_token'];
    return await fetchProfile();
  }

  /// Resend Verification OTP to terminal
  Future<Map<String, dynamic>> resendOtp({
    required String emailOrPhone,
  }) async {
    final response = await _apiClient.post(
      'auth/resend-otp',
      body: {
        'email_or_phone': emailOrPhone,
      },
    );
    return Map<String, dynamic>.from(response);
  }

  /// Login User
  Future<UserModel> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {
        'email_or_phone': emailOrPhone,
        'password': password,
      },
    );

    _authToken = response['access_token'];
    _refreshToken = response['refresh_token'];
    return await fetchProfile();
  }

  /// Fetch User Profile (/me)
  Future<UserModel> fetchProfile() async {
    final response = await _apiClient.get(
      ApiEndpoints.profileMe,
    );
    _currentUser = UserModel.fromJson(response);
    return _currentUser!;
  }

  /// Refresh Session using refresh token
  Future<bool> refreshSession() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _apiClient.post(
        'auth/refresh',
        body: {
          'refresh_token': _refreshToken,
        },
      );
      _authToken = response['access_token'];
      _refreshToken = response['refresh_token'];
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  /// Admin: List Users
  Future<List<UserModel>> listAllUsers() async {
    final response = await _apiClient.get(
      ApiEndpoints.adminUsers,
    );
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  /// Admin: Map Roles
  Future<dynamic> mapUserRoles({
    required String userId,
    required List<String> roles,
    String? appContext,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.adminMapRoles(userId),
      body: {
        'user_id': userId,
        'roles': roles,
        'app_context': ?appContext,
      },
    );
  }

  /// Consent: Grant
  Future<ConsentModel> grantConsent({
    required String granteeName,
    required String purpose,
    required List<String> scopes,
    required int durationDays,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.consentGrant,
      body: {
        'grantee_id': 'spec_${DateTime.now().millisecondsSinceEpoch}',
        'grantee_name': granteeName,
        'purpose': purpose,
        'scopes': scopes,
        'duration_days': durationDays,
      },
    );
    return ConsentModel.fromJson(response);
  }

  /// Consent: List
  Future<List<ConsentModel>> listMyConsents() async {
    final response = await _apiClient.get(
      ApiEndpoints.myConsents,
    );
    return (response as List).map((json) => ConsentModel.fromJson(json)).toList();
  }

  /// Consent: Revoke
  Future<ConsentModel> revokeConsent(String consentId) async {
    final response = await _apiClient.post(
      ApiEndpoints.consentRevoke(consentId),
    );
    return ConsentModel.fromJson(response);
  }

  /// Logout and clear token states on server and client
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await _apiClient.post('auth/logout');
      }
    } catch (_) {
      // Suppress connection issues during logout teardown
    } finally {
      _authToken = null;
      _refreshToken = null;
      _currentUser = null;
    }
  }
}
