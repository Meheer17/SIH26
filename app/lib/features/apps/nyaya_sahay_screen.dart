import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/speech/speech_service.dart';

class NyayaSahayScreen extends StatefulWidget {
  const NyayaSahayScreen({super.key});

  @override
  State<NyayaSahayScreen> createState() => _NyayaSahayScreenState();
}

class _NyayaSahayScreenState extends State<NyayaSahayScreen> {
  final ApiClient _apiClient = ApiClient();
  final _authService = AuthService();
  final SpeechService _speechService = SpeechService();

  double _sentimentValue = -0.2;
  String _selectedStage = 'trial';
  final _daysController = TextEditingController(text: '90');
  final _diaryController = TextEditingController(text: 'Anxious before the court trial.');

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
    try {
      final res = await _apiClient.post(
        'apps/nyaya/voice-stress',
        body: {
          'transcript_text': _diaryController.text,
          'pitch_variance': 32.5,
          'pause_ratio': 0.38,
        },
      );
      setState(() {
        _voiceStressResult = Map<String, dynamic>.from(res);
        _sentimentValue = (res['sentiment_score'] as num).toDouble();
      });

      _speechService.speak("Voice stress index evaluated at ${res['voice_stress_score']}. Sentiment classification is ${res['emotion_classification']}.");
    } catch (e) {
      debugPrint("Voice stress error: $e");
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

    try {
      final res = await _apiClient.post(
        'apps/nyaya/distress',
        body: {
          'sentiment_score': _sentimentValue,
          'case_stage': _selectedStage,
          'days_since_incident': int.parse(_daysController.text),
          'recent_checkin_responses': _diaryController.text,
        },
      );

      setState(() {
        _latestResult = Map<String, dynamic>.from(res);
      });
      _fetchHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wellbeing log recorded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    final isCounselor = user.mappedRoles.contains('COUNSELOR') || user.mappedRoles.contains('SYSTEM_ADMIN');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(isCounselor ? 'NyayaSahay Counselors Desk' : 'NyayaSahay Victim Support', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: const Color(0xFF1E293B),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outreach Wellbeing Checkin',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sentiment Level: ${_sentimentValue.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _sentimentValue,
                  min: -1.0,
                  max: 1.0,
                  divisions: 20,
                  label: _sentimentValue.toStringAsFixed(1),
                  activeColor: Colors.amberAccent,
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
                        dropdownColor: const Color(0xFF1E293B),
                        value: _selectedStage,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Case Stage',
                          labelStyle: TextStyle(color: Colors.white60),
                        ),
                        items: ['fir', 'chargesheet', 'trial', 'adjournment'].map((stage) {
                          return DropdownMenuItem(value: stage, child: Text(stage.toUpperCase()));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStage = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Days Since Incident',
                          labelStyle: TextStyle(color: Colors.white60),
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
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Wellness Diary response',
                          labelStyle: TextStyle(color: Colors.white60),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isDictating ? Icons.mic : Icons.mic_none,
                        color: _isDictating ? Colors.redAccent : Colors.amberAccent,
                      ),
                      tooltip: 'Record Native Speech Input',
                      onPressed: _toggleDictation,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _analyzeVoiceStress,
                  icon: const Icon(Icons.graphic_eq_rounded, color: Colors.amberAccent, size: 18),
                  label: const Text('Analyze Voice Stress & Acoustic Markers', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                ),
                if (_voiceStressResult != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Voice Stress Index: ${_voiceStressResult!["voice_stress_score"]} | Emotion: ${_voiceStressResult!["emotion_classification"]}',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitWellbeing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Log Wellbeing & Distress', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        if (_latestResult != null) ...[
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distress Evaluation',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Distress Score: ${_latestResult!["distress_score"]} (${_latestResult!["distress_level"]})',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_latestResult!["escalation_status"] != "NONE")
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '⚠️ ALERT: Multi-tier Escalation dispatched to District protection node and counselor assigned.',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  else
                    const Text('Status: Standard case monitoring active.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Logs History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ..._history.map((h) {
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                'Distress: ${h["distress_score"]} (${h["distress_level"]})',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                h["recent_checkin_responses"] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCounselorView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Escalated Wellbeing Alerts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ..._escalations.map((item) {
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Victim: ${item["patient_name"]}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distress: ${item["distress_score"]} (${item["distress_level"]})',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Legal Stage: ${item["case_stage"]}',
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _acknowledgeAlert(item["id"]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Acknowledge'),
                  ),
                ],
              ),
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
        const SizedBox(height: 12),
        // Innovation Card: PoA Legal Milestone & Relief Payout Tracker
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '⚖️ PoA Legal & Relief Tracker',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DBT INTEGRATED',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Legal Stage 3/4 (Special Court Trial). Direct Benefit Transfer (DBT): ₹3,50,000 released to Aadhar bank account.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
