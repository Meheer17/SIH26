import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';

class MediKioskService {
  final ApiClient _api = ApiClient();

  // 1. PATIENT & AUTHENTICATION
  Future<List<dynamic>> getPatients() async {
    try {
      final res = await _api.get('medikiosk/patients');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPatient(String patientId) async {
    try {
      final res = await _api.get('medikiosk/patients/$patientId');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching patient: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPatientsLiveDirectory({
    String? dept,
    String? statusFilter,
    String? search,
  }) async {
    try {
      final query = <String, String>{};
      if (dept != null && dept.isNotEmpty) query['department'] = dept;
      if (statusFilter != null && statusFilter.isNotEmpty) query['status_filter'] = statusFilter;
      if (search != null && search.isNotEmpty) query['search'] = search;

      String endpoint = 'medikiosk/patients/directory/live';
      if (query.isNotEmpty) {
        final q = query.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
        endpoint = '$endpoint?$q';
      }

      final res = await _api.get(endpoint);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching live patients directory: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> registerPatient(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('medikiosk/patients/register', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error registering patient: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyAbha(String abhaOrPhone) async {
    try {
      final res = await _api.post('medikiosk/auth/abha/verify', body: {'abha_id': abhaOrPhone});
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error verifying ABHA: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyAadhaar(String aadhaar) async {
    try {
      final res = await _api.post('medikiosk/auth/aadhaar/verify', body: {'aadhaar_number': aadhaar});
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error verifying Aadhaar: $e');
      return null;
    }
  }

  // 2. SESSION & CONSENT
  Future<Map<String, dynamic>?> createSession(String patientId, {String? dept, String? lang}) async {
    try {
      final res = await _api.post('medikiosk/sessions/create', body: {
        'patient_id': patientId,
        'department': dept ?? 'General Medicine OPD',
        'language': lang ?? 'hi',
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error creating session: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> grantConsent(String patientId, List<String> consentTypes) async {
    try {
      final res = await _api.post('medikiosk/consent/grant', body: {
        'patient_id': patientId,
        'consent_types': consentTypes,
        'signature_data': 'digital-signature-verified-on-kiosk',
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error granting consent: $e');
      return null;
    }
  }

  // 3. CONVERSATIONAL SOCRATES HISTORY
  Future<Map<String, dynamic>?> startHistory(String sessionId, {String? dept, String? site}) async {
    try {
      final res = await _api.post('medikiosk/history/start', body: {
        'session_id': sessionId,
        'department': dept ?? 'General Medicine OPD',
        'body_site': site ?? 'Chest / Cardiovascular',
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error starting history: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> respondHistory(String interviewId, String questionId, String answer) async {
    try {
      final res = await _api.post('medikiosk/history/respond', body: {
        'interview_id': interviewId,
        'question_id': questionId,
        'answer_text': answer,
        'input_mode': 'touch',
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error responding history: $e');
      return null;
    }
  }

  // 4. AYUSH DASHAVIDHA
  Future<Map<String, dynamic>?> getDashavidha(String patientId) async {
    try {
      final res = await _api.get('medikiosk/ayush/dashavidha/$patientId');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching Dashavidha: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveDashavidha(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('medikiosk/ayush/dashavidha', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error saving Dashavidha: $e');
      return null;
    }
  }

  // 5. DOCUMENTS & OCR
  Future<List<dynamic>> getPatientDocuments(String patientId) async {
    try {
      final res = await _api.get('medikiosk/documents/patient/$patientId');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error fetching documents: $e');
      return [];
    }
  }

  // 6. TIMELINE & LABS
  Future<Map<String, dynamic>?> getTimeline(String patientId) async {
    try {
      final res = await _api.get('medikiosk/timeline/$patientId');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching timeline: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLabTrends(String patientId, {String testName = 'HbA1c'}) async {
    try {
      final res = await _api.get('medikiosk/lab-values/$patientId/trends?test_name=$testName');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching lab trends: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDrugInteractions(String patientId) async {
    try {
      final res = await _api.get('medikiosk/medications/$patientId/interactions');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error checking drug interactions: $e');
      return null;
    }
  }

  // 7. CLINICAL SUMMARY
  Future<Map<String, dynamic>?> getSummary(String summaryId) async {
    try {
      final res = await _api.get('medikiosk/summary/$summaryId');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error getting summary: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> editSummarySection(String summaryId, String section, String content) async {
    try {
      final res = await _api.put('medikiosk/summary/$summaryId/edit', body: {
        'summary_id': summaryId,
        'section': section,
        'updated_content': content,
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error editing summary section: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> acceptSummary(String summaryId, {String? doctorName}) async {
    try {
      final res = await _api.post('medikiosk/summary/$summaryId/accept', body: {
        'doctor_name': doctorName ?? 'Dr. Ananya Sharma',
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error accepting summary: $e');
      return null;
    }
  }

  // 8. DOCTOR EMR & PRESCRIPTION
  Future<Map<String, dynamic>?> getDoctorDashboard() async {
    try {
      final res = await _api.get('medikiosk/doctor/dashboard');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching doctor dashboard: $e');
      return null;
    }
  }

  Future<List<dynamic>> getDoctorQueue({String? dept}) async {
    try {
      final endpoint = dept != null ? 'medikiosk/doctor/queue?department=$dept' : 'medikiosk/doctor/queue';
      final res = await _api.get(endpoint);
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error fetching doctor queue: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> callPatient(String token) async {
    try {
      final res = await _api.post('medikiosk/doctor/queue/$token/call');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error calling patient: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveDoctorNotes(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('medikiosk/doctor/notes', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error saving doctor notes: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveDualPrescription(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('medikiosk/doctor/prescription', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error saving dual prescription: $e');
      return null;
    }
  }

  // 9. TRIAGE & EMERGENCY
  Future<List<dynamic>> getTriageAlerts() async {
    try {
      final res = await _api.get('medikiosk/triage/alerts');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error fetching triage alerts: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> acknowledgeAlert(String alertId) async {
    try {
      final res = await _api.post('medikiosk/triage/alerts/$alertId/acknowledge');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error acknowledging alert: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> resolveAlert(String alertId) async {
    try {
      final res = await _api.post('medikiosk/triage/alerts/$alertId/resolve');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error resolving alert: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> recordVitals(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('medikiosk/triage/vitals', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error recording vitals: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> assignEsi(String patientId, int esiLevel, String dept) async {
    try {
      final res = await _api.post('medikiosk/triage/esi', body: {
        'patient_id': patientId,
        'esi_level': esiLevel,
        'routing_department': dept,
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error assigning ESI: $e');
      return null;
    }
  }

  // 10. HOSPITAL ADMIN & ANALYTICS
  Future<Map<String, dynamic>?> getAdminDashboard() async {
    try {
      final res = await _api.get('medikiosk/admin/dashboard');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching admin dashboard: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAdminAnalytics() async {
    try {
      final res = await _api.get('medikiosk/admin/analytics');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching admin analytics: $e');
      return null;
    }
  }

  Future<List<dynamic>> getKiosks() async {
    try {
      final res = await _api.get('medikiosk/admin/kiosks');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error fetching kiosks: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> restartKiosk(String kioskId) async {
    try {
      final res = await _api.post('medikiosk/admin/kiosks/$kioskId/restart');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error restarting kiosk: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitFeedback(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('medikiosk/admin/feedback', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFeedback() async {
    try {
      final res = await _api.get('medikiosk/admin/feedback');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching feedback: $e');
      return null;
    }
  }

  // 11. SYSTEM ADMIN, EPHEMERAL PURGE & ABDM FHIR
  Future<Map<String, dynamic>?> getSystemHealth() async {
    try {
      final res = await _api.get('medikiosk/system/health');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error fetching system health: $e');
      return null;
    }
  }

  Future<List<dynamic>> getAuditLogs() async {
    try {
      final res = await _api.get('medikiosk/system/audit-logs');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> purgeEphemeralMemory() async {
    try {
      final res = await _api.post('medikiosk/system/sanitizer/purge');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error purging memory: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFhirBundle(String patientId) async {
    try {
      final res = await _api.get('medikiosk/fhir/bundle/$patientId');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error generating FHIR bundle: $e');
      return null;
    }
  }
}
