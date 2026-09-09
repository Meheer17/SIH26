import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_endpoints.dart';

class SosLocation {
  final double latitude;
  final double longitude;
  final String addressName;

  SosLocation({
    required this.latitude,
    required this.longitude,
    required this.addressName,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address_name': addressName,
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
  });
}

class SosEmergencyModule {
  static Timer? _countdownTimer;
  static int _secondsRemaining = 5;
  static SosEvent? _activeEvent;

  static final StreamController<int> _countdownStreamController = StreamController<int>.broadcast();
  static Stream<int> get countdownStream => _countdownStreamController.stream;
  static SosEvent? get activeEvent => _activeEvent;

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
        await _dispatchSosToBackend(event);
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
      final url = Uri.parse(ApiEndpoints.endpoint('sos/${_activeEvent!.sosId}/cancel'));
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cancel_reason': cancelReason}),
      );
    } catch (_) {}

    _activeEvent = null;
    return true;
  }

  static Future<void> _dispatchSosToBackend(SosEvent event) async {
    try {
      final url = Uri.parse(ApiEndpoints.endpoint('sos/trigger'));
      await http.post(
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
    } catch (_) {}
  }
}
