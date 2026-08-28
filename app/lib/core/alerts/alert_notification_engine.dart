import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum AlertSeverity { low, moderate, high, criticalSos }

class AppAlertRecord {
  final String alertId;
  final String appContext;
  final AlertSeverity severity;
  final String title;
  final String message;
  final List<String> channels;
  final List<String> recipients;
  final int escalationTimeoutSeconds;
  bool isAcknowledged;
  final String timestamp;

  AppAlertRecord({
    required this.alertId,
    required this.appContext,
    required this.severity,
    required this.title,
    required this.message,
    required this.channels,
    required this.recipients,
    required this.escalationTimeoutSeconds,
    this.isAcknowledged = false,
    required this.timestamp,
  });
}

class AlertNotificationEngine {
  static final List<AppAlertRecord> _activeAlerts = [];
  static final StreamController<AppAlertRecord> _alertStreamController = StreamController<AppAlertRecord>.broadcast();

  static Stream<AppAlertRecord> get alertStream => _alertStreamController.stream;
  static List<AppAlertRecord> get activeAlerts => List.unmodifiable(_activeAlerts);

  /// Dispatches a multi-tier alert and sets escalation timers
  static Future<AppAlertRecord> dispatchAlert({
    required String appContext,
    required AlertSeverity severity,
    required String title,
    required String message,
    required List<String> recipients,
    int escalationTimeoutSeconds = 60,
  }) async {
    final alertId = 'ALT-${DateTime.now().millisecondsSinceEpoch}';
    final severityStr = severity.name.toUpperCase();

    List<String> channels = ['IN_APP_BANNER'];
    if (severity == AlertSeverity.moderate) {
      channels.addAll(['PUSH_NOTIFICATION']);
    } else if (severity == AlertSeverity.high) {
      channels.addAll(['PUSH_NOTIFICATION', 'SMS_DISPATCH']);
    } else if (severity == AlertSeverity.criticalSos) {
      channels.addAll(['PUSH_NOTIFICATION', 'SMS_DISPATCH', 'EMERGENCY_CALL_DISPATCH', 'LOUD_ALARM_TRIGGER']);
    }

    final record = AppAlertRecord(
      alertId: alertId,
      appContext: appContext,
      severity: severity,
      title: title,
      message: message,
      channels: channels,
      recipients: recipients,
      escalationTimeoutSeconds: escalationTimeoutSeconds,
      timestamp: DateTime.now().toString(),
    );

    _activeAlerts.insert(0, record);
    _alertStreamController.add(record);

    // Send payload to Backend API
    try {
      final url = Uri.parse('http://localhost:8000/api/v1/alerts/dispatch');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'app_context': appContext,
          'severity': severityStr == 'CRITICALSOS' ? 'CRITICAL_SOS' : severityStr,
          'title': title,
          'message': message,
          'recipients': recipients,
          'escalation_timeout_seconds': escalationTimeoutSeconds,
        }),
      );
    } catch (_) {}

    // Set escalation timer for unacknowledged alerts
    if (severity != AlertSeverity.criticalSos) {
      Timer(Duration(seconds: escalationTimeoutSeconds), () {
        if (!record.isAcknowledged) {
          _escalateAlert(record);
        }
      });
    }

    return record;
  }

  static void _escalateAlert(AppAlertRecord record) {
    record.isAcknowledged = false;
    dispatchAlert(
      appContext: record.appContext,
      severity: AlertSeverity.criticalSos,
      title: '🚨 ESCALATED: ${record.title}',
      message: 'Unacknowledged after ${record.escalationTimeoutSeconds}s: ${record.message}',
      recipients: record.recipients,
    );
  }

  /// Acknowledges alert and stops escalation
  static void acknowledgeAlert(String alertId) {
    for (final alert in _activeAlerts) {
      if (alert.alertId == alertId) {
        alert.isAcknowledged = true;
        break;
      }
    }
  }
}
