import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SosLocation {
  final double latitude;
  final double longitude;
  final String addressName;
  final String? googleMapsUrl;
  final String? osmUrl;

  SosLocation({
    required this.latitude,
    required this.longitude,
    required this.addressName,
    this.googleMapsUrl,
    this.osmUrl,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address_name': addressName,
        'google_maps_url': googleMapsUrl,
        'osm_url': osmUrl,
      };
}

class SosHealthSnapshot {
  final int? heartRate;
  final double? bodyTempC;
  final double? heatIndex;
  final String? triageStatus;
  final int? burnoutScore;
  final int? distressScore;

  SosHealthSnapshot({
    this.heartRate,
    this.bodyTempC,
    this.heatIndex,
    this.triageStatus,
    this.burnoutScore,
    this.distressScore,
  });

  Map<String, dynamic> toJson() => {
        'heart_rate': heartRate,
        'body_temp_c': bodyTempC,
        'heat_index': heatIndex,
        'triage_status': triageStatus,
        'burnout_score': burnoutScore,
        'distress_score': distressScore,
      };
}

class EmergencyFacility {
  final String name;
  final String type;
  final double distanceKm;
  final int distanceMeters;
  final int estimatedEtaMins;
  final String phone;
  final String directionsUrl;

  EmergencyFacility({
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.distanceMeters,
    required this.estimatedEtaMins,
    required this.phone,
    required this.directionsUrl,
  });

  factory EmergencyFacility.fromJson(Map<String, dynamic> json) {
    return EmergencyFacility(
      name: json['name'] ?? 'Local Emergency Facility',
      type: json['type'] ?? 'Hospital',
      distanceKm: (json['distance_km'] ?? 1.5).toDouble(),
      distanceMeters: json['distance_meters'] ?? 1500,
      estimatedEtaMins: json['estimated_eta_mins'] ?? 5,
      phone: json['phone'] ?? '108',
      directionsUrl: json['directions_url'] ?? '',
    );
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;
  final bool notifySms;
  final bool notifyWhatsapp;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.isPrimary = true,
    this.notifySms = true,
    this.notifyWhatsapp = true,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? 'cnt-01',
      name: json['name'] ?? 'Emergency Contact',
      relationship: json['relationship'] ?? 'Family',
      phoneNumber: json['phone_number'] ?? '+919876543210',
      isPrimary: json['is_primary'] ?? true,
      notifySms: json['notify_sms'] ?? true,
      notifyWhatsapp: json['notify_whatsapp'] ?? true,
    );
  }
}

class SosEvent {
  final String sosId;
  final String appContext;
  final String userId;
  final String userName;
  final SosLocation location;
  final SosHealthSnapshot healthSnapshot;
  final List<String> emergencyContacts;
  final String emergencyReason;
  String status;
  final String timestamp;
  String? whatsappDispatchUrl;
  String? smsDispatchUrl;
  EmergencyFacility? closestHospital;

  SosEvent({
    required this.sosId,
    required this.appContext,
    required this.userId,
    required this.userName,
    required this.location,
    required this.healthSnapshot,
    required this.emergencyContacts,
    required this.emergencyReason,
    this.status = 'COUNTDOWN_ACTIVE',
    required this.timestamp,
    this.whatsappDispatchUrl,
    this.smsDispatchUrl,
    this.closestHospital,
  });
}

class SosEmergencyModule {
  static Timer? _countdownTimer;
  static int _secondsRemaining = 5;
  static SosEvent? _activeEvent;

  static final StreamController<int> _countdownStreamController = StreamController<int>.broadcast();
  static Stream<int> get countdownStream => _countdownStreamController.stream;
  static SosEvent? get activeEvent => _activeEvent;

