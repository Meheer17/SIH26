import 'dart:async';
import 'package:flutter/material.dart';
import '../services/nyaya_manas_service.dart';
import '../../../../core/speech/speech_service.dart';
import '../../../creative/panic_disguise_screen.dart';
import 'victim_onboarding_wizard.dart';

class VictimViewScreen extends StatefulWidget {
  final String victimId;
  final VoidCallback? onRefresh;

  const VictimViewScreen({
    super.key,
    this.victimId = 'V-UP-VAR-8842',
    this.onRefresh,
  });

  @override
  State<VictimViewScreen> createState() => _VictimViewScreenState();
}

class _VictimViewScreenState extends State<VictimViewScreen> {
  final _service = NyayaManasService();
  final _speechService = SpeechService();

  bool _loading = true;
  Map<String, dynamic>? _victimDossier;

  // Bottom Nav State (0: Home & Score, 1: Voice & Chat, 2: Relief & Courts, 3: Helpline & Exercises)
  int _selectedNavIndex = 0;

  // Voice recording & checkin state
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String _selectedLanguage = 'hi';
  List<double> _waveform = [0.2, 0.4, 0.7, 0.3, 0.8, 0.5, 0.9, 0.4, 0.6];
  Map<String, dynamic>? _lastCheckInResult;

  // 4-7-8 Breathing Exercise State
  bool _isBreathing = false;
  int _breathSeconds = 0;
  String _breathPhase = 'Inhale';
  Timer? _breathTimer;

  // Chat state
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<Map<String, dynamic>> _chatHistory = [
    {
      'sender': 'bot',
      'text': 'नमस्ते सावित्री जी! मैं न्याय-मानस हूँ, SC/ST अत्याचार निवारण अधिनियम सहायता नेटवर्क के तहत आपका 24x7 देखभाल साथी। आज आप कैसा महसूस कर रही हैं?',
      'time': '10:00 AM',
      'emotion': 'CALM'
    }
  ];
  bool _chatSending = false;

  // Voice check-in state & scenario presets
  final TextEditingController _voiceTranscriptController = TextEditingController(
    text: "I am feeling safe and supported today. Everything is calm in my home and village.",
  );
  int _selectedVoicePreset = 0; // 0: Calm, 1: Delay/Finance, 2: Court Dread, 3: Armed Intimidation

  final List<Map<String, String>> _voiceScenarios = [
    {
      'label': '🟢 Calm & Safe',
      'desc': 'Baseline low distress',
      'text': 'I am feeling safe and supported today. Everything is calm in my home and village.',
    },
    {
      'label': '🟡 Delay Anxiety',
      'desc': 'Rule 12(4) DBT relief concern',
      'text': 'I am stressed about case delays and desperately waiting for my 50% Rule 12(4) statutory compensation DBT.',
    },
    {
      'label': '🟠 Court Dread',
      'desc': 'Testimony anticipatory panic',
      'text': 'My witness cross-examination in the Special Court is tomorrow morning. I am terrified and trembling.',
    },
    {
      'label': '🔴 Armed Intimidation',
      'desc': 'Direct retaliation threat',
      'text': 'The accused relatives visited my house with weapons and threatened to kill my family if I go to court.',
    },
  ];

  // IVRS simulator state
  int _selectedDtmf = 1;
  String? _ivrsAudioOutput;
  bool _ivrsCalling = false;

  // SOS state
  bool _sosDispatched = false;

  final List<Map<String, String>> _dialectOptions = [
    {'code': 'hi', 'label': 'Hindi (Bhojpuri / Awadhi)'},
    {'code': 'ta', 'label': 'Tamil (Madurai / Kongu)'},
    {'code': 'te', 'label': 'Telugu (Rayalaseema / Coastal)'},
    {'code': 'mr', 'label': 'Marathi (Vidarbha / Marathwada)'},
    {'code': 'bn', 'label': 'Bengali (Rarh / Varandra)'},
    {'code': 'en', 'label': 'English (Indian Standard)'},
  ];

  @override
  void initState() {
    super.initState();
    _speechService.init();
    _loadData();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _breathTimer?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    _voiceTranscriptController.dispose();
    super.dispose();
  }

