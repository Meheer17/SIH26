import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';

class PhcService {
  final ApiClient _api = ApiClient();

  // 1. User & Health Profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final res = await _api.get('phc/users/profile');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getUserProfile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final res = await _api.put('phc/users/profile', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in updateUserProfile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getHealthProfile() async {
    try {
      final res = await _api.get('phc/users/health-profile');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getHealthProfile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateHealthProfile(Map<String, dynamic> data) async {
    try {
      final res = await _api.put('phc/users/health-profile', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in updateHealthProfile: $e');
      return null;
    }
  }

  // 2. Vitals & Continuous Health Tracking
  Future<Map<String, dynamic>?> getLatestVitals() async {
    try {
      final res = await _api.get('phc/health/vitals/latest');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getLatestVitals: $e');
      return null;
    }
  }

  Future<List<dynamic>> getVitalsHistory({int limit = 20}) async {
    try {
      final res = await _api.get('phc/health/vitals/history?limit=$limit');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getVitalsHistory: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> syncVitals(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('phc/health/vitals/sync', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in syncVitals: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVitalsTrends() async {
    try {
      final res = await _api.get('phc/health/vitals/trends');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getVitalsTrends: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getHealthRiskScore() async {
    try {
      final res = await _api.get('phc/health/risk-score');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getHealthRiskScore: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getHydrationToday() async {
    try {
      final res = await _api.get('phc/health/hydration/today');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getHydrationToday: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> logHydration(int amountMl, {String beverageType = 'water'}) async {
    try {
      final res = await _api.post('phc/health/hydration/log', body: {
        'amount_ml': amountMl,
        'beverage_type': beverageType,
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in logHydration: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSleepHistory() async {
    try {
      final res = await _api.get('phc/health/sleep/history');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getSleepHistory: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getActivityHistory() async {
    try {
      final res = await _api.get('phc/health/activity/history');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getActivityHistory: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeeklyReport() async {
    try {
      final res = await _api.get('phc/health/reports/weekly');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getWeeklyReport: $e');
      return null;
    }
  }

  // 3. AI Anomaly Detection & Alerts
  Future<List<dynamic>> getAnomalies() async {
    try {
      final res = await _api.get('phc/anomalies');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getAnomalies: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> dismissAnomaly(String anomalyId) async {
    try {
      final res = await _api.post('phc/anomalies/$anomalyId/dismiss');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in dismissAnomaly: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> escalateAnomaly(String anomalyId) async {
    try {
      final res = await _api.post('phc/anomalies/$anomalyId/escalate');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in escalateAnomaly: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> detectEdgeAiAnomalies(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('phc/anomalies/detect', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in detectEdgeAiAnomalies: $e');
      return null;
    }
  }

  Future<List<dynamic>> getDisasterAlerts() async {
    try {
      final res = await _api.get('phc/alerts/disaster');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getDisasterAlerts: $e');
      return [];
    }
  }

  // 4. Environmental Intelligence
  Future<Map<String, dynamic>?> getCurrentEnvironment() async {
    try {
      final res = await _api.get('phc/environment/current');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getCurrentEnvironment: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getEnvironmentForecast() async {
    try {
      final res = await _api.get('phc/environment/forecast');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getEnvironmentForecast: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAqiDetails() async {
    try {
      final res = await _api.get('phc/environment/aqi');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getAqiDetails: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getHeatIndexDetails() async {
    try {
      final res = await _api.get('phc/environment/heat-index');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getHeatIndexDetails: $e');
      return null;
    }
  }

  // 5. Emergency SOS & Nearby Care
  Future<Map<String, dynamic>?> triggerEmergencySos({
    double lat = 25.3176,
    double lng = 82.9739,
    String address = 'Assi Ghat, Varanasi, Uttar Pradesh',
    String triggerType = 'manual_button',
    String? reason,
  }) async {
    try {
      final res = await _api.post('phc/emergency/sos/trigger', body: {
        'latitude': lat,
        'longitude': lng,
        'address': address,
        'trigger_type': triggerType,
        'distress_reason': reason ?? 'Exertional Heat Exhaustion & Dizziness',
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in triggerEmergencySos: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> cancelEmergencySos() async {
    try {
      final res = await _api.post('phc/emergency/sos/cancel');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in cancelEmergencySos: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getEmergencySosStatus() async {
    try {
      final res = await _api.get('phc/emergency/sos/status');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getEmergencySosStatus: $e');
      return null;
    }
  }

  Future<List<dynamic>> getEmergencyContacts() async {
    try {
      final res = await _api.get('phc/emergency/contacts');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getEmergencyContacts: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addEmergencyContact(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('phc/emergency/contacts', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in addEmergencyContact: $e');
      return null;
    }
  }

  Future<bool> deleteEmergencyContact(String contactId) async {
    try {
      await _api.delete('phc/emergency/contacts/$contactId');
      return true;
    } catch (e) {
      debugPrint('Error in deleteEmergencyContact: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getEmergencyMedicalId() async {
    try {
      final res = await _api.get('phc/emergency/medical-id');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getEmergencyMedicalId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateEmergencyMedicalId(Map<String, dynamic> data) async {
    try {
      final res = await _api.put('phc/emergency/medical-id', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in updateEmergencyMedicalId: $e');
      return null;
    }
  }

  Future<List<dynamic>> getNearbyHospitals() async {
    try {
      final res = await _api.get('phc/emergency/nearby-hospitals');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getNearbyHospitals: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> reportFallDetected() async {
    try {
      final res = await _api.post('phc/emergency/fall-detected');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in reportFallDetected: $e');
      return null;
    }
  }

  // 6. Medications & Reminders
  Future<List<dynamic>> getMedications() async {
    try {
      final res = await _api.get('phc/medications');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getMedications: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addMedication(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('phc/medications', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in addMedication: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> logMedicationStatus(String medId, String status) async {
    try {
      final res = await _api.post('phc/medications/$medId/log', body: {
        'medication_id': medId,
        'status': status,
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in logMedicationStatus: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMedicationAdherence() async {
    try {
      final res = await _api.get('phc/medications/adherence');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getMedicationAdherence: $e');
      return null;
    }
  }

  // 7. Caregiver Hub
  Future<List<dynamic>> getCaregiverDependents() async {
    try {
      final res = await _api.get('phc/caregiver/dependents');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getCaregiverDependents: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> sendCaregiverCheckin(String depId, {String? message}) async {
    try {
      final res = await _api.post('phc/caregiver/dependents/$depId/check-in', body: {
        'dependent_id': depId,
        'message': message ?? 'Are you feeling okay today? Remember to drink ORS.',
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in sendCaregiverCheckin: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> triggerRemoteSos(String depId) async {
    try {
      final res = await _api.post('phc/caregiver/dependents/$depId/sos');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in triggerRemoteSos: $e');
      return null;
    }
  }

  // 8. Provider / ASHA Copilot
  Future<List<dynamic>> getProviderPatients() async {
    try {
      final res = await _api.get('phc/provider/patients');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getProviderPatients: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCommunityHeatmap() async {
    try {
      final res = await _api.get('phc/provider/community/heatmap');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getCommunityHeatmap: $e');
      return null;
    }
  }

  // 9. Telemedicine
  Future<List<dynamic>> getTelemedicineDoctors() async {
    try {
      final res = await _api.get('phc/telemedicine/doctors');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getTelemedicineDoctors: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> bookTelemedicineAppointment({
    required String doctorId,
    required String appointmentTime,
    required String chiefComplaint,
    String consultationType = 'video',
  }) async {
    try {
      final res = await _api.post('phc/telemedicine/appointments', body: {
        'doctor_id': doctorId,
        'appointment_time': appointmentTime,
        'consultation_type': consultationType,
        'chief_complaint': chiefComplaint,
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in bookTelemedicineAppointment: $e');
      return null;
    }
  }

  Future<List<dynamic>> getTelemedicineAppointments() async {
    try {
      final res = await _api.get('phc/telemedicine/appointments');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getTelemedicineAppointments: $e');
      return [];
    }
  }

  // 10. Health Records Vault
  Future<List<dynamic>> getHealthRecords() async {
    try {
      final res = await _api.get('phc/records');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getHealthRecords: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> uploadHealthRecord(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('phc/records', body: data);
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in uploadHealthRecord: $e');
      return null;
    }
  }

  Future<bool> deleteHealthRecord(String recordId) async {
    try {
      await _api.delete('phc/records/$recordId');
      return true;
    } catch (e) {
      debugPrint('Error in deleteHealthRecord: $e');
      return false;
    }
  }

  // 11. Government Schemes
  Future<Map<String, dynamic>?> getSchemesEligibility() async {
    try {
      final res = await _api.get('phc/schemes/eligibility');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getSchemesEligibility: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateAbhaId({
    required String aadhaarNumber,
    required String mobile,
    required String fullName,
  }) async {
    try {
      final res = await _api.post('phc/schemes/abha/generate', body: {
        'aadhaar_number': aadhaarNumber,
        'mobile': mobile,
        'full_name': fullName,
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in generateAbhaId: $e');
      return null;
    }
  }

  // 12. Content & Wellness
  Future<Map<String, dynamic>?> getWellnessRecommendations() async {
    try {
      final res = await _api.get('phc/content/recommendations');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getWellnessRecommendations: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFirstAidGuides() async {
    try {
      final res = await _api.get('phc/content/first-aid');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getFirstAidGuides: $e');
      return null;
    }
  }

  // 13. Paired BLE Devices
  Future<List<dynamic>> getPairedDevices() async {
    try {
      final res = await _api.get('phc/devices');
      return res is List ? res : [];
    } catch (e) {
      debugPrint('Error in getPairedDevices: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> syncDevice(String deviceId) async {
    try {
      final res = await _api.post('phc/devices/$deviceId/sync');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in syncDevice: $e');
      return null;
    }
  }

  // 14. Edge AI & Privacy
  Future<Map<String, dynamic>?> getEdgeAiStatus() async {
    try {
      final res = await _api.get('phc/edge-ai/status');
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in getEdgeAiStatus: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> toggleConsent(String key, bool granted) async {
    try {
      final res = await _api.post('phc/privacy/consent/toggle', body: {
        'consent_key': key,
        'granted': granted,
      });
      return res is Map<String, dynamic> ? res : null;
    } catch (e) {
      debugPrint('Error in toggleConsent: $e');
      return null;
    }
  }
}
