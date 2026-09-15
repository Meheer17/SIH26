import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/speech/speech_service.dart';
import '../../core/ml/mobile_ml_engine.dart';
import '../../core/theme/app_theme.dart';

class RakshakMitraScreen extends StatefulWidget {
  const RakshakMitraScreen({super.key});

  @override
  State<RakshakMitraScreen> createState() => _RakshakMitraScreenState();
}

class _RakshakMitraScreenState extends State<RakshakMitraScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  final _authService = AuthService();
  final SpeechService _speechService = SpeechService();

  late TabController _tabController;

  // HRMS & Wellness Sliders State
  double _sliderDays = 90;
  double _sliderLeave = 0.75;
  double _sliderDuty = 62;
  double _sliderTransfers = 3;
  double _sliderTraining = 4;
  double _sliderAssessment = 14;

  final TextEditingController _voiceController = TextEditingController(
    text: 'Experiencing severe sleep disruption and fatigue after continuous 12-hour night sentinel patrols in high altitude border post.',
  );

  bool _isLoading = false;
  bool _isDictating = false;
  bool _showOperationalGuide = true;
  
  List<dynamic> _history = [];
  Map<String, dynamic>? _commanderData;
  Map<String, dynamic>? _latestResult;

  final List<Map<String, dynamic>> _presets = [
    {
      'label': '🏔️ High-Altitude Border Guard',
      'days': 120,
      'leave': 0.90,
      'duty': 74.0,
      'transfers': 4,
      'training': 6,
      'assessment': 19,
      'journal': 'Extreme sub-zero cold and continuous night sentinel watch. Experiencing severe physical exhaustion and high stress.',
    },
    {
      'label': '🌙 CAPF Night Outpost Sentry',
      'days': 85,
      'leave': 0.70,
      'duty': 64.0,
      'transfers': 3,
      'training': 4,
      'assessment': 14,
      'journal': 'Intermittent sleep during night patrols, feeling persistent tension before operational shift.',
    },
    {
      'label': '🚔 Rapid Action Patrol Unit',
      'days': 45,
      'leave': 0.40,
      'duty': 50.0,
      'transfers': 2,
      'training': 3,
      'assessment': 8,
      'journal': 'Routine law and order patrol duties completed smoothly without major incidents.',
    },
    {
      'label': '🧘 Rest & De-escalation Roster',
      'days': 10,
      'leave': 0.15,
      'duty': 36.0,
      'transfers': 1,
      'training': 1,
      'assessment': 3,
      'journal': 'Completed rest cycle, spent quality time with family, feeling recharged and operational.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _speechService.init();
    _fetchHistory();
    _fetchCommanderData();
    _runLiveCalculation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  void _runLiveCalculation() {
    final res = MobileMlEngine.evaluateRakshakBurnout(
      deploymentDays: _sliderDays.toInt(),
      leaveGapRatio: _sliderLeave,
      dutyHoursPerWeek: _sliderDuty,
      selfAssessmentScore: _sliderAssessment.toInt(),
      voiceJournalText: _voiceController.text,
    );
    setState(() {
      _latestResult = res;
    });
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _sliderDays = (preset['days'] as num).toDouble();
      _sliderLeave = (preset['leave'] as num).toDouble();
      _sliderDuty = (preset['duty'] as num).toDouble();
      _sliderTransfers = (preset['transfers'] as num).toDouble();
      _sliderTraining = (preset['training'] as num).toDouble();
      _sliderAssessment = (preset['assessment'] as num).toDouble();
      _voiceController.text = preset['journal'];
    });
    _runLiveCalculation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied Duty Roster Preset: ${preset['label']}'),
        backgroundColor: AppTheme.primaryTeal,
      ),
    );
  }

  void _toggleVoiceJournalDictation() {
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
            _voiceController.text = text;
          });
          _runLiveCalculation();
        },
        onStatusChange: (listening) {
          setState(() {
            _isDictating = listening;
          });
        },
      );
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await _apiClient.get('apps/rakshak/burnout');
      if (res is List) {
        setState(() {
          _history = res;
          if (_history.isNotEmpty && _latestResult == null) {
            _latestResult = Map<String, dynamic>.from(_history.first);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading burnout history: $e');
    }
  }

  Future<void> _fetchCommanderData() async {
    try {
      final res = await _apiClient.get('apps/rakshak/commander-dashboard');
      if (res is Map<String, dynamic>) {
        setState(() {
          _commanderData = res;
        });
      }
    } catch (e) {
      debugPrint('Error loading commander dashboard data: $e');
    }
  }

  Future<void> _submitAssessment() async {
    setState(() {
      _isLoading = true;
    });

    final days = _sliderDays.toInt();
    final leave = _sliderLeave;
    final duty = _sliderDuty;
    final transfers = _sliderTransfers.toInt();
    final training = _sliderTraining.toInt();
    final assessment = _sliderAssessment.toInt();
    final journal = _voiceController.text;

    final localMlResult = MobileMlEngine.evaluateRakshakBurnout(
      deploymentDays: days,
      leaveGapRatio: leave,
      dutyHoursPerWeek: duty,
      selfAssessmentScore: assessment,
      voiceJournalText: journal,
    );

    try {
      final res = await _apiClient.post(
        'apps/rakshak/hrms-stress',
        body: {
          'weekly_duty_hours': duty,
          'deployment_days': days,
          'leave_gap_ratio': leave,
          'station_transfers_count': transfers,
          'training_commitments_count': training,
          'phq9_assessment_score': assessment,
          'voice_journal_text': journal,
        },
      );

      setState(() {
        _latestResult = Map<String, dynamic>.from(res);
      });
      _fetchHistory();
      _fetchCommanderData();

      final score = res['hrms_stress_index'] ?? res['burnout_score'] ?? localMlResult['burnout_score'];
      final tier = res['burnout_tier'] ?? res['risk_tier'] ?? localMlResult['risk_tier'];

      _speechService.speak("HRMS Stress Index is $score. Operational Risk Tier is $tier.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HRMS Telemetry Logged & Analyzed by RakshakMitra Bedrock Agent (Score: $score)'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _latestResult = localMlResult;
      });
      _speechService.speak("Local ML Stress Index is ${localMlResult['burnout_score']}. Risk tier is ${localMlResult['risk_tier']}.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evaluated via Mobile ML Engine (Score: ${localMlResult['burnout_score']})'),
            backgroundColor: AppTheme.primaryIndigo,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.lightBackground,
        body: Center(child: Text('Please log in to access RakshakManas.', style: TextStyle(color: AppTheme.textPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, color: AppTheme.primaryTeal, size: 20),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'RAKSHAK-MANAS Personnel Stress & Welfare System',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showOperationalGuide ? Icons.info : Icons.info_outline, color: AppTheme.primaryTeal),
            tooltip: 'Toggle Operational Blueprint',
            onPressed: () => setState(() => _showOperationalGuide = !_showOperationalGuide),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.person, size: 18), text: 'Personnel Wellness App'),
            Tab(icon: Icon(Icons.dashboard_customize, size: 18), text: 'Commander & Welfare Officer'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: PERSONNEL WELLNESS MOBILE APP
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroTelemetryBanner(),
                  const SizedBox(height: 16),
                  if (_showOperationalGuide) ...[
                    _buildOperationalGuideCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildSoldierInteractiveForm(),
                ],
              ),
            ),

            // TAB 2: COMMANDER & WELFARE OFFICER DASHBOARD
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCommanderDashboardHeader(),
                  const SizedBox(height: 16),
                  _buildCommanderView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. HERO TELEMETRY GAUGE
  Widget _buildHeroTelemetryBanner() {
    final int score = (_latestResult?['hrms_stress_index'] ?? _latestResult?['burnout_score'] as num?)?.toInt() ?? 42;
    final String tier = _latestResult?['burnout_tier'] ?? _latestResult?['risk_tier'] ?? 'ORANGE';
    
    Color tierColor = AppTheme.primaryTeal;
    if (tier == 'RED' || score >= 70) {
      tierColor = AppTheme.alertRose;
    } else if (tier == 'ORANGE' || score >= 40) {
      tierColor = AppTheme.accentAmber;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.health_and_safety, color: tierColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CAPF / ARMED FORCES HRMS TELEMETRY',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      Text(
                        'Personnel Stress & Burnout Index',
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tierColor.withOpacity(0.4)),
                ),
                child: Text(
                  '$tier RISK TIER',
                  style: TextStyle(color: tierColor, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Burnout Score Progress Bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('HRMS Burnout Risk Gauge', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('$score / 100', style: TextStyle(color: tierColor, fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: score / 100.0,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Mini Metric Badges
          Row(
            children: [
              _buildMiniMetric('Deployment', '${_sliderDays.toInt()} Days', Icons.landscape, AppTheme.secondaryCyan),
              const SizedBox(width: 8),
              _buildMiniMetric('Duty Burden', '${_sliderDuty.toInt()}h/wk', Icons.schedule, AppTheme.accentAmber),
              const SizedBox(width: 8),
              _buildMiniMetric('Leave Gap', '${(_sliderLeave * 100).toInt()}%', Icons.event_busy, AppTheme.primaryIndigo),
              const SizedBox(width: 8),
              _buildMiniMetric('Transfers', '${_sliderTransfers.toInt()} Shifts', Icons.swap_horiz, AppTheme.primaryTeal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // 2. OPERATIONAL BLUEPRINT & TRIAGE PROTOCOL
  Widget _buildOperationalGuideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_moon, color: AppTheme.primaryTeal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '📖 RAKSHAK-MANAS Operational Blueprint',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showOperationalGuide = false),
                child: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Proactive AI-driven stress and welfare monitoring platform designed specifically for CAPF, Indian Armed Forces, and State Police operating under hazardous, high-altitude, and prolonged operational deployments.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text('KEY ORGANIZATIONAL & WELLNESS INDICATORS ANALYZED:', style: TextStyle(color: AppTheme.primaryTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          _buildGuidePoint('1. HRMS Duty & Deployment Telemetry', 'Analyzes weekly duty hours, border posting tenure, leave denial ratio, and station transfer frequency.'),
          _buildGuidePoint('2. Voluntary PHQ-9 & GAD-7 Self Assessment', 'Optional mobile assessment for clinical depression, fatigue, and operational anxiety.'),
          _buildGuidePoint('3. Bhashini Acoustic Voice Biomarker', 'Analyzes vocal micro-tremors, pitch jitter, pause ratio, and speech rate WPM from voluntary voice logs.'),
          _buildGuidePoint('4. Differential Privacy & Non-Disciplinary Mandate', 'Data anonymization safeguards guarantee personnel dignity and focus purely on welfare interventions.'),

          const SizedBox(height: 12),
          const Text('3-TIER WELFARE INTERVENTION PROTOCOL:', style: TextStyle(color: AppTheme.primaryIndigo, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTierGuideBadge('🟢 GREEN (0-39)', 'Standard Rostering', AppTheme.primaryTeal),
              const SizedBox(width: 6),
              _buildTierGuideBadge('🟠 ORANGE (40-69)', 'Duty Load Shift', AppTheme.accentAmber),
              const SizedBox(width: 6),
              _buildTierGuideBadge('🔴 RED (70-100)', '72h Rest Mandate', AppTheme.alertRose),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuidePoint(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierGuideBadge(String title, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // 3. SOLDIER INTERACTIVE FORM
  Widget _buildSoldierInteractiveForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // PRESETS
        const Text('Quick Duty Scenario Presets:', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _presets.map((p) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor: AppTheme.lightSurface,
                  side: const BorderSide(color: AppTheme.cardBorder),
                  label: Text(p['label'], style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                  onPressed: () => _applyPreset(p),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: AppTheme.primaryTeal, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'HRMS & Operational Stress Biomarker Calculator',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Slider 1: Deployment Days
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('1. Deployment Duration (Border/Field Tenure)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${_sliderDays.toInt()} Days', style: const TextStyle(color: AppTheme.secondaryCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Slider(
                  value: _sliderDays,
                  min: 5,
                  max: 200,
                  divisions: 39,
                  activeColor: AppTheme.secondaryCyan,
                  onChanged: (val) {
                    setState(() => _sliderDays = val);
                    _runLiveCalculation();
                  },
                ),

                // Slider 2: Leave Ratio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('2. Leave Gap Ratio (Denied or Delayed Leave)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${(_sliderLeave * 100).toInt()}%', style: const TextStyle(color: AppTheme.primaryIndigo, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Slider(
                  value: _sliderLeave,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  activeColor: AppTheme.primaryIndigo,
                  onChanged: (val) {
                    setState(() => _sliderLeave = val);
                    _runLiveCalculation();
                  },
                ),

                // Slider 3: Duty Burden
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('3. Weekly Duty Burden (Patrol / Sentry Hours)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${_sliderDuty.toInt()} Hours/Wk', style: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Slider(
                  value: _sliderDuty,
                  min: 20,
                  max: 100,
                  divisions: 16,
                  activeColor: AppTheme.accentAmber,
                  onChanged: (val) {
                    setState(() => _sliderDuty = val);
                    _runLiveCalculation();
                  },
                ),

                // Slider 4: Station Transfers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('4. Station Transfer Frequency (Past 2 Years)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${_sliderTransfers.toInt()} Transfers', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Slider(
                  value: _sliderTransfers,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (val) {
                    setState(() => _sliderTransfers = val);
                    _runLiveCalculation();
                  },
                ),

                // Slider 5: PHQ-9 Psychological Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('5. Voluntary PHQ-9 Self-Assessment Rating', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${_sliderAssessment.toInt()} / 27', style: const TextStyle(color: AppTheme.alertRose, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Slider(
                  value: _sliderAssessment,
                  min: 0,
                  max: 27,
                  divisions: 27,
                  activeColor: AppTheme.alertRose,
                  onChanged: (val) {
                    setState(() => _sliderAssessment = val);
                    _runLiveCalculation();
                  },
                ),

                // Voice Mood Journal Section
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voiceController,
                        maxLines: 2,
                        onChanged: (_) => _runLiveCalculation(),
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: '6. Voluntary Voice Journal / Acoustic Check-in',
                          labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _isDictating ? Icons.mic : Icons.mic_none,
                        color: _isDictating ? AppTheme.alertRose : AppTheme.primaryTeal,
                        size: 28,
                      ),
                      tooltip: 'Record Voice Journal with Bhashini AI',
                      onPressed: _toggleVoiceJournalDictation,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sync HRMS Telemetry & Run Bedrock Risk Engine', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),

        if (_latestResult != null) ...[
          const SizedBox(height: 16),
          _buildAssessmentResultCard(),
        ],

        const SizedBox(height: 16),
        const Text(
          'Recent Personnel Wellness Logs & History',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),

        if (_history.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No historical logs recorded. Submit an assessment above.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          )
        else
          ..._history.map((h) {
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  'Stress Index: ${h["burnout_score"]} (${h["risk_tier"]})',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  h["voice_journal_text"] ?? 'Standard check-in without voice transcript.',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ),
            );
          }),
      ],
    );
  }

  // 4. ASSESSMENT RESULT CARD
  Widget _buildAssessmentResultCard() {
    final int score = (_latestResult!["hrms_stress_index"] ?? _latestResult!["burnout_score"] as num).toInt();
    final String tier = _latestResult!["burnout_tier"] ?? _latestResult!["risk_tier"] ?? 'ORANGE';
    
    Color tierColor = AppTheme.primaryTeal;
    if (tier == 'RED' || score >= 70) {
      tierColor = AppTheme.alertRose;
    } else if (tier == 'ORANGE' || score >= 40) {
      tierColor = AppTheme.accentAmber;
    }

    final voiceAnalysis = _latestResult!["voice_analysis"] as Map<String, dynamic>?;
    final factors = _latestResult!["contributing_factors"] as List<dynamic>?;
    final recommendations = _latestResult!["action_recommendations"] as List<dynamic>?;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎯 AI Stress & Burnout Predictive Result',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tierColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    tier,
                    style: TextStyle(color: tierColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'HRMS Stress Index: $score / 100',
              style: TextStyle(color: tierColor, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),

            // Action Protocol
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tierColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: tierColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Welfare Intervention Protocol:',
                        style: TextStyle(color: tierColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _latestResult!["action_recommendation"] ??
                        (recommendations != null && recommendations.isNotEmpty
                            ? recommendations.first.toString()
                            : "Standard duty roster maintained."),
                    style: TextStyle(color: tierColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            if (factors != null && factors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('⚠️ Primary Contributing Risk Factors:', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...factors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $f', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              )),
            ],

            if (voiceAnalysis != null) ...[
              const SizedBox(height: 12),
              const Text('🎙️ Acoustic Voice Biomarker Metrics:', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '• Emotion: ${voiceAnalysis["emotion_classification"]} | Tremor: ${voiceAnalysis["physiological_tremor"]}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              Text(
                '• Pitch Var: ${voiceAnalysis["pitch_variance"]} | Pause Ratio: ${voiceAnalysis["pause_ratio"]} | WPM: ${voiceAnalysis["speech_rate_wpm"]}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 5. COMMANDER DASHBOARD HEADER
  Widget _buildCommanderDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryIndigo.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryIndigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: AppTheme.primaryIndigo, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Unit Commander & Welfare Officer Dashboard',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRIVACY GUARD ENFORCED',
                  style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w900, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Aggregated, anonymized regiment wellness metrics enabling commanders to deploy proactive counseling, 72h rest rosters, and workload balancing without compromising individual confidentiality.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 6. COMMANDER & WELFARE OFFICER VIEW
  Widget _buildCommanderView() {
    final units = _commanderData?['units_breakdown'] as List<dynamic>? ?? [
      {'unit': '101 CRPF Battalion (High Altitude)', 'personnel_count': 140, 'average_burnout_index': 78, 'status': 'RED', 'critical_risk_count': 18},
      {'unit': '45 BSF Frontier Outpost', 'personnel_count': 95, 'average_burnout_index': 62, 'status': 'ORANGE', 'critical_risk_count': 9},
      {'unit': '12 ITBP Mountain Battalion', 'personnel_count': 110, 'average_burnout_index': 58, 'status': 'ORANGE', 'critical_risk_count': 7},
      {'unit': '20 Urban Rapid Action Unit', 'personnel_count': 180, 'average_burnout_index': 28, 'status': 'GREEN', 'critical_risk_count': 1},
    ];

    final summary = _commanderData?['regiment_risk_summary'] as Map<String, dynamic>? ?? {
      'total_monitored': 525,
      'high_risk_percentage': '15.2%',
      'moderate_risk_percentage': '32.4%',
      'low_risk_percentage': '52.4%',
    };

    final actions = _commanderData?['recommended_welfare_actions'] as List<dynamic>? ?? [
      'Dispatch 72-hour mandatory rest cycle for 18 personnel in 101 CRPF Battalion.',
      'Reallocate night sentry duty schedules to lower stress burden for BSF Outpost.',
      'Provide priority family connectivity leave slots for high leave-gap personnel.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Cards
        Row(
          children: [
            _buildCommanderStatCard('Total Monitored', '${summary["total_monitored"]}', Icons.people, AppTheme.secondaryCyan),
            const SizedBox(width: 8),
            _buildCommanderStatCard('High Risk', '${summary["high_risk_percentage"]}', Icons.warning_amber, AppTheme.alertRose),
            const SizedBox(width: 8),
            _buildCommanderStatCard('Optimal', '${summary["low_risk_percentage"]}', Icons.check_circle_outline, AppTheme.primaryTeal),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'Anonymized Regiment Wellness Heatmap',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Differential privacy enabled. Individual identities protected under strict role-based access control.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),

        ...units.map((item) {
          final score = (item["average_burnout_index"] as num).toDouble();
          final status = item["status"] as String;
          
          Color statusColor = AppTheme.primaryTeal;
          if (status == "RED" || score >= 70) {
            statusColor = AppTheme.alertRose;
          } else if (status == "ORANGE" || score >= 40) {
            statusColor = AppTheme.accentAmber;
          }

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["unit"],
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personnel Strength: ${item["personnel_count"]}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Avg Stress: $score',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Critical: ${item["critical_risk_count"]}',
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 14),
        const Text(
          'Automated Commander Welfare Recommendations',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        ...actions.map((act) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment_turned_in, color: AppTheme.primaryTeal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  act.toString(),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildCommanderStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
