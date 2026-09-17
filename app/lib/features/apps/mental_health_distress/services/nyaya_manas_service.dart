import 'dart:async';
import '../../../../core/api/api_client.dart';

class NyayaManasService {
  static final NyayaManasService _instance = NyayaManasService._internal();
  factory NyayaManasService() => _instance;
  NyayaManasService._internal();

  final ApiClient _api = ApiClient();

  /// Fetch all monitored victims
  Future<Map<String, dynamic>> fetchVictims({
    String? district,
    String? riskTier,
    String? search,
  }) async {
    String query = 'nyaya-manas/victims';
    final params = <String>[];
    if (district != null && district != 'All Districts (UP)') params.add('district=${Uri.encodeComponent(district)}');
    if (riskTier != null && riskTier != 'All Risk Levels') params.add('risk_tier=${Uri.encodeComponent(riskTier)}');
    if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
    if (params.isNotEmpty) query += '?${params.join('&')}';

    final res = await _api.get(query);
    return res is Map<String, dynamic> ? res : {'victims': res};
  }

  /// Fetch single victim dossier
  Future<Map<String, dynamic>> fetchVictimDossier(String victimId) async {
    final res = await _api.get('nyaya-manas/victims/$victimId');
    return res is Map<String, dynamic> ? res : {'victim': res};
  }

  /// Register a new victim
  Future<Map<String, dynamic>> registerVictim(Map<String, dynamic> payload) async {
    final res = await _api.post('nyaya-manas/victims/register', body: payload);
    return res is Map<String, dynamic> ? res : {};
  }

  /// Submit check-in (text, voice features, IVRS)
  Future<Map<String, dynamic>> submitCheckIn(Map<String, dynamic> payload) async {
    final res = await _api.post('nyaya-manas/checkin/submit', body: payload);
    return res is Map<String, dynamic> ? res : {};
  }

  /// Conversational trauma-informed AI chat
  Future<Map<String, dynamic>> sendChatMessage({
    required String victimId,
    required String message,
    String language = 'hi',
  }) async {
    final res = await _api.post('nyaya-manas/chat', body: {
      'victim_id': victimId,
      'message': message,
      'language': language,
    });
    return res is Map<String, dynamic> ? res : {};
  }

  /// Simulate IVRS 14566 Call
  Future<Map<String, dynamic>> simulateIvrs({
    required String victimId,
    required String phoneNumber,
    required int dtmfChoice,
    String language = 'hi',
    String? transcript,
  }) async {
    final res = await _api.post('nyaya-manas/ivrs/simulate', body: {
      'victim_id': victimId,
      'phone_number': phoneNumber,
      'dtmf_choice': dtmfChoice,
      'language': language,
      'spoken_audio_transcript': transcript ?? '',
    });
    return res is Map<String, dynamic> ? res : {};
  }

  /// Fetch statutory interventions
  Future<List<Map<String, dynamic>>> fetchInterventions({
    String? district,
    String? victimId,
    String? agency,
  }) async {
    String query = 'nyaya-manas/interventions';
    final params = <String>[];
    if (district != null) params.add('district=${Uri.encodeComponent(district)}');
    if (victimId != null) params.add('victim_id=${Uri.encodeComponent(victimId)}');
    if (agency != null) params.add('agency=${Uri.encodeComponent(agency)}');
    if (params.isNotEmpty) query += '?${params.join('&')}';

    final res = await _api.get(query);
    if (res is Map && res.containsKey('interventions')) {
      return List<Map<String, dynamic>>.from(res['interventions']);
    } else if (res is List) {
      return List<Map<String, dynamic>>.from(res);
    }
    return [];
  }

  /// Dispatch intervention
  Future<Map<String, dynamic>> dispatchIntervention(Map<String, dynamic> payload) async {
    final res = await _api.post('nyaya-manas/interventions/dispatch', body: payload);
    return res is Map<String, dynamic> ? res : {};
  }

  /// Update intervention outcome
  Future<Map<String, dynamic>> updateInterventionStatus({
    required String interventionId,
    required String status,
    required String outcomeNotes,
  }) async {
    final res = await _api.post('nyaya-manas/interventions/update-status', body: {
      'intervention_id': interventionId,
      'status': status,
      'outcome_notes': outcomeNotes,
    });
    return res is Map<String, dynamic> ? res : {};
  }

  /// Fetch XAI Explanation for victim
  Future<Map<String, dynamic>> fetchXaiExplanation(String victimId) async {
    final res = await _api.get('nyaya-manas/xai/explain/$victimId');
    return res is Map<String, dynamic> ? res : {};
  }

