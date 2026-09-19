import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class PersonnelHomeTab extends StatefulWidget {
  final Function(int tabIndex) onNavigate;
  final VoidCallback onTriggerSos;

  const PersonnelHomeTab({
    super.key,
    required this.onNavigate,
    required this.onTriggerSos,
  });

  @override
  State<PersonnelHomeTab> createState() => _PersonnelHomeTabState();
}

class _PersonnelHomeTabState extends State<PersonnelHomeTab> {
  final RakshaSetuService _service = RakshaSetuService();

  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _wellnessScore;
  int _selectedMood = 3;
  bool _moodLoggedToday = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _service.fetchProfile();
      final score = await _service.fetchWellnessScore();
      if (mounted) {
        setState(() {
          _profile = profile;
          _wellnessScore = score;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _quickLogMood(int rating, String label) async {
    setState(() {
      _selectedMood = rating;
      _moodLoggedToday = true;
    });
    try {
      await _service.logMood(
        moodRating: rating,
        moodLabel: label,
        energyLevel: rating >= 4 ? 4 : 3,
        stressLevel: rating <= 2 ? 4 : 2,
        tags: ['quick_home_checkin'],
        note: 'Logged from Daily Check-In on home screen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily mood logged: $label. Streak extended! 🔥'),
            backgroundColor: const Color(0xFF0D9488),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadDashboardData();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0284C7)),
      );
    }

    final scoreVal = (_wellnessScore?['wellness_score'] as num?)?.toDouble() ?? 68.5;
    final riskVal = (_wellnessScore?['risk_score'] as num?)?.toDouble() ?? 31.5;
    final tier = _wellnessScore?['tier'] as String? ?? 'MODERATE';
    final trendArrow = _wellnessScore?['trend_arrow'] as String? ?? '↑';
    final recAction = _wellnessScore?['recommended_action'] as String? ?? 'Maintain tactical box breathing';
    final points = _profile?['wellness_points'] ?? 740;
    final streak = _profile?['streak_days'] ?? 14;
    final rank = _profile?['rank'] ?? 'Havaldar';
    final name = _profile?['full_name'] ?? 'Rajesh Singh';
    final belt = _profile?['service_belt_number'] ?? 'CRPF-88412';
    final unit = _profile?['unit_name'] ?? '44th Bn CAPF';

    Color tierColor = const Color(0xFF10B981);
    if (tier == 'CRITICAL') tierColor = const Color(0xFFEF4444);
    else if (tier == 'HIGH') tierColor = const Color(0xFFF97316);
    else if (tier == 'MODERATE') tierColor = const Color(0xFFF59E0B);

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF0284C7),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Soldier Header Card
            _buildSoldierHeader(rank, name, belt, unit, streak, points),
            const SizedBox(height: 16),

            // 2. Circular Wellness Score Card
            _buildWellnessScoreCard(scoreVal, riskVal, tier, tierColor, trendArrow, recAction),
            const SizedBox(height: 16),

            // 3. Daily Mood Check-In Card
            _buildDailyCheckInCard(),
            const SizedBox(height: 16),

            // 4. Quick Action Hub
            _buildQuickActionGrid(),
            const SizedBox(height: 16),

            // 5. Contributing Stress Factors Card
            _buildContributingFactorsCard(),
            const SizedBox(height: 16),

