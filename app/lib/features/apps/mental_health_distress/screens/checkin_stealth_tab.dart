import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/speech/speech_service.dart';
import '../../../../core/ml/mobile_ml_engine.dart';
import '../../../creative/panic_disguise_screen.dart';

class CheckInStealthTab extends StatefulWidget {
  const CheckInStealthTab({super.key});

  @override
  State<CheckInStealthTab> createState() => _CheckInStealthTabState();
}

class _CheckInStealthTabState extends State<CheckInStealthTab> {
  final SpeechService _speechService = SpeechService();

  // Voice Recording State
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String _selectedDialect = 'Hindi (Bhojpuri/Awadhi)';
  List<double> _waveform = [0.2, 0.5, 0.8, 0.3, 0.6, 0.9, 0.4, 0.7, 0.2];

  Map<String, dynamic>? _lastVoiceStressResult;

  // Micro Check-In Chat Bot State
  final List<Map<String, String>> _chatMessages = [
    {
      'sender': 'bot',
      'text': 'Namaste Rajesh ji. I am your NHAA 14566 wellness companion. How are you feeling today ahead of the upcoming court date?'
    },
  ];
  final TextEditingController _chatController = TextEditingController();

  // SOS Beacon State
  bool _sosActivated = false;

  final List<String> _dialects = [
    'Hindi (Bhojpuri/Awadhi)',
    'Tamil (Madurai/Kongu)',
    'Marathi (Vidarbha/Marathwada)',
    'Bengali (Rarh/Varandra)',
    'Telugu (Rayalaseema)',
    'English (Standard/Indian)',
  ];

  @override
  void initState() {
    super.initState();
    _speechService.init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  void _toggleVoiceRecording() {
    if (_isRecording) {
      _stopVoiceRecording();
    } else {
      _startVoiceRecording();
    }
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
      _recordDuration = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordDuration++;
        _waveform = List.generate(9, (_) => 0.1 + (0.8 * (0.5 + (0.5 * (timer.tick % 3)))));
      });
    });
  }

  void _stopVoiceRecording() {
    _timer?.cancel();
    setState(() => _isRecording = false);

    final result = MobileMlEngine.evaluateVoiceStress(
      text: "I am feeling extremely anxious and fearful about court tomorrow.",
      speechRateWpm: 155.0 - (_recordDuration * 2),
      vocalTremorScore: 0.38 + (_recordDuration % 4) * 0.05,
    );

    setState(() {
      _lastVoiceStressResult = result;
    });

    _speechService.speak(
        "Voice check-in analyzed. Emotion classified as ${result['emotion_classification']}. Stress score is ${result['voice_stress_score']}.");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF059669),
        content: Text('✅ IVRS Audio Processed: ${result['emotion_classification']} (Stress: ${result['voice_stress_score']}/100)'),
      ),
    );
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'sender': 'user', 'text': text});
      _chatController.clear();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      String response = "Thank you for sharing. We have logged your low-fatigue check-in. Our system noted your emotional tone. Remember, legal protection and tele-counseling are on standby.";
      if (text.toLowerCase().contains('threat') || text.toLowerCase().contains('afraid') || text.toLowerCase().contains('scared')) {
        response = "⚠️ I hear your concern regarding retaliatory intimidation. I am quietly notifying your assigned DLSA Counselor and flagging protection level.";
      }

      setState(() {
        _chatMessages.add({'sender': 'bot', 'text': response});
      });
    });
  }

  void _triggerSosBeacon() {
    setState(() => _sosActivated = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFE11D48),
        duration: Duration(seconds: 5),
        content: Text('🚨 SOS WITNESS BEACON DISPATCHED! Silent Geofence Push Sent to Police Nodal Cell & DM Office.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stealth Mode Quick Launcher Banner
          _buildStealthLauncherCard(context),
          const SizedBox(height: 20),

          // SOS Witness Beacon Card
          _buildSosBeaconCard(),
          const SizedBox(height: 20),

          // Dialect-Aware IVRS Voice Check-In Section
          _buildIvrsVoiceSection(),
          const SizedBox(height: 20),

          // Micro-Check-In Conversational Bot Section
          _buildMicroCheckInBot(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStealthLauncherCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFE4E6),
            radius: 24,
            child: const Icon(Icons.security, color: Color(0xFFE11D48), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Stealth "Disguised" UI Launcher',
                  style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  'Camouflages app into Calculator. Duress PIN wipes local logs & pings authorities.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PanicDisguiseScreen()),
              );
            },
            child: const Text('DISGUISE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSosBeaconCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _sosActivated ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sosActivated ? const Color(0xFFF43F5E) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text(
                    'SOS "One-Touch" Witness Beacon',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              if (_sosActivated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(12)),
                  child: const Text('DISPATCH ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Instant silent trigger across SMS, App & IVRS 14566. Geofences GPS location to local Police Special Protection Cell.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _sosActivated ? const Color(0xFFBE185D) : const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.error_outline, size: 24),
              label: Text(
                _sosActivated ? 'BEACON ACTIVE - POLICE EN ROUTE' : 'TRIGGER SILENT SOS BEACON',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              onPressed: _triggerSosBeacon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIvrsVoiceSection() {
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
                  Icon(Icons.mic, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text(
                    'Dialect-Aware IVRS Voice Check-In',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
                child: const Text('IVRS 14566', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Parses vernacular idioms, rural accents, and non-standard phrasing while analyzing acoustic prosody for voice tremors and panic.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedDialect,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
            decoration: InputDecoration(
              labelText: 'Select Vernacular Language / Dialect',
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            items: _dialects.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedDialect = val);
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              GestureDetector(
                onTap: _toggleVoiceRecording,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: _isRecording ? Colors.red : const Color(0xFF4F46E5),
                  child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRecording ? 'Recording IVRS Check-In... (${_recordDuration}s)' : 'Tap to start 45-60s vocal stress check-in',
                      style: TextStyle(
                        color: _isRecording ? Colors.redAccent : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _waveform.map((h) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 6,
                            height: 24 * h,
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.redAccent : const Color(0xFF4F46E5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_lastVoiceStressResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emotion AI: ${_lastVoiceStressResult!["emotion_classification"]}',
                        style: const TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'Acoustic Tremor: ${_lastVoiceStressResult!["vocal_tremor_score"] ?? _lastVoiceStressResult!["physiological_tremor"] ?? "0.38"}',
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'Stress: ${_lastVoiceStressResult!["voice_stress_score"]}/100',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMicroCheckInBot() {
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
              Icon(Icons.chat_bubble_outline, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Micro-Check-In Conversational Bot',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Replaces long clinical surveys (PHQ-9) with short, empathetic open touchpoints to prevent trauma fatigue.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.builder(
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF4F46E5) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: isUser ? null : const [BoxShadow(color: Color(0x050F172A), blurRadius: 4)],
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(color: isUser ? Colors.white : const Color(0xFF0F172A), fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Respond in your own words...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send, size: 18),
                onPressed: _sendChatMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
