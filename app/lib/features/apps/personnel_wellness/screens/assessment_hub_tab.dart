import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class AssessmentHubTab extends StatefulWidget {
  final VoidCallback onTriggerSos;

  const AssessmentHubTab({super.key, required this.onTriggerSos});

  @override
  State<AssessmentHubTab> createState() => _AssessmentHubTabState();
}

class _AssessmentHubTabState extends State<AssessmentHubTab> with SingleTickerProviderStateMixin {
  final RakshaSetuService _service = RakshaSetuService();

  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _catalog = [];
  List<dynamic> _history = [];

  // Active Questionnaire State
  Map<String, dynamic>? _activeAssessment;
  List<int> _currentAnswers = [];
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  Map<String, dynamic>? _latestResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final catalog = await _service.fetchAssessmentCatalog();
      final history = await _service.fetchAssessmentHistory();
      if (mounted) {
        setState(() {
          _catalog = catalog;
          _history = history;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startAssessment(Map<String, dynamic> item) {
    final questions = item['questions'] as List<dynamic>? ?? [];
    setState(() {
      _activeAssessment = item;
      _currentAnswers = List.filled(questions.length, 0);
      _currentQuestionIndex = 0;
      _latestResult = null;
    });
  }

  Future<void> _submitActiveAssessment() async {
    if (_activeAssessment == null) return;
    setState(() => _isSubmitting = true);

    try {
      final res = await _service.submitAssessment(
        assessmentType: _activeAssessment!['type'] as String,
        responses: _currentAnswers,
        notes: 'Submitted via Raksha Setu Mobile Screening Hub',
      );

      if (mounted) {
        setState(() {
          _latestResult = res;
          _isSubmitting = false;
        });
        _service.fetchAssessmentHistory().then((h) {
          if (mounted) setState(() => _history = h);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
    }

    if (_activeAssessment != null) {
      return _buildQuestionnaireView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0284C7),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0284C7),
            tabs: const [
              Tab(icon: Icon(Icons.quiz_outlined, size: 18), text: 'Assessment Catalog'),
              Tab(icon: Icon(Icons.history_edu_outlined, size: 18), text: 'My History & Trends'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCatalogView(),
          _buildHistoryView(),
        ],
      ),
    );
  }

  Widget _buildCatalogView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Banner info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: const [
              Icon(Icons.verified_user_outlined, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'All questionnaires are strictly confidential and voluntary. Results are encrypted under DPDP Act 2023 regulations.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ..._catalog.map((item) {
          final title = item['title'] ?? '';
          final hindiTitle = item['hindi_title'] ?? '';
          final desc = item['description'] ?? '';
          final mins = item['estimated_mins'] ?? 4;
          final maxScore = item['max_score'] ?? 27;
          final type = item['type'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.health_and_safety, color: Color(0xFF0284C7), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            hindiTitle,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '~$mins mins',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Max Score: $maxScore pts • Validated',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _startAssessment(item as Map<String, dynamic>),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Start Assessment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionnaireView() {
    if (_latestResult != null) {
      return _buildResultCard();
    }

    final questions = _activeAssessment!['questions'] as List<dynamic>;
    final options = _activeAssessment!['options'] as List<dynamic>;
    final totalQ = questions.length;
    final currentQ = questions[_currentQuestionIndex] as String;
    final title = _activeAssessment!['title'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Exit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _activeAssessment = null),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentQuestionIndex + 1} of $totalQ',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / totalQ,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
            ),
          ),
          const SizedBox(height: 24),

          // Question Container Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUESTION ${_currentQuestionIndex + 1}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.1),
                ),
                const SizedBox(height: 12),
                Text(
                  currentQ,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.4),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select the response that best describes your experience over the past 2 weeks:',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // Option Buttons
                ...options.map((opt) {
                  final optVal = opt['value'] as int;
                  final optText = opt['text'] as String;
                  final isSelected = _currentAnswers[_currentQuestionIndex] == optVal;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _currentAnswers[_currentQuestionIndex] = optVal;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0284C7).withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              optText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Navigation Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentQuestionIndex > 0)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _currentQuestionIndex--),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else
                const SizedBox(),
              if (_currentQuestionIndex < totalQ - 1)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _currentQuestionIndex++),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitActiveAssessment,
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSubmitting ? 'Computing Score...' : 'Submit & Calculate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final res = _latestResult!;
    final score = res['score'] ?? 0;
    final maxScore = res['max_score'] ?? 27;
    final label = res['severity_label'] ?? 'Evaluated';
    final rec = res['recommendation'] ?? '';
    final crit = res['critical_flag'] == true;
    final points = res['points_awarded'] ?? 50;

    Color badgeColor = crit ? Colors.red : const Color(0xFF0284C7);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: crit ? Colors.red.shade200 : const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  crit ? Icons.warning_amber_rounded : Icons.verified_rounded,
                  color: badgeColor,
                  size: 54,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Clinical Assessment Evaluation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  _activeAssessment?['title'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score / $maxScore PTS',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: badgeColor),
                      ),
                      Text(
                        label,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Clinical Action & Recommendations:',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rec,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+$points Wellness Points Awarded!',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
                if (crit) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: widget.onTriggerSos,
                    icon: const Icon(Icons.emergency),
                    label: const Text('Connect to Duty Psychologist (14416)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _activeAssessment = null;
                        _latestResult = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Back to Assessment Hub'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_history.isEmpty) {
      return const Center(
        child: Text(
          'No assessments logged yet.\nComplete your first checkup from the catalog!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final name = item['assessment_name'] ?? item['assessment_type'] ?? 'Assessment';
        final score = item['score'] ?? 0;
        final max = item['max_score'] ?? 27;
        final label = item['severity_label'] ?? 'Completed';
        final date = (item['created_at'] as String?)?.split('T').first ?? 'Recent';
        final crit = item['critical_flag'] == true;

        Color badgeColor = crit ? Colors.red : const Color(0xFF0284C7);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$label • $score/$max pts',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                    ),
                    Text(
                      'Completed on $date',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
            ],
          ),
        );
      },
    );
  }
}