  void _toggleBreathingExercise() {
    if (_isBreathing) {
      _breathTimer?.cancel();
      setState(() {
        _isBreathing = false;
        _breathSeconds = 0;
      });
    } else {
      setState(() {
        _isBreathing = true;
        _breathSeconds = 4;
        _breathPhase = 'Inhale';
      });
      _breathTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_breathSeconds > 1) {
            _breathSeconds--;
          } else {
            if (_breathPhase == 'Inhale') {
              _breathPhase = 'Hold';
              _breathSeconds = 7;
            } else if (_breathPhase == 'Hold') {
              _breathPhase = 'Exhale';
              _breathSeconds = 8;
            } else {
              _breathPhase = 'Inhale';
              _breathSeconds = 4;
            }
          }
        });
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await _service.fetchRoleDashboard('victim', victimId: widget.victimId);
      if (mounted) {
        setState(() {
          _victimDossier = res['victim_dossier'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecordingAndSubmit();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordDuration = 0;
    });

    // Capture real microphone speech in real-time
    _speechService.listen(
      onResult: (spokenText) {
        if (!mounted) return;
        setState(() {
          _voiceTranscriptController.text = spokenText;
        });
      },
      onStatusChange: (listening) {
        if (!mounted) return;
        if (!listening && _isRecording) {
          // Keep recording timer active
        }
      },
    );

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordDuration++;
        _waveform = List.generate(9, (i) => 0.15 + (0.75 * ((timer.tick + i) % 4) / 4.0));
      });
    });
  }

  Future<void> _stopRecordingAndSubmit() async {
    _recordTimer?.cancel();
    await _speechService.stopListening();
    setState(() => _isRecording = false);

    final transcript = _voiceTranscriptController.text.trim().isNotEmpty
        ? _voiceTranscriptController.text.trim()
        : "I am feeling safe and supported today.";

    final duration = _recordDuration > 0 ? _recordDuration : 15;
    final words = transcript.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;
    final speechRateWpm = duration > 0 ? ((wordCount / duration) * 60.0).clamp(60.0, 240.0) : 135.0;

    final textLower = transcript.toLowerCase();
    final bool threatFlag = textLower.contains('threat') ||
        textLower.contains('kill') ||
        textLower.contains('dhamki') ||
        textLower.contains('hathiyaar') ||
        textLower.contains('goli') ||
        textLower.contains('maar');

    final payload = {
      'victim_id': widget.victimId,
      'channel': 'ivrs',
      'language': _selectedLanguage,
      'text_content': transcript,
      'audio_duration_sec': duration.toDouble(),
      'speech_rate_wpm': speechRateWpm,
      'engagement_latency_hours': 1.5,
      'reported_threat': threatFlag,
    };

    try {
      final result = await _service.submitCheckIn(payload);
      if (mounted) {
        setState(() {
          _lastCheckInResult = result;
          if (_victimDossier != null && result['computed_dds'] != null) {
            _victimDossier!['dds_score'] = result['computed_dds']['dds_score'];
            _victimDossier!['risk_tier'] = result['computed_dds']['risk_tier'];
            _victimDossier!['risk_color'] = result['computed_dds']['risk_color'];
          }
        });

        final dds = result['computed_dds']?['dds_score'] ?? 50;
        final emotion = result['voice_analysis']?['emotion'] ?? result['voice_analysis']?['emotion_classification'] ?? 'STABLE';
        final riskTier = result['computed_dds']?['risk_tier'] ?? 'MODERATE';

        _speechService.speak("Voice check-in analyzed. Dynamic distress score is $dds. Emotion classified as $emotion.");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: dds >= 76
                ? const Color(0xFFE11D48)
                : (dds >= 50 ? const Color(0xFFEA580C) : const Color(0xFF059669)),
            content: Text('✅ Voice Analyzed: DDS $dds/100 ($riskTier / $emotion) • Live Synced!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _sendChatMessage([String? customMessage]) async {
    final text = (customMessage ?? _chatController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _chatHistory.add({
        'sender': 'user',
        'text': text,
        'time': 'Just now',
      });
      if (customMessage == null) _chatController.clear();
      _chatSending = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final res = await _service.sendChatMessage(
        victimId: widget.victimId,
        message: text,
        language: _selectedLanguage,
      );

      if (mounted) {
        setState(() {
          _chatHistory.add({
            'sender': 'bot',
            'text': res['bot_reply'] ?? 'Your message has been safely logged with your assigned counselor.',
            'emotion': res['detected_emotion'],
            'time': 'Just now',
          });
          _chatSending = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _chatSending = false);
      }
    }
  }

  Future<void> _simulateIvrs(int dtmf) async {
    setState(() {
      _selectedDtmf = dtmf;
      _ivrsCalling = true;
    });

    try {
      final res = await _service.simulateIvrs(
        victimId: widget.victimId,
        phoneNumber: '+919876543210',
        dtmfChoice: dtmf,
        language: _selectedLanguage,
      );

      if (mounted) {
        setState(() {
          _ivrsAudioOutput = res['audio_response'];
          _ivrsCalling = false;
        });
        if (_ivrsAudioOutput != null) {
          _speechService.speak(_ivrsAudioOutput!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ivrsCalling = false);
      }
    }
  }

  Future<void> _triggerSos() async {
    setState(() => _sosDispatched = true);
    try {
      await _service.triggerSosBeacon(
        victimId: widget.victimId,
        threatDescription: 'Witness intimidation beacon triggered from mobile app',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE11D48),
            duration: Duration(seconds: 5),
            content: Text('🚨 SILENT SOS BEACON DISPATCHED! Geofenced GPS Push Sent to Police SP & DM Cell!'),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }

    final ddsScore = (_victimDossier?['dds_score'] as num?)?.toDouble() ?? 78.4;
    final riskTier = (_victimDossier?['risk_tier'] as String?) ?? 'HIGH';
    final victimName = _victimDossier?['full_name'] ?? 'Savitri Devi';
    final firNumber = _victimDossier?['fir_number'] ?? 'FIR-2026/0412-SCST';
    final district = _victimDossier?['district'] ?? 'Varanasi';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF7C3AED),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedNavIndex == 0) ...[
                // Victim Header Banner
                _buildVictimHeaderCard(victimName, firNumber, district),
                const SizedBox(height: 16),

                // Stealth Disguise & SOS Action Bar
                _buildStealthAndSosBar(context),
                const SizedBox(height: 16),

                // Live Dynamic Distress Score Gauge Card
                _buildDdsScoreCard(ddsScore, riskTier),
              ] else if (_selectedNavIndex == 1) ...[
                // Dialect-Aware Voice IVRS 14566 Check-In Section
                _buildVoiceCheckInCard(),
                const SizedBox(height: 16),

                // Trauma-Informed AI Companion Chatbot
                _buildAiChatCard(),
              ] else if (_selectedNavIndex == 2) ...[
                // Statutory SC/ST Relief Compensation Tracker
                _buildCompensationReliefCard(),
                const SizedBox(height: 16),

                // e-Courts & CCTNS Judicial Milestone Timeline
                _buildMilestonesCard(),
              ] else if (_selectedNavIndex == 3) ...[
                // NHAA 14566 Interactive Voice Response Simulator
                _buildIvrsSimulatorCard(),
                const SizedBox(height: 16),

                // 4-7-8 Breathing & Grounding
                _buildBreathingExerciseCard(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (idx) => setState(() => _selectedNavIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF7C3AED),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety_outlined),
              activeIcon: Icon(Icons.health_and_safety),
              label: 'Home & Score',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.record_voice_over_outlined),
              activeIcon: Icon(Icons.record_voice_over),
              label: 'Voice & Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Relief & Courts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.self_improvement_outlined),
              activeIcon: Icon(Icons.self_improvement),
              label: 'Helpline & Help',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictimHeaderCard(String name, String fir, String dist) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFF3E8FF),
            child: const Icon(Icons.person_pin, color: Color(0xFF7C3AED), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('SC/ST Beneficiary', style: TextStyle(color: Color(0xFF15803D), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$fir • $dist District • Assigned: Dr. Ananya Sharma (NIMHANS/DMHP)',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final newId = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VictimOnboardingWizardScreen(
                          onOnboardingComplete: (id) => _loadData(),
                        ),
                      ),
                    );
                    if (newId != null) _loadData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD8B4FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.app_registration, size: 12, color: Color(0xFF7C3AED)),
                        SizedBox(width: 4),
                        Text('Launch 5-Step Onboarding Wizard', style: TextStyle(color: Color(0xFF6B21A8), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStealthAndSosBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _sosDispatched ? const Color(0xFFBE185D) : const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.emergency_share, size: 18),
            label: Text(
              _sosDispatched ? 'SOS ACTIVE (POLICE EN ROUTE)' : 'SILENT SOS BEACON',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: _triggerSos,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: const Text('DISGUISE APP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PanicDisguiseScreen()));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDdsScoreCard(double score, String tier) {
    Color tierColor = const Color(0xFF059669);
    if (score >= 76) {
      tierColor = const Color(0xFFE11D48);
    } else if (score >= 51) {
      tierColor = const Color(0xFFEA580C);
    } else if (score >= 26) {
      tierColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 4)),
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
                  Icon(Icons.speed, color: Color(0xFF7C3AED), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'DYNAMIC DISTRESS SCORE (DDS)',
                    style: TextStyle(color: Color(0xFF581C87), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tierColor),
                ),
                child: Text(
                  tier,
                  style: TextStyle(color: tierColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 9,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.toStringAsFixed(1),
                        style: TextStyle(color: tierColor, fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                      const Text('/ 100', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Predictive Crisis Assessment:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score >= 76
                          ? '⚠️ Critical distress spike flagged. Preemptive counseling & witness protection escorts have been notified.'
                          : 'Distress trajectory is being actively supervised alongside statutory case milestones.',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCheckInCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4)),
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
                  Icon(Icons.mic_none_outlined, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text(
                    'Dialect-Aware Voice Check-In',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                child: const Text('IVRS 14566', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Analyzes acoustic vocal micro-tremors, Fundamental Frequency (f₀), speech cadence, and sentiment to compute your live Dynamic Distress Score (DDS).',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Dialect Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            decoration: InputDecoration(
              labelText: 'Preferred Dialect / Language',
              labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            items: _dialectOptions.map((d) {
              return DropdownMenuItem(value: d['code'], child: Text(d['label']!, style: const TextStyle(fontSize: 12)));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedLanguage = val;
                });
              }
            },
          ),
          const SizedBox(height: 14),

          // Quick Prompts / Live Voice Check-In
          const Text(
            'Quick Speech Prompts (or speak freely into live mic):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_voiceScenarios.length, (idx) {
                final sc = _voiceScenarios[idx];
                final isSelected = _selectedVoicePreset == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      sc['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFF3E8FF),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1)),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedVoicePreset = idx;
                          _voiceTranscriptController.text = sc['text'] as String;
                        });
                      }
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Editable Voice Transcript / Note
          TextField(
            controller: _voiceTranscriptController,
            maxLines: 2,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Spoken / Transcribed Voice Note',
              labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              hintText: 'Type or speak your check-in thoughts...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 14),

          // Mic Recording Bar & Waveform
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isRecording ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isRecording ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: _isRecording ? const Color(0xFFE11D48) : const Color(0xFF7C3AED),
                    child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRecording ? 'Recording Voice Check-in (${_recordDuration}s)...' : 'Tap Mic to Record or Submit Transcript',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: _isRecording ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: _waveform.map((h) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 5,
                              height: 18 * h,
                              decoration: BoxDecoration(
                                color: _isRecording ? const Color(0xFFE11D48) : const Color(0xFF7C3AED),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRecording ? _toggleRecording : _stopRecordingAndSubmit,
                  icon: Icon(_isRecording ? Icons.check_circle : Icons.upload_file, size: 14),
                  label: Text(_isRecording ? 'Finish' : 'Analyze'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          if (_lastCheckInResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_outlined, size: 16, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 6),
                          Text(
                            'Emotion AI: ${_lastCheckInResult!["voice_analysis"]?["emotion"] ?? "CALM"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF581C87)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ((_lastCheckInResult!["computed_dds"]?["dds_score"] ?? 50) as num) >= 76
                              ? const Color(0xFFE11D48)
                              : (((_lastCheckInResult!["computed_dds"]?["dds_score"] ?? 50) as num) >= 50
                                  ? const Color(0xFFEA580C)
                                  : const Color(0xFF059669)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'DDS: ${_lastCheckInResult!["computed_dds"]?["dds_score"] ?? "50"}/100 (${_lastCheckInResult!["computed_dds"]?["risk_tier"] ?? "MODERATE"})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Tremor: ${(_lastCheckInResult!["voice_analysis"]?["vocal_tremor_score"] ?? 0.15).toString()}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                      Text(
                        'Pitch Var: ${_lastCheckInResult!["voice_analysis"]?["acoustic_markers"]?["pitch_variance_hz"] ?? 18} Hz',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                      Text(
                        'Speech Rate: ${_lastCheckInResult!["voice_analysis"]?["acoustic_markers"]?["speech_rate_wpm"] ?? 135} WPM',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      final dds = _lastCheckInResult!["computed_dds"]?["dds_score"] ?? 50;
                      final emo = _lastCheckInResult!["voice_analysis"]?["emotion"] ?? "CALM";
                      final tier = _lastCheckInResult!["computed_dds"]?["risk_tier"] ?? "MODERATE";
                      _speechService.speak("Voice analysis complete. Dynamic distress score is $dds. Risk tier is $tier. Emotion is $emo.");
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.volume_up, size: 14, color: Color(0xFF7C3AED)),
                        SizedBox(width: 4),
                        Text('🔊 Listen to Voice Analysis Voiceover', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                      ],
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

  Widget _buildAiChatCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4)),
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
                  Icon(Icons.chat_bubble_outline, color: Color(0xFF0D9488)),
                  SizedBox(width: 8),
                  Text(
                    'Trauma-Informed AI Companion',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(8)),
                child: const Text('24x7 ACTIVE', style: TextStyle(color: Color(0xFF0D9488), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Context-aware, multilingual companion for court anxiety, safety threats, relief tracking & calming exercises.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 10),

          // Quick Prompt Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChatChip('🏛️ Court Testimony Fear', 'कल कोर्ट में पेशी है मुझे बहुत डर लग रहा है'),
                _buildQuickChatChip('💰 50% Relief Compensation', 'मेरा 50% मुआवजा कब तक बैंक खाते में आएगा?'),
                _buildQuickChatChip('🌸 4-7-8 Breathing Help', 'I am having a severe panic attack, please guide me in breathing'),
                _buildQuickChatChip('🚨 Death Threat Alert', 'The accused relatives came to my house with weapons and threatened me'),
                _buildQuickChatChip('⚖️ Free DLSA Legal Aid', 'क्या मुझे मुफ्त वकील मिल सकता है?'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Chat Messages List
          Container(
            height: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.builder(
              controller: _chatScrollController,
              itemCount: _chatHistory.length,
              itemBuilder: (context, idx) {
                final msg = _chatHistory[idx];
                final isUser = msg['sender'] == 'user';
                final emotion = msg['emotion'] as String?;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 290),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF7C3AED) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: isUser ? null : const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isUser && emotion != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: emotion == 'FEAR'
                                  ? const Color(0xFFFEE2E2)
                                  : (emotion == 'HIGH_ANXIETY' ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AI Detected: $emotion',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: emotion == 'FEAR'
                                    ? const Color(0xFFB91C1C)
                                    : (emotion == 'HIGH_ANXIETY' ? const Color(0xFFB45309) : const Color(0xFF0369A1)),
                              ),
                            ),
                          ),
                        ],
                        Text(
                          msg['text'] as String,
                          style: TextStyle(
                            color: isUser ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg['time'] ?? 'Just now',
                              style: TextStyle(
                                color: isUser ? Colors.white70 : const Color(0xFF94A3B8),
                                fontSize: 9,
                              ),
                            ),
                            if (!isUser) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _speechService.speak(msg['text'] as String),
                                child: const Icon(Icons.volume_up, size: 14, color: Color(0xFF7C3AED)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Message Input Field & Send Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Share how you feel, court fears, relief status...',
                    hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                ),
                icon: _chatSending
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, size: 16),
                onPressed: _chatSending ? null : () => _sendChatMessage(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChatChip(String label, String messageToSend) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0FDFA),
        side: const BorderSide(color: Color(0xFF99F6E4)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onPressed: _chatSending ? null : () => _sendChatMessage(messageToSend),
      ),
    );
  }

  Widget _buildIvrsSimulatorCard() {
    final dtmfOptions = [
      {'key': 1, 'label': '1. Emotional Well-being'},
      {'key': 2, 'label': '2. Relief Status'},
      {'key': 3, 'label': '3. SOS Distress'},
      {'key': 4, 'label': '4. Live Counselor'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4)),
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
                  Icon(Icons.phone_in_talk, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    'NHAA 14566 IVRS Telephony Simulator',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                child: _ivrsCalling
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                      )
                    : const Text('TOLL FREE', style: TextStyle(color: Color(0xFF0284C7), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Simulates automated Interactive Voice Response touch-tone keypad for rural & low-literacy beneficiaries.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dtmfOptions.map((d) {
              final key = d['key'] as int;
              final isSelected = _selectedDtmf == key;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                  foregroundColor: isSelected ? Colors.white : const Color(0xFF334155),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _simulateIvrs(key),
                child: Text(d['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),

          if (_ivrsAudioOutput != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: Color(0xFF0284C7), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _ivrsAudioOutput!,
                      style: const TextStyle(color: Color(0xFF0369A1), fontSize: 11, fontWeight: FontWeight.w600),
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

  Widget _buildCompensationReliefCard() {
    final disbursed = (_victimDossier?['statutory_relief_disbursed'] as num?)?.toDouble() ?? 412500.0;
    final total = (_victimDossier?['statutory_relief_total'] as num?)?.toDouble() ?? 825000.0;
    final progress = total > 0 ? (disbursed / total).clamp(0.0, 1.0) : 0.5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4)),
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
                  Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text(
                    'Statutory SC/ST Relief Compensation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                child: const Text('STAGE 2 DISBURSED', style: TextStyle(color: Color(0xFF15803D), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Mandated under SC/ST (PoA) Amendment Rules 2016 Annexure-I. Tracks Direct Benefit Transfer alongside psychological recovery.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Disbursement Progress:', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
              Text(
                '₹ ${disbursed.toStringAsFixed(0)} / ₹ ${total.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('25% on FIR', style: TextStyle(fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
              Text('50% on Chargesheet', style: TextStyle(fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
              Text('25% on Conviction', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesCard() {
    final milestone = _victimDossier?['upcoming_milestone'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.gavel_outlined, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text(
                'e-Courts & CCTNS Judicial Milestone Sync',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Predicts psychological distress spikes ahead of sensitive testimony and bail milestones.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.event_note, color: Color(0xFFD97706), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone?['title'] ?? 'Cross-Examination Testimony',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${milestone?['date'] ?? 'Tomorrow'} • ${milestone?['court'] ?? 'Special Court Varanasi'}',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                  child: const Text('High Impact', style: TextStyle(color: Color(0xFFDC2626), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingExerciseCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.self_improvement, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('Trauma De-escalation: 4-7-8 Breathing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Guided physiological regulation to lower heart rate and reduce cortisol spikes before court hearings.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  width: _isBreathing ? 130 : 100,
                  height: _isBreathing ? 130 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isBreathing ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    border: Border.all(color: _isBreathing ? const Color(0xFF059669) : const Color(0xFFCBD5E1), width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _isBreathing ? '$_breathPhase\n${_breathSeconds}s' : 'Tap to Start',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _isBreathing ? const Color(0xFF065F46) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBreathing ? const Color(0xFFE11D48) : const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _toggleBreathingExercise,
                  icon: Icon(_isBreathing ? Icons.stop : Icons.play_arrow, size: 18),
                  label: Text(_isBreathing ? 'Stop Exercise' : 'Start 4-7-8 Breathing (2 Mins)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
