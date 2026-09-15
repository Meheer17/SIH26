import 'package:flutter/material.dart';

class PersonnelWellnessTab extends StatefulWidget {
  const PersonnelWellnessTab({super.key});

  @override
  State<PersonnelWellnessTab> createState() => _PersonnelWellnessTabState();
}

class _PersonnelWellnessTabState extends State<PersonnelWellnessTab> with SingleTickerProviderStateMixin {
  // Privacy Consent Hub Toggles
  bool _airGappedLocalEnclave = true;
  bool _wearableSyncOptIn = true;
  bool _voiceJournalOptIn = false;
  bool _selfCheckOptIn = true;

  // Screening State
  int _activeScreeningQuestion = 0;
  final List<int> _screeningAnswers = [2, 1, 0, 1]; // PHQ-4 / GAD-2 responses
  bool _screeningCompleted = false;

  // Voice Journal State
  bool _isRecordingVoice = false;
  String _voiceJournalText = "Recorded: 'Completed 12-hour border night patrol. Feeling physically exhausted but mentally stable.'";

  // Box Breathing State
  bool _isBreathingActive = false;
  int _breathPhase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  final List<String> _breathInstructions = ['INHALE (4s)', 'HOLD (4s)', 'EXHALE (4s)', 'HOLD (4s)'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner: Zero-Stigma Air-Gapped Status
          _buildAirGappedHeader(),
          const SizedBox(height: 20),

          // Voluntary Telemetry Consent Hub
          _buildConsentHubCard(),
          const SizedBox(height: 20),

          // Micro-Screening & Vernacular Voice Journal
          _buildMicroScreeningCard(),
          const SizedBox(height: 20),

          // Biometric Vitals Sync Engine & Circadian Rest Monitor
          _buildBiometricSyncCard(),
          const SizedBox(height: 20),

          // Tactical Resilience & 4-4-4-4 Box Breathing
          _buildTacticalBreathingCard(),
          const SizedBox(height: 20),

          // Family Welfare & Direct Confidential Tele-Counseling Booker
          _buildSupportAndInterventionCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAirGappedHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Zero-Stigma Air-Gapped Mode',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ENCLAVE ENCRYPTED', style: TextStyle(color: Color(0xFF16A34A), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Runs 100% locally on your device. Self-assessments & logs are encrypted in Secure Enclave and never transmitted to commanders without consent.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentHubCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tune, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Voluntary Telemetry Consent Hub',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Full granular control over what metrics are synced. Revoke any permission at any time with total institutional trust.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Wearable Vitals Sync (RHR & HRV)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Sync fitness tracker data for physical recovery tracking.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _wearableSyncOptIn,
            activeTrackColor: const Color(0xFF0284C7),
            onChanged: (v) => setState(() => _wearableSyncOptIn = v),
          ),
          const Divider(color: Color(0xFFE2E8F0)),
          SwitchListTile(
            title: const Text('Vernacular Voice Diary Processing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Process local audio valence in regional dialect without raw audio upload.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _voiceJournalOptIn,
            activeTrackColor: const Color(0xFF7C3AED),
            onChanged: (v) => setState(() => _voiceJournalOptIn = v),
          ),
          const Divider(color: Color(0xFFE2E8F0)),
          SwitchListTile(
            title: const Text('Voluntary Self-Checkin Sharing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Share aggregate wellness scores anonymously with Unit Medical Officer.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _selfCheckOptIn,
            activeTrackColor: const Color(0xFF059669),
            onChanged: (v) => setState(() => _selfCheckOptIn = v),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroScreeningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.quiz_outlined, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text(
                    'Conversational Micro-Screening (PHQ-4 / GAD-2)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                child: const Text('60-SEC CHECKIN', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Replaces clinical forms with a quick interactive check-in assessing sleep, mood, and operational fatigue.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (!_screeningCompleted) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_activeScreeningQuestion + 1} of 4:',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _activeScreeningQuestion == 0
                        ? 'Over the last 2 weeks, how often have you felt down, depressed, or hopeless after shifts?'
                        : (_activeScreeningQuestion == 1
                            ? 'How often have you felt nervous, anxious, or on edge during operational duty?'
                            : (_activeScreeningQuestion == 2
                                ? 'Are you experiencing trouble sleeping or severe fatigue during night patrols?'
                                : 'How often do you feel little interest or pleasure in daily routine tasks?')),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _buildScreeningOption('Not at all', 0),
                      const SizedBox(width: 6),
                      _buildScreeningOption('Several days', 1),
                      const SizedBox(width: 6),
                      _buildScreeningOption('More than half', 2),
                      const SizedBox(width: 6),
                      _buildScreeningOption('Nearly every day', 3),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Micro-Screening Completed! Wellness Score: 85/100 (Optimal Operational Resilience). Next check-in due in 48 hours.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Vernacular Voice Wellness Journal
          Row(
            children: const [
              Icon(Icons.mic, color: Color(0xFFEA580C)),
              SizedBox(width: 8),
              Text(
                'Vernacular Voice Journal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isRecordingVoice ? Icons.stop_circle : Icons.mic, color: const Color(0xFFEA580C)),
                  onPressed: () {
                    setState(() {
                      _isRecordingVoice = !_isRecordingVoice;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    _isRecordingVoice ? 'Recording vernacular audio locally...' : _voiceJournalText,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningOption(String text, int value) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () {
          setState(() {
            _screeningAnswers[_activeScreeningQuestion] = value;
            if (_activeScreeningQuestion < 3) {
              _activeScreeningQuestion++;
            } else {
              _screeningCompleted = true;
            }
          });
        },
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBiometricSyncCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.watch, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    'Biometric Vitals & Circadian Rest Monitor',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                child: const Text('BLE SYNC ACTIVE', style: TextStyle(color: Color(0xFF0284C7), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ingests Resting Heart Rate (RHR), HRV, and sleep debt caused by extended guard shifts or rapid deployment rotations.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildBiometricTile('Resting HR', '62 bpm', 'Optimal', Icons.favorite, const Color(0xFFE11D48)),
              const SizedBox(width: 8),
              _buildBiometricTile('HRV Score', '58 ms', 'High Recovery', Icons.timeline, const Color(0xFF059669)),
              const SizedBox(width: 8),
              _buildBiometricTile('Sleep Debt', '1.5 hrs', 'Post Night Duty', Icons.bedtime, const Color(0xFFD97706)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricTile(String label, String value, String status, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            Text(status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticalBreathingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.air, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text(
                    'Tactical Resilience & 4-4-4-4 Box-Breathing',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBreathingActive ? const Color(0xFFE11D48) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: Icon(_isBreathingActive ? Icons.pause : Icons.play_arrow, size: 14),
                label: Text(_isBreathingActive ? 'Stop' : 'Start Pacing', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    _isBreathingActive = !_isBreathingActive;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Haptic-guided respiratory pacing lowers sympathetic nervous system arousal during high-stress operational pauses.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          Center(
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              width: _isBreathingActive ? 120 : 90,
              height: _isBreathingActive ? 120 : 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: _isBreathingActive ? 0.2 : 0.1),
                border: Border.all(color: const Color(0xFF059669), width: 3),
              ),
              child: Center(
                child: Text(
                  _isBreathingActive ? _breathInstructions[_breathPhase] : 'TAP START',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAndInterventionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.headset_mic_outlined, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'Direct Intervention & Family Welfare Connect',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Confidential Tele-Counseling', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                      SizedBox(height: 2),
                      Text('Direct 1-on-1 booking with certified external psychologists without command visibility.', style: TextStyle(fontSize: 9, color: Color(0xFF475569))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Anonymous Buddy Portal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                      SizedBox(height: 2),
                      Text('Connect pseudonymously with peer support soldiers across units without career penalty.', style: TextStyle(fontSize: 9, color: Color(0xFF475569))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
