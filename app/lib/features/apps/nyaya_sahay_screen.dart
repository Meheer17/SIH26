import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/speech/speech_service.dart';
import '../../core/ml/mobile_ml_engine.dart';
import 'sc_st_relief_screen.dart';

class NyayaSahayScreen extends StatefulWidget {
  const NyayaSahayScreen({super.key});

  @override
  State<NyayaSahayScreen> createState() => _NyayaSahayScreenState();
}

class _NyayaSahayScreenState extends State<NyayaSahayScreen> {
  final ApiClient _apiClient = ApiClient();
  final _authService = AuthService();
  final SpeechService _speechService = SpeechService();

  double _sentimentValue = -0.3;
  String _selectedStage = 'trial';
  final _daysController = TextEditingController(text: '90');
  final _diaryController = TextEditingController(
    text: 'Feeling anxious and stressed about upcoming court trial testimony.',
  );

  bool _isLoading = false;
  bool _isDictating = false;
  List<dynamic> _history = [];
  List<dynamic> _escalations = [];
  Map<String, dynamic>? _latestResult;
  Map<String, dynamic>? _voiceStressResult;

  @override
  void initState() {
    super.initState();
    _speechService.init();
    _fetchHistory();
    _fetchEscalations();
  }

  void _toggleDictation() {
    if (_isDictating) {
      _speechService.stopListening(onStatusChange: (listening) {
        setState(() {
          _isDictating = listening;
        });
      });
    } else {
      _speechService.listen(
        onResult: (text) {
          setState(() {
            _diaryController.text = text;
          });
        },
        onStatusChange: (listening) {
          setState(() {
            _isDictating = listening;
          });
        },
      );
    }
  }

