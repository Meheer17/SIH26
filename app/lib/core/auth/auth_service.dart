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

  UserModel({
    required this.id,
    required this.fullName,
    required this.emailOrPhone,
    required this.primaryRole,
    required this.appContext,
    required this.mappedRoles,
    required this.isActive,
    required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      emailOrPhone: json['email_or_phone'] ?? '',
      primaryRole: json['primary_role'] ?? 'PATIENT',
      appContext: json['app_context'] ?? 'arogya_sathi',
      mappedRoles: List<String>.from(json['mapped_roles'] ?? []),
      isActive: json['is_active'] ?? true,
      isAdmin: json['is_admin'] ?? false,
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
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  String? _authToken;
  UserModel? _currentUser;

  String? get token => _authToken;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null && _currentUser != null;

  Map<String, String> get _authHeaders => {
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Register User
  Future<UserModel> register({
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

    _authToken = response['access_token'];
    return await fetchProfile();
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
    return await fetchProfile();
  }

  /// Fetch User Profile (/me)
  Future<UserModel> fetchProfile() async {
    final response = await _apiClient.get(
      ApiEndpoints.profileMe,
      headers: _authHeaders,
    );
    _currentUser = UserModel.fromJson(response);
    return _currentUser!;
  }

  /// Admin: List Users
  Future<List<UserModel>> listAllUsers() async {
    final response = await _apiClient.get(
      ApiEndpoints.adminUsers,
      headers: _authHeaders,
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
      headers: _authHeaders,
      body: {
        'user_id': userId,
        'roles': roles,
        if (appContext != null) 'app_context': appContext,
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
      headers: _authHeaders,
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
      headers: _authHeaders,
    );
    return (response as List).map((json) => ConsentModel.fromJson(json)).toList();
  }

  /// Consent: Revoke
  Future<ConsentModel> revokeConsent(String consentId) async {
    final response = await _apiClient.post(
      ApiEndpoints.consentRevoke(consentId),
      headers: _authHeaders,
    );
    return ConsentModel.fromJson(response);
  }

  /// Logout
  void logout() {
    _authToken = null;
    _currentUser = null;
  }
}