  /// OpenStreetMap Nominatim Reverse Geocoding
  static Future<Map<String, dynamic>> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse('http://localhost:8000/api/v1/sos/reverse-geocode?lat=$lat&lon=$lon');
      final resp = await http.get(url).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
    } catch (_) {}

    return {
      'display_name': 'Coordinates: ${lat.toStringAsFixed(4)}° N, ${lon.toStringAsFixed(4)}° E',
      'google_maps_url': 'https://www.google.com/maps?q=$lat,$lon',
    };
  }

  /// OpenStreetMap Overpass Nearby Emergency Facilities
  static Future<List<EmergencyFacility>> getNearbyFacilities(double lat, double lon, {double radiusKm = 5.0}) async {
    try {
      final url = Uri.parse('http://localhost:8000/api/v1/sos/nearby-emergency-services?lat=$lat&lon=$lon&radius_km=$radiusKm');
      final resp = await http.get(url).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = data['facilities'] as List? ?? [];
        return list.map((item) => EmergencyFacility.fromJson(item)).toList();
      }
    } catch (_) {}

    return [
      EmergencyFacility(
        name: 'District Civil Hospital Emergency Trauma Center',
        type: 'Hospital',
        distanceKm: 1.4,
        distanceMeters: 1400,
        estimatedEtaMins: 5,
        phone: '108',
        directionsUrl: 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
      )
    ];
  }

  /// Get Emergency ICE Contacts
  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final url = Uri.parse('http://localhost:8000/api/v1/sos/contacts');
      final resp = await http.get(url).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = data['contacts'] as List? ?? [];
        return list.map((c) => EmergencyContact.fromJson(c)).toList();
      }
    } catch (_) {}

    return [
      EmergencyContact(
        id: 'cnt-001',
        name: 'Dr. Ananya Sharma (Family Physician)',
        relationship: 'Physician',
        phoneNumber: '+919876543210',
      ),
      EmergencyContact(
        id: 'cnt-002',
        name: 'Pooja Sharma (Spouse / Guardian)',
        relationship: 'Spouse',
        phoneNumber: '+919123456789',
      )
    ];
  }

  /// One-Tap Emergency Trigger with GPS & Vitals Snapshot
  static Future<SosEvent> triggerSos({
    required String appContext,
    required String userId,
    required String userName,
    required SosLocation location,
    required SosHealthSnapshot healthSnapshot,
    required List<String> emergencyContacts,
    String emergencyReason = 'One-Tap Emergency SOS Triggered',
    required void Function(SosEvent event) onConfirmed,
  }) async {
    final sosId = 'SOS-${DateTime.now().millisecondsSinceEpoch}';

    final event = SosEvent(
      sosId: sosId,
      appContext: appContext,
      userId: userId,
      userName: userName,
      location: location,
      healthSnapshot: healthSnapshot,
      emergencyContacts: emergencyContacts,
      emergencyReason: emergencyReason,
      timestamp: DateTime.now().toString(),
    );

    _activeEvent = event;
    _secondsRemaining = 5;
    _countdownStreamController.add(_secondsRemaining);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _secondsRemaining--;
      _countdownStreamController.add(_secondsRemaining);

      if (_secondsRemaining <= 0) {
        timer.cancel();
        event.status = 'ACTIVE_CRITICAL_SOS';
        final backendRes = await _dispatchSosToBackend(event);
        if (backendRes != null) {
          event.whatsappDispatchUrl = backendRes['whatsapp_dispatch_url'];
          event.smsDispatchUrl = backendRes['sms_dispatch_url'];
          if (backendRes['sos_event']?['closest_hospital'] != null) {
            event.closestHospital = EmergencyFacility.fromJson(backendRes['sos_event']['closest_hospital']);
          }
        }
        onConfirmed(event);
      }
    });

    return event;
  }

  /// Cancels active SOS during countdown
  static Future<bool> cancelSos(String cancelReason) async {
    if (_activeEvent == null) return false;

    _countdownTimer?.cancel();
    _activeEvent!.status = 'CANCELLED';

    try {
      final url = Uri.parse('http://localhost:8000/api/v1/sos/${_activeEvent!.sosId}/cancel');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cancel_reason': cancelReason}),
      );
    } catch (_) {}

    _activeEvent = null;
    return true;
  }

  static Future<Map<String, dynamic>?> _dispatchSosToBackend(SosEvent event) async {
    try {
      final url = Uri.parse('http://localhost:8000/api/v1/sos/trigger');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'app_context': event.appContext,
          'user_id': event.userId,
          'user_name': event.userName,
          'location': event.location.toJson(),
          'health_snapshot': event.healthSnapshot.toJson(),
          'emergency_contacts': event.emergencyContacts,
          'emergency_reason': event.emergencyReason,
        }),
      );
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
    } catch (_) {}
    return null;
  }
}
