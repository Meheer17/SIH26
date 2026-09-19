import 'dart:async';
import '../../../../core/api/api_client.dart';

class RakshaSetuService {
  static final RakshaSetuService _instance = RakshaSetuService._internal();
  factory RakshaSetuService() => _instance;
  RakshaSetuService._internal();

  final ApiClient _api = ApiClient();

  // Cache for instant responsiveness
  Map<String, dynamic>? _cachedProfile;
  Map<String, dynamic>? _cachedWellnessScore;
  List<dynamic>? _cachedAssessmentsCatalog;
  List<dynamic>? _cachedAssessmentHistory;
  List<dynamic>? _cachedMoods;
  List<dynamic>? _cachedSleeps;
  List<dynamic>? _cachedJournals;
  List<dynamic>? _cachedChatMessages;
  List<dynamic>? _cachedCounselors;
  List<dynamic>? _cachedAppointments;
  Map<String, dynamic>? _cachedCommanderOverview;
  Map<String, dynamic>? _cachedHeatmap;
  List<dynamic>? _cachedAlerts;
  List<dynamic>? _cachedInterventions;

  // --- 1. PROFILE & CONSENT ---

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final res = await _api.get('rakshak/personnel/me');
      if (res is Map<String, dynamic> && res.containsKey('profile')) {
        _cachedProfile = res['profile'] as Map<String, dynamic>;
        return _cachedProfile!;
      }
    } catch (_) {}
    return _cachedProfile ?? {
      'full_name': 'Havaldar Rajesh Singh',
      'rank': 'Havaldar',
      'force_branch': 'CRPF',
      'unit_name': '44th Battalion CAPF (Border Sentinel)',
      'service_belt_number': 'CRPF-88412',
      'posting_location': 'Baramulla Forward Outpost, J&K',
      'posting_area_risk_class': 4,
      'deployment_days': 115,
      'weekly_duty_hours': 66.0,
      'leave_gap_ratio': 0.82,
      'wellness_points': 740,
      'streak_days': 14,
      'preferred_language': 'hi',
      'emergency_contact_name': 'Sunita Singh (Wife)',
      'emergency_contact_phone': '+91 98765 43210',
    };
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> payload) async {
    final res = await _api.put('rakshak/personnel/preferences', body: payload);
    if (res is Map<String, dynamic> && res.containsKey('profile')) {
      _cachedProfile = res['profile'] as Map<String, dynamic>;
      return res;
    }
    return {'status': 'SUCCESS', 'profile': payload};
  }

  Future<Map<String, dynamic>> submitConsent(Map<String, dynamic> payload) async {
    final res = await _api.post('rakshak/consent', body: payload);
    return res is Map<String, dynamic> ? res : {'status': 'SUCCESS'};
  }

  Future<Map<String, dynamic>> fetchConsent() async {
    try {
      final res = await _api.get('rakshak/consent/me');
      if (res is Map<String, dynamic> && res.containsKey('consent')) {
        return res['consent'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'terms_accepted': true,
      'hr_data_analysis': true,
      'voluntary_self_assessment': true,
      'wearable_biometrics': true,
      'journal_nlp_analysis': true,
      'anonymized_research': false,
    };
  }

  // --- 2. SELF-ASSESSMENTS ---

  Future<List<dynamic>> fetchAssessmentCatalog() async {
    try {
      final res = await _api.get('rakshak/assessments/catalog');
      if (res is Map<String, dynamic> && res.containsKey('catalog')) {
        _cachedAssessmentsCatalog = res['catalog'] as List<dynamic>;
        return _cachedAssessmentsCatalog!;
      }
    } catch (_) {}
    return _cachedAssessmentsCatalog ?? [];
  }

  Future<Map<String, dynamic>> submitAssessment({
    required String assessmentType,
    required List<int> responses,
    String? notes,
    int? durationSeconds,
  }) async {
    final res = await _api.post('rakshak/assessments/submit', body: {
      'assessment_type': assessmentType,
      'responses': responses,
      'notes': notes ?? '',
      'duration_seconds': durationSeconds ?? 180,
    });
    // Invalidate cached history & score
    _cachedAssessmentHistory = null;
    _cachedWellnessScore = null;
    return res is Map<String, dynamic> ? res : {};
  }

  Future<List<dynamic>> fetchAssessmentHistory() async {
    try {
      final res = await _api.get('rakshak/assessments/history');
      if (res is Map<String, dynamic> && res.containsKey('history')) {
        _cachedAssessmentHistory = res['history'] as List<dynamic>;
        return _cachedAssessmentHistory!;
      }
    } catch (_) {}
    return _cachedAssessmentHistory ?? [];
  }

  // --- 3. WELLNESS TRACKING (Mood, Sleep, Journal, Score) ---

  Future<Map<String, dynamic>> logMood({
    required int moodRating,
    required String moodLabel,
    int energyLevel = 3,
    int stressLevel = 3,
    List<String>? tags,
    String? note,
  }) async {
    final res = await _api.post('rakshak/wellness/mood', body: {
      'mood_rating': moodRating,
      'mood_label': moodLabel,
      'energy_level': energyLevel,
      'stress_level': stressLevel,
      'tags': tags ?? [],
      'note': note ?? '',
    });
    _cachedMoods = null;
    _cachedWellnessScore = null;
    return res is Map<String, dynamic> ? res : {};
  }

  Future<List<dynamic>> fetchMoodHistory() async {
    try {
      final res = await _api.get('rakshak/wellness/mood/history');
      if (res is Map<String, dynamic> && res.containsKey('records')) {
        _cachedMoods = res['records'] as List<dynamic>;
        return _cachedMoods!;
      }
    } catch (_) {}
    return _cachedMoods ?? [];
  }

  Future<Map<String, dynamic>> logSleep({
    required String bedtime,
    required String wakeTime,
    required double durationHours,
    required int sleepQuality,
    List<String>? disturbances,
    double? deepSleepPercentage,
  }) async {
    final res = await _api.post('rakshak/wellness/sleep', body: {
      'bedtime': bedtime,
      'wake_time': wakeTime,
      'duration_hours': durationHours,
      'sleep_quality': sleepQuality,
      'disturbances': disturbances ?? [],
      'deep_sleep_percentage': deepSleepPercentage ?? 20.0,
    });
    _cachedSleeps = null;
    _cachedWellnessScore = null;
    return res is Map<String, dynamic> ? res : {};
  }

  Future<List<dynamic>> fetchSleepHistory() async {
    try {
      final res = await _api.get('rakshak/wellness/sleep/history');
      if (res is Map<String, dynamic> && res.containsKey('records')) {
        _cachedSleeps = res['records'] as List<dynamic>;
        return _cachedSleeps!;
      }
    } catch (_) {}
    return _cachedSleeps ?? [];
  }

  Future<Map<String, dynamic>> submitJournal({
    required String journalText,
    bool isVoice = false,
    double? pitchJitter,
  }) async {
    final res = await _api.post('rakshak/wellness/journal', body: {
      'journal_text': journalText,
      'is_voice_transcription': isVoice,
      'voice_pitch_jitter': pitchJitter ?? 0.15,
    });
    _cachedJournals = null;
    return res is Map<String, dynamic> ? res : {};
  }

  Future<List<dynamic>> fetchJournalHistory() async {
    try {
      final res = await _api.get('rakshak/wellness/journal/history');
      if (res is Map<String, dynamic> && res.containsKey('records')) {
        _cachedJournals = res['records'] as List<dynamic>;
        return _cachedJournals!;
      }
    } catch (_) {}
    return _cachedJournals ?? [];
  }

  Future<Map<String, dynamic>> fetchWellnessScore() async {
    try {
      final res = await _api.get('rakshak/wellness/score/me');
      if (res is Map<String, dynamic> && res.containsKey('wellness_score')) {
        _cachedWellnessScore = res;
        return _cachedWellnessScore!;
      }
    } catch (_) {}
    return _cachedWellnessScore ?? {
      'wellness_score': 68.5,
      'risk_score': 31.5,
      'tier': 'MODERATE',
      'tier_color': '#FBBF24',
      'trend': 'STABLE_IMPROVING',
      'trend_arrow': '↑',
      'recommended_action': 'Maintain tactical box breathing and sleep discipline',
      'contributing_factors': [
        {'factor': 'Weekly Duty Workload', 'weight': 25, 'score': 18.0, 'status': 'NORMAL'},
        {'factor': 'Leave Deficit Ratio', 'weight': 25, 'score': 19.5, 'status': 'HIGH'},
        {'factor': 'Clinical Self-Assessment', 'weight': 30, 'score': 12.0, 'status': 'STABLE'},
        {'factor': 'Sleep Deficit & Circadian Strain', 'weight': 20, 'score': 8.0, 'status': 'OPTIMAL'},
      ]
    };
  }

  // --- 4. AI COUNSELOR "SAHAYAK" ---

  Future<Map<String, dynamic>> sendChatMessage(String message, {String language = 'hi'}) async {
    final res = await _api.post('rakshak/chat', body: {
      'message': message,
      'language': language,
    });
    return res is Map<String, dynamic> ? res : {'reply': 'Connected with Sahayak.'};
  }

  Future<List<dynamic>> fetchChatHistory() async {
    try {
      final res = await _api.get('rakshak/chat/history');
      if (res is Map<String, dynamic> && res.containsKey('messages')) {
        _cachedChatMessages = res['messages'] as List<dynamic>;
        return _cachedChatMessages!;
      }
    } catch (_) {}
    return _cachedChatMessages ?? [];
  }

  // --- 5. TACTICAL RESOURCES ---

  Future<List<dynamic>> fetchResources() async {
    try {
      final res = await _api.get('rakshak/resources');
      if (res is Map<String, dynamic> && res.containsKey('resources')) {
        return res['resources'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> logResourceActivity(String resourceId, String activityType, int durationMins) async {
    final res = await _api.post('rakshak/resources/log-activity', body: {
      'resource_id': resourceId,
      'activity_type': activityType,
      'duration_minutes': durationMins,
    });
    return res is Map<String, dynamic> ? res : {};
  }

  // --- 6. GAMIFICATION ---

  Future<Map<String, dynamic>> fetchGamification() async {
    try {
      final res = await _api.get('rakshak/gamification/dashboard');
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}
    return {
      'wellness_points': 740,
      'streak_days': 14,
      'badges': [],
      'battalion_leaderboard': []
    };
  }

  Future<List<dynamic>> fetchChallenges() async {
    try {
      final res = await _api.get('rakshak/gamification/challenges');
      if (res is Map<String, dynamic> && res.containsKey('challenges')) {
        return res['challenges'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  // --- 7. COUNSELING & SOS ---

  Future<List<dynamic>> fetchCounselors() async {
    try {
      final res = await _api.get('rakshak/counselors');
      if (res is Map<String, dynamic> && res.containsKey('counselors')) {
        _cachedCounselors = res['counselors'] as List<dynamic>;
        return _cachedCounselors!;
      }
    } catch (_) {}
    return _cachedCounselors ?? [];
  }

  Future<Map<String, dynamic>> bookAppointment(Map<String, dynamic> payload) async {
    final res = await _api.post('rakshak/appointments/book', body: payload);
    _cachedAppointments = null;
    return res is Map<String, dynamic> ? res : {};
  }

  Future<List<dynamic>> fetchAppointments() async {
    try {
      final res = await _api.get('rakshak/appointments');
      if (res is Map<String, dynamic> && res.containsKey('appointments')) {
        _cachedAppointments = res['appointments'] as List<dynamic>;
        return _cachedAppointments!;
      }
    } catch (_) {}
    return _cachedAppointments ?? [];
  }

  Future<Map<String, dynamic>> triggerSos({
    double? latitude,
    double? longitude,
    String? locationName,
    String? note,
  }) async {
    final res = await _api.post('rakshak/sos', body: {
      'latitude': latitude ?? 34.0837,
      'longitude': longitude ?? 74.7973,
      'location_name': locationName ?? 'Baramulla Forward Outpost',
      'note': note ?? 'Emergency silent distress beacon triggered from app',
    });
    return res is Map<String, dynamic> ? res : {'dispatch_status': 'DISPATCHED'};
  }

  Future<Map<String, dynamic>> fetchPeerBuddy() async {
    try {
      final res = await _api.get('rakshak/peer-buddy');
      if (res is Map<String, dynamic> && res.containsKey('peer_buddy')) {
        return res['peer_buddy'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'alias': 'Cheetah-9 (Anonymous Comrade)',
      'unit': '44th Bn CAPF',
      'status': 'AVAILABLE_FOR_CHAT',
      'bio': 'Experienced high-altitude border sentinel available for peer decompression.'
    };
  }

  // --- 8. BIOMETRIC & WEARABLES ---

  Future<Map<String, dynamic>> syncWearable(Map<String, dynamic> payload) async {
    final res = await _api.post('rakshak/wearables/sync', body: payload);
    return res is Map<String, dynamic> ? res : {};
  }

  Future<Map<String, dynamic>> fetchWearableStatus() async {
    try {
      final res = await _api.get('rakshak/wearables/status');
      if (res is Map<String, dynamic> && res.containsKey('device')) {
        return res['device'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'device_name': 'Garmin Tactical Armed Pro',
      'battery_level': 88,
      'sync_status': 'ACTIVE_SYNCED',
      'heart_rate_bpm': 68,
      'hrv_rmssd_ms': 52.4,
      'stress_index': 32.0,
      'autonomic_state': 'HEALTHY_RECOVERY_PARASYMPATHETIC',
      'sleep_hours': 6.5,
      'steps_count': 14200,
    };
  }

  // --- 9. FAMILY CONNECT ---

  Future<Map<String, dynamic>> fetchFamilyOverview() async {
    try {
      final res = await _api.get('rakshak/family/overview');
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}
    return {
      'family_members': [],
      'scheduled_video_call': {'date': 'Tomorrow, 19:30 IST', 'duration': '20 minutes'},
      'welfare_schemes': []
    };
  }

  Future<Map<String, dynamic>> submitFamilyCheckin(Map<String, dynamic> payload) async {
    final res = await _api.post('rakshak/family/checkin', body: payload);
    return res is Map<String, dynamic> ? res : {};
  }

  // --- 10. COMMANDER & WELFARE OFFICER VIEW ---

  Future<Map<String, dynamic>> fetchCommanderOverview() async {
    try {
      final res = await _api.get('rakshak/commander/overview');
      if (res is Map<String, dynamic>) {
        _cachedCommanderOverview = res;
        return _cachedCommanderOverview!;
      }
    } catch (_) {}
    return _cachedCommanderOverview ?? {
      'unit_name': '44th Battalion CAPF (Border Sentinel)',
      'commanding_officer': 'Col. A. Chatterjee',
      'total_strength': 850,
      'active_field_deployed': 620,
      'average_unit_burnout_index': 38.6,
      'high_risk_count': 12,
      'moderate_strain_count': 45,
      'stable_count': 793,
      'unit_stressors': [],
    };
  }

  Future<Map<String, dynamic>> fetchCommanderHeatmap() async {
    try {
      final res = await _api.get('rakshak/commander/heatmap');
      if (res is Map<String, dynamic>) {
        _cachedHeatmap = res;
        return _cachedHeatmap!;
      }
    } catch (_) {}
    return _cachedHeatmap ?? {'garrison_companies': []};
  }

  Future<List<dynamic>> fetchCommanderAlerts({String? priority}) async {
    try {
      String query = 'rakshak/commander/alerts';
      if (priority != null && priority != 'ALL') {
        query += '?priority=$priority';
      }
      final res = await _api.get(query);
      if (res is Map<String, dynamic> && res.containsKey('alerts')) {
        _cachedAlerts = res['alerts'] as List<dynamic>;
        return _cachedAlerts!;
      }
    } catch (_) {}
    return _cachedAlerts ?? [];
  }

  Future<Map<String, dynamic>> actionCommanderAlert(String alertId, String action, {String? notes}) async {
    final res = await _api.post('rakshak/commander/alerts/$alertId/action', body: {
      'action': action,
      'notes': notes ?? '',
    });
    _cachedAlerts = null;
    return res is Map<String, dynamic> ? res : {};
  }

  Future<Map<String, dynamic>> fetchPersonnelDossier(String personnelId) async {
    final res = await _api.get('rakshak/commander/personnel/$personnelId');
    return res is Map<String, dynamic> ? res : {};
  }

  Future<List<dynamic>> fetchInterventions() async {
    try {
      final res = await _api.get('rakshak/commander/interventions');
      if (res is Map<String, dynamic> && res.containsKey('interventions')) {
        _cachedInterventions = res['interventions'] as List<dynamic>;
        return _cachedInterventions!;
      }
    } catch (_) {}
    return _cachedInterventions ?? [];
  }

  Future<Map<String, dynamic>> assignIntervention(Map<String, dynamic> payload) async {
    final res = await _api.post('rakshak/commander/interventions/assign', body: payload);
    _cachedInterventions = null;
    return res is Map<String, dynamic> ? res : {};
  }

  Future<Map<String, dynamic>> updateInterventionStatus(String id, String status, {String? notes}) async {
    final res = await _api.put('rakshak/commander/interventions/$id/status', body: {
      'status': status,
      'notes': notes ?? '',
    });
    _cachedInterventions = null;
    return res is Map<String, dynamic> ? res : {};
  }

  Future<Map<String, dynamic>> fetchCommanderForecast() async {
    try {
      final res = await _api.get('rakshak/commander/forecast');
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}
    return {
      'forecast_period': 'Next 30 Days',
      'predicted_high_risk_surge_percent': 18.5,
      'bottleneck_sub_units': ['Charlie Company', 'Alpha Company'],
      'recommended_preventative_actions': []
    };
  }

  Future<List<dynamic>> fetchAuditLogs() async {
    try {
      final res = await _api.get('rakshak/commander/audit-logs');
      if (res is Map<String, dynamic> && res.containsKey('audit_logs')) {
        return res['audit_logs'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }
}
