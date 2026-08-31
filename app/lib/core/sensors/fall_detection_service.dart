import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class FallDetectionService {
  static final FallDetectionService _instance = FallDetectionService._internal();
  factory FallDetectionService() => _instance;
  FallDetectionService._internal();

  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  bool _isListening = false;
  bool _freefallDetected = false;
  DateTime? _freefallTime;

  // Threshold constants
  static const double FREEFALL_THRESHOLD = 3.5;  // m/s^2 near zero gravity drop
  static const double IMPACT_THRESHOLD = 25.0;   // m/s^2 severe high-impact threshold

  void startMonitoring({required Function() onFallDetected}) {
    if (_isListening) return;

    try {
      _isListening = true;
      _accelSubscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          // Calculate acceleration vector magnitude G
          final double magnitude = sqrt(
            (event.x * event.x) + (event.y * event.y) + (event.z * event.z)
          );

          // 1. Detect low-gravity freefall signature
          if (magnitude < FREEFALL_THRESHOLD) {
            _freefallDetected = true;
            _freefallTime = DateTime.now();
          }

          // 2. Detect sudden severe impact G-force spike
          if (magnitude > IMPACT_THRESHOLD) {
            final now = DateTime.now();
            // Verify impact occurred within 1.5 seconds of freefall
            if (_freefallDetected &&
                _freefallTime != null &&
                now.difference(_freefallTime!).inMilliseconds < 1500) {
              _freefallDetected = false;
              _freefallTime = null;
              debugPrint("⚠️ CRITICAL ACCELEROMETER FALL SIGNATURE DETECTED! G=$magnitude");
              onFallDetected();
            } else if (magnitude > (IMPACT_THRESHOLD * 1.2)) {
              // Direct severe impact fall signature
              debugPrint("⚠️ DIRECT SEVERE IMPACT FALL DETECTED! G=$magnitude");
              onFallDetected();
            }
          }
        },
        onError: (error) {
          debugPrint("Accelerometer Stream Error: $error");
        },
      );
    } catch (e) {
      debugPrint("Could not start accelerometer listener: $e");
    }
  }

  void stopMonitoring() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
    _isListening = false;
  }
}