            // 6. Tactical Wellness Tip of the Day
            _buildWellnessTipCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSoldierHeader(String rank, String name, String belt, String unit, int streak, int points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0F172A), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF0284C7),
                child: const Icon(Icons.shield, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'जय हिन्द, $rank $name',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Belt # $belt • $unit',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x3310B981),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_outline, color: Color(0xFF10B981), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'AIR-GAPPED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderBadge(Icons.local_fire_department, '🔥 $streak-Day Streak', const Color(0xFFF97316)),
              _buildHeaderBadge(Icons.military_tech, '⭐ $points Pts', const Color(0xFFEAB308)),
              _buildHeaderBadge(Icons.verified, 'DPDP Compliant', const Color(0xFF38BDF8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildWellnessScoreCard(
    double score,
    double risk,
    String tier,
    Color tierColor,
    String trendArrow,
    String recAction,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Operational Resilience',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tier,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tierColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular Gauge
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 9,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${score.toInt()}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                trendArrow,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tierColor),
                              ),
                            ],
                          ),
                          const Text(
                            '/100',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operational Burnout Risk: ${risk.toInt()}%',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tierColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recAction,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => widget.onNavigate(1), // Go to Assessments
                      child: Row(
                        children: const [
                          Text(
                            'View Detailed Clinical Breakdown',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF0284C7)),
                        ],
                      ),
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

  Widget _buildDailyCheckInCard() {
    final emojis = [
      {'val': 1, 'emoji': '😫', 'label': 'Exhausted'},
      {'val': 2, 'emoji': '😟', 'label': 'Tense'},
      {'val': 3, 'emoji': '😐', 'label': 'Neutral'},
      {'val': 4, 'emoji': '🙂', 'label': 'Steady'},
      {'val': 5, 'emoji': '💪', 'label': 'Resilient'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.mood, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Daily Sentinel Check-In (दैनिक हालचाल)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ],
              ),
              if (_moodLoggedToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LOGGED TODAY ✓',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'How are you feeling before or after your duty shift today?',
            style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: emojis.map((item) {
              final isSel = _selectedMood == item['val'];
              return InkWell(
                onTap: () => _quickLogMood(item['val'] as int, item['label'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF16A34A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(item['emoji'] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    final actions = [
      {
        'title': 'Self-Assessments',
        'sub': 'PHQ-9, GAD-7, CAPF',
        'icon': Icons.assignment_turned_in_outlined,
        'color': const Color(0xFF0284C7),
        'tab': 1,
      },
      {
        'title': 'Sahayak AI',
        'sub': 'Confidential Counselor',
        'icon': Icons.smart_toy_outlined,
        'color': const Color(0xFF7C3AED),
        'tab': 3,
      },
      {
        'title': '4-4-4-4 Breathing',
        'sub': 'Tactical Grounding',
        'icon': Icons.air_rounded,
        'color': const Color(0xFF0D9488),
        'tab': 4,
      },
      {
        'title': 'Log Sleep & Rest',
        'sub': 'Circadian Tracking',
        'icon': Icons.bedtime_outlined,
        'color': const Color(0xFF3B82F6),
        'tab': 2,
      },
      {
        'title': 'Voice Journal',
        'sub': 'NLP Sentiment Check',
        'icon': Icons.mic_none_outlined,
        'color': const Color(0xFFE11D48),
        'tab': 2,
      },
      {
        'title': 'Book Counselor',
        'sub': 'Dr. Sharma / 14416',
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFF10B981),
        'tab': 5,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Operations & Welfare Hub',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
          ),
          itemBuilder: (context, index) {
            final item = actions[index];
            final color = item['color'] as Color;
            return InkWell(
              onTap: () => widget.onNavigate(item['tab'] as int),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item['icon'] as IconData, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item['sub'] as String,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContributingFactorsCard() {
    final factors = _wellnessScore?['contributing_factors'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'AI Contributing Stress Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                'SHAP Model',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...factors.map((f) {
            final name = f['factor'] ?? 'Factor';
            final score = (f['score'] as num?)?.toDouble() ?? 10.0;
            final weight = (f['weight'] as num?)?.toDouble() ?? 25.0;
            final status = f['status'] ?? 'NORMAL';
            final ratio = (score / weight).clamp(0.0, 1.0);

            Color barColor = const Color(0xFF10B981);
            if (status == 'HIGH') barColor = const Color(0xFFEF4444);
            else if (status == 'WATCH' || status == 'MODERATE') barColor = const Color(0xFFF59E0B);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                      Text(
                        '${score.toInt()}/${weight.toInt()} pts ($status)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: barColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWellnessTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Tactical Sentinel Tip (सामरिक कल्याण सलाह)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                ),
                SizedBox(height: 4),
                Text(
                  'During sub-zero night posts, 3 minutes of rhythmic diaphragmatic breathing preserves core temperature, decreases cortisol, and elevates visual alertness by 34%.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF4338CA), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
