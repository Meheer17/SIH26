import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class GamificationTab extends StatefulWidget {
  const GamificationTab({super.key});

  @override
  State<GamificationTab> createState() => _GamificationTabState();
}

class _GamificationTabState extends State<GamificationTab> {
  final RakshaSetuService _service = RakshaSetuService();

  bool _isLoading = true;
  Map<String, dynamic>? _dashboard;
  List<dynamic> _challenges = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dash = await _service.fetchGamification();
      final chal = await _service.fetchChallenges();
      if (mounted) {
        setState(() {
          _dashboard = dash;
          _challenges = chal;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
    }

    final points = _dashboard?['wellness_points'] ?? 740;
    final streak = _dashboard?['streak_days'] ?? 14;
    final badges = _dashboard?['badges'] as List<dynamic>? ?? [];
    final leaderboard = _dashboard?['battalion_leaderboard'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF0284C7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Points & Streak Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x1A047857), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL WELLNESS POINTS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFA7F3D0), letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$points',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            const Text('PTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFA7F3D0))),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$streak Days', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                              const Text('ACTIVE STREAK', style: TextStyle(fontSize: 8, color: Color(0xFFA7F3D0))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFF059669), height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Next Rank: Sentinel Master', style: TextStyle(fontSize: 12, color: Colors.white)),
                    Text('740 / 1000 PTS (74%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFA7F3D0))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.74,
                    minHeight: 6,
                    backgroundColor: Color(0xFF047857),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Active Battalion Challenges
          const Text('Battalion Operational Challenges', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          ..._challenges.map((c) {
            final title = c['title'] ?? 'Challenge';
            final desc = c['description'] ?? '';
            final progress = (c['progress_percent'] as num?)?.toDouble() ?? 50.0;
            final daysLeft = c['days_left'] ?? 3;
            final reward = c['reward_points'] ?? 200;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                        child: Text('+$reward PTS', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress: ${progress.toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                      Text('⏳ $daysLeft Days Remaining', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // 3. Badges Gallery
          const Text('Earned Operational Badges', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (context, index) {
              final b = badges[index];
              final name = b['name'] ?? '';
              final desc = b['description'] ?? '';
              final unlocked = b['unlocked'] == true;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unlocked ? Colors.white : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: unlocked ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                  boxShadow: unlocked ? const [BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2))] : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          unlocked ? Icons.military_tech_rounded : Icons.lock_outline_rounded,
                          color: unlocked ? const Color(0xFFEAB308) : const Color(0xFF94A3B8),
                          size: 28,
                        ),
                        if (unlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                            child: const Text('EARNED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // 4. Battalion Company Leaderboard
          const Text('Battalion Company Resilience Standings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: leaderboard.map((item) {
                final rank = item['rank'] ?? 1;
                final company = item['company'] ?? '';
                final score = item['resilience_score'] ?? 80.0;
                final streaks = item['active_streaks'] ?? 50;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: rank == 1 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rank == 1 ? const Color(0xFFD97706) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  title: Text(company, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  subtitle: Text('$streaks jawans maintaining daily wellness streak', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '$score%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