  /// Human override of DDS
  Future<Map<String, dynamic>> submitHumanOverride({
    required String victimId,
    required double adjustedDdsScore,
    required String justificationReason,
  }) async {
    final res = await _api.post('nyaya-manas/xai/override', body: {
      'victim_id': victimId,
      'adjusted_dds_score': adjustedDdsScore,
      'justification_reason': justificationReason,
    });
    return res is Map<String, dynamic> ? res : {};
  }

  /// Disburse statutory compensation
  Future<Map<String, dynamic>> disburseCompensation({
    required String victimId,
    required String stage,
    required double amountInr,
    required String referenceNumber,
  }) async {
    final res = await _api.post('nyaya-manas/compensation/disburse', body: {
      'victim_id': victimId,
      'stage': stage,
      'amount_inr': amountInr,
      'reference_number': referenceNumber,
    });
    return res is Map<String, dynamic> ? res : {};
  }

  /// Trigger silent SOS Witness Beacon
  Future<Map<String, dynamic>> triggerSosBeacon({
    required String victimId,
    double latitude = 25.3176,
    double longitude = 82.9739,
    String? threatDescription,
    bool covertPinUsed = false,
  }) async {
    final res = await _api.post('nyaya-manas/sos/trigger', body: {
      'victim_id': victimId,
      'latitude': latitude,
      'longitude': longitude,
      'threat_description': threatDescription ?? 'Emergency silent beacon triggered',
      'covert_pin_used': covertPinUsed,
    });
    return res is Map<String, dynamic> ? res : {};
  }

  /// Fetch Role-Specific Dashboard
  Future<Map<String, dynamic>> fetchRoleDashboard(String roleTier, {String? victimId, String? district}) async {
    String query = 'nyaya-manas/dashboard/$roleTier';
    final params = <String>[];
    if (victimId != null) params.add('victim_id=${Uri.encodeComponent(victimId)}');
    if (district != null) params.add('district=${Uri.encodeComponent(district)}');
    if (params.isNotEmpty) query += '?${params.join('&')}';

    final res = await _api.get(query);
    return res is Map<String, dynamic> ? res : {};
  }

  /// Upload doctor clinical report, execute OCR, and index in Mongo Vector DB
  Future<Map<String, dynamic>> uploadClinicalReport({
    required String victimId,
    String doctorName = 'Dr. Ananya Sharma, MD (Psychiatry)',
    String doctorLicense = 'MCI-NIMHANS-2018-8842',
    String reportType = 'DMHP Clinical Intake & Trauma Assessment',
    String rawText = '',
    String? imageBase64,
    String fileName = 'clinical_report.pdf',
  }) async {
    final res = await _api.post('nyaya-manas/reports/upload-ocr', body: {
      'victim_id': victimId,
      'doctor_name': doctorName,
      'doctor_license': doctorLicense,
      'report_type': reportType,
      'raw_text': rawText,
      'image_base64': imageBase64,
      'file_name': fileName,
    });
    return res is Map<String, dynamic> ? res : {};
  }

  /// Query Clinical Vector Database using RAG
  Future<Map<String, dynamic>> ragQueryClinicalKnowledge({
    required String query,
    String? victimId,
    int topK = 3,
  }) async {
    final res = await _api.post('nyaya-manas/reports/rag-query', body: {
      'victim_id': victimId,
      'query': query,
      'top_k': topK,
    });
    return res is Map<String, dynamic> ? res : {};
  }

  /// Retrieve all clinical/forensic reports for a victim
  Future<Map<String, dynamic>> fetchVictimReports(String victimId) async {
    final res = await _api.get('nyaya-manas/reports/$victimId');
    return res is Map<String, dynamic> ? res : {};
  }

  /// Fetch cases prioritized by Composite Urgency Score (CUS)
  Future<Map<String, dynamic>> fetchPrioritizedCases({String? district}) async {
    String query = 'nyaya-manas/cases/prioritized';
    if (district != null) query += '?district=${Uri.encodeComponent(district)}';
    final res = await _api.get(query);
    return res is Map<String, dynamic> ? res : {};
  }

  /// Generate automated statutory decision package
  Future<Map<String, dynamic>> generateAutomatedDecision(String victimId, {String additionalContext = ''}) async {
    final res = await _api.post('nyaya-manas/cases/auto-decide', body: {
      'victim_id': victimId,
      'additional_context': additionalContext,
    });
    return res is Map<String, dynamic> ? res : {};
  }
}