  Future<void> _analyzeVoiceStress() async {
    final localVoiceMl = MobileMlEngine.evaluateVoiceStress(
      text: _diaryController.text,
    );

    setState(() {
      _voiceStressResult = localVoiceMl;
      _sentimentValue = (localVoiceMl['sentiment_score'] as num).toDouble();
    });

    try {
      final res = await _apiClient.post(
        'apps/nyaya/voice-stress',
        body: {
          'transcript_text': _diaryController.text,
          'pitch_variance': localVoiceMl['pitch_variance'],
          'pause_ratio': localVoiceMl['pause_ratio'],
        },
      );
      setState(() {
        _voiceStressResult = Map<String, dynamic>.from(res);
        _sentimentValue = (res['sentiment_score'] as num).toDouble();
      });

      _speechService.speak("Voice stress index evaluated at ${res['voice_stress_score']}. Sentiment classification is ${res['emotion_classification']}.");
    } catch (e) {
      debugPrint("Voice stress backend error (using local ML): $e");
      _speechService.speak("Voice stress index evaluated at ${localVoiceMl['voice_stress_score']}. Sentiment classification is ${localVoiceMl['emotion_classification']}.");
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await _apiClient.get('apps/nyaya/distress');
      setState(() {
        _history = List<dynamic>.from(res);
        if (_history.isNotEmpty) {
          _latestResult = _history.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading distress checkins: $e');
    }
  }

  Future<void> _fetchEscalations() async {
    final user = _authService.currentUser;
    if (user != null) {
      final isCounselor = user.mappedRoles.contains('COUNSELOR') || user.mappedRoles.contains('SYSTEM_ADMIN');
      if (isCounselor) {
        try {
          final res = await _apiClient.get('apps/nyaya/escalations');
          setState(() {
            _escalations = List<dynamic>.from(res);
          });
        } catch (e) {
          debugPrint('Error loading escalations: $e');
        }
      }
    }
  }

  Future<void> _submitWellbeing() async {
    setState(() {
      _isLoading = true;
    });

    final days = int.tryParse(_daysController.text) ?? 45;
    final diaryText = _diaryController.text;

    final localMlResult = MobileMlEngine.evaluateNyayaDistress(
      sentimentScore: _sentimentValue,
      caseStage: _selectedStage,
      daysSinceIncident: days,
      diaryResponse: diaryText,
    );

    try {
      final res = await _apiClient.post(
        'apps/nyaya/distress',
        body: {
          'sentiment_score': _sentimentValue,
          'case_stage': _selectedStage,
          'days_since_incident': days,
          'recent_checkin_responses': diaryText,
        },
      );

      setState(() {
        _latestResult = Map<String, dynamic>.from(res);
      });
      _fetchHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('✅ Wellbeing log recorded & Dynamic Distress Score updated!'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _latestResult = localMlResult;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offline Mode: Distress score evaluated locally (${localMlResult["distress_score"]})')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acknowledgeAlert(String id) async {
    try {
      await _apiClient.post('alerts/$id/acknowledge');
      _fetchEscalations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Distress alert acknowledged.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error acknowledging alert: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isCounselor = user != null && (user.mappedRoles.contains('COUNSELOR') || user.mappedRoles.contains('SYSTEM_ADMIN'));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          isCounselor ? 'NyayaManas Counselor Desk' : 'NYAYA-MANAS Victim Gateway',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: isCounselor ? _buildCounselorView() : _buildVictimView(),
        ),
      ),
    );
  }

  Widget _buildVictimView() {
    final score = _latestResult?['distress_score'] ?? 58;
    final level = _latestResult?['distress_level'] ?? 'MODERATE_DISTRESS';

    Color gaugeColor = const Color(0xFF10B981);
    if (score > 65) {
      gaugeColor = const Color(0xFFE11D48);
    } else if (score > 40) {
      gaugeColor = const Color(0xFFD97706);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Guidance Box
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCCFBF1)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFF0D9488), size: 18),
                  SizedBox(width: 8),
                  Text(
                    '⚖️ NHAA 14566 Dynamic Distress Monitoring',
                    style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Continuous mental health monitoring throughout trial milestones under SC/ST Act 1989. Early warning alerts automatically dispatch district counselors & witness protection.',
                style: TextStyle(color: Color(0xFF115E59), fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),

        // Live Dynamic Distress Gauge Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dynamic Distress Score',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: gaugeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      level.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: gaugeColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Circular Gauge Representation
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: gaugeColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: gaugeColor),
                      ),
                      const Text('/ 100', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Longitudinal Milestone Progress Bar
              const Text(
                'Longitudinal Trial Milestone Progress',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMilestoneDot('FIR', true),
                  _buildMilestoneLine(true),
                  _buildMilestoneDot('Chargesheet', true),
                  _buildMilestoneLine(true),
                  _buildMilestoneDot('Trial', _selectedStage == 'trial' || _selectedStage == 'conviction'),
                  _buildMilestoneLine(_selectedStage == 'conviction'),
                  _buildMilestoneDot('Relief', _selectedStage == 'conviction'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Checkin Form Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Periodic Outreach Check-in',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),

              Text(
                'Sentiment Polarity: ${_sentimentValue.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              Slider(
                value: _sentimentValue,
                min: -1.0,
                max: 1.0,
                divisions: 20,
                label: _sentimentValue.toStringAsFixed(1),
                activeColor: const Color(0xFF0D9488),
                onChanged: (val) {
                  setState(() {
                    _sentimentValue = val;
                  });
                },
              ),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStage,
                      decoration: const InputDecoration(
                        labelText: 'Legal Case Stage',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'fir', child: Text('FIR Filing')),
                        DropdownMenuItem(value: 'chargesheet', child: Text('Chargesheet Filed')),
                        DropdownMenuItem(value: 'trial', child: Text('Special Court Trial')),
                        DropdownMenuItem(value: 'adjournment', child: Text('Adjournment Delay')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStage = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Days Elapsed',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _diaryController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        labelText: 'Wellness Journal & Check-in Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isDictating ? Icons.mic : Icons.mic_none,
                      color: _isDictating ? const Color(0xFFE11D48) : const Color(0xFF0D9488),
                    ),
                    tooltip: 'Speech Input',
                    onPressed: _toggleDictation,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: _analyzeVoiceStress,
                icon: const Icon(Icons.graphic_eq_rounded, size: 16),
                label: const Text('Analyze Voice Stress & Acoustic Markers'),
              ),
              if (_voiceStressResult != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text(
                    'Voice Stress Score: ${_voiceStressResult!["voice_stress_score"]} | Emotion: ${_voiceStressResult!["emotion_classification"]}',
                    style: const TextStyle(color: Color(0xFF0369A1), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitWellbeing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Log Wellbeing & Evaluate Distress Score'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Statutory SC/ST Relief Portal Card Shortcut
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.gavel_rounded, color: Color(0xFFD97706), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SC/ST Compensation Portal',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const Text(
                      'Annexure-I Relief & Legal Aid (DLSA)',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SCSTReliefScreen()));
                },
                child: const Text('Open Portal', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneDot(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
          ),
          child: active ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: active ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildMilestoneLine(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        color: active ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildCounselorView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Escalated Victim Protection Alerts',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),

        ..._escalations.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Victim: ${item["patient_name"]}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Distress: ${item["distress_score"]}% (${item["distress_level"]})',
                      style: const TextStyle(color: Color(0xFFE11D48), fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Legal Stage: ${item["case_stage"]}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _acknowledgeAlert(item["id"]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Acknowledge'),
                ),
              ],
            ),
          );
        }),

        if (_escalations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No escalated protection alerts found.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ),
      ],
    );
  }
}
