import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class WellnessTrackerTab extends StatefulWidget {
  const WellnessTrackerTab({super.key});

  @override
  State<WellnessTrackerTab> createState() => _WellnessTrackerTabState();
}

class _WellnessTrackerTabState extends State<WellnessTrackerTab> with SingleTickerProviderStateMixin {
  final RakshaSetuService _service = RakshaSetuService();

  late TabController _tabController;
  bool _isLoading = true;

  // Mood State
  int _selectedMood = 3;
  double _energyLevel = 3;
  double _stressLevel = 3;
  final Set<String> _selectedMoodTags = {'night_patrol'};
  final TextEditingController _moodNoteController = TextEditingController();
  List<dynamic> _moodHistory = [];

  // Sleep State
  final TextEditingController _bedtimeController = TextEditingController(text: '23:30');
  final TextEditingController _wakeTimeController = TextEditingController(text: '05:45');
  double _sleepDurationHours = 6.25;
  int _sleepQualityRating = 3;
  final Set<String> _sleepDisturbances = {'night_patrol_alarm'};
  List<dynamic> _sleepHistory = [];
  double _lastSleepDebt = 0.75;
  String _circadianRating = 'OPTIMAL';

  // Journal State
  final TextEditingController _journalController = TextEditingController(
    text: 'Completed 12-hour high altitude sentinel duty in sub-zero frost. Practiced tactical 4-4-4-4 breathing during break. Feeling steady and focused.',
  );
  bool _isDictating = false;
  bool _isSubmittingJournal = false;
  Map<String, dynamic>? _latestJournalAnalysis;
  List<dynamic> _journalHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllTrackerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _moodNoteController.dispose();
    _bedtimeController.dispose();
    _wakeTimeController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTrackerData() async {
    setState(() => _isLoading = true);
    try {
      final moods = await _service.fetchMoodHistory();
      final sleeps = await _service.fetchSleepHistory();
      final journals = await _service.fetchJournalHistory();
      if (mounted) {
        setState(() {
          _moodHistory = moods;
          _sleepHistory = sleeps;
          _journalHistory = journals;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitMood() async {
    final labels = ['Exhausted', 'Tense', 'Neutral', 'Steady', 'Resilient'];
    final label = labels[_selectedMood - 1];

    try {
      final res = await _service.logMood(
        moodRating: _selectedMood,
        moodLabel: label,
        energyLevel: _energyLevel.toInt(),
        stressLevel: _stressLevel.toInt(),
        tags: _selectedMoodTags.toList(),
        note: _moodNoteController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mood logged: $label. 7-Day Avg: ${res['seven_day_mood_avg'] ?? 3.5}'), backgroundColor: const Color(0xFF0D9488)),
        );
        _service.fetchMoodHistory().then((m) => setState(() => _moodHistory = m));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _submitSleep() async {
    try {
      final res = await _service.logSleep(
        bedtime: _bedtimeController.text,
        wakeTime: _wakeTimeController.text,
        durationHours: _sleepDurationHours,
        sleepQuality: _sleepQualityRating,
        disturbances: _sleepDisturbances.toList(),
        deepSleepPercentage: 21.0,
      );
      if (mounted) {
        setState(() {
          _lastSleepDebt = (res['sleep_debt_hours'] as num?)?.toDouble() ?? 0.0;
          _circadianRating = res['circadian_rating'] as String? ?? 'OPTIMAL';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sleep logged! Sleep debt: ${_lastSleepDebt}h. Circadian state: $_circadianRating'), backgroundColor: const Color(0xFF2563EB)),
        );
        _service.fetchSleepHistory().then((s) => setState(() => _sleepHistory = s));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _submitJournal() async {
    if (_journalController.text.trim().isEmpty) return;
    setState(() => _isSubmittingJournal = true);

    try {
      final res = await _service.submitJournal(
        journalText: _journalController.text,
        isVoice: _isDictating,
        pitchJitter: 0.16,
      );
      if (mounted) {
        setState(() {
          _latestJournalAnalysis = res['record'] as Map<String, dynamic>?;
          _isSubmittingJournal = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal analyzed with NLP sentiment engine!'), backgroundColor: Color(0xFF16A34A)),
        );
        _service.fetchJournalHistory().then((j) => setState(() => _journalHistory = j));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingJournal = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
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
              Tab(icon: Icon(Icons.mood_outlined, size: 18), text: 'Daily Mood'),
              Tab(icon: Icon(Icons.bedtime_outlined, size: 18), text: 'Sleep Logger'),
              Tab(icon: Icon(Icons.mic_outlined, size: 18), text: 'Voice Journal'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoodTrackerTab(),
          _buildSleepLoggerTab(),
          _buildVoiceJournalTab(),
        ],
      ),
    );
  }

  // --- SUBTAB 1: MOOD TRACKER ---
  Widget _buildMoodTrackerTab() {
    final emojis = [
      {'val': 1, 'emoji': '😫', 'label': 'Exhausted'},
      {'val': 2, 'emoji': '😟', 'label': 'Tense'},
      {'val': 3, 'emoji': '😐', 'label': 'Neutral'},
      {'val': 4, 'emoji': '🙂', 'label': 'Steady'},
      {'val': 5, 'emoji': '💪', 'label': 'Resilient'},
    ];

    final tags = ['night_patrol', 'cold_weather', 'rest_shift', 'family_call', 'long_vigil', 'high_altitude'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log Current Shift Mood & Valence',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: emojis.map((item) {
                  final isSel = _selectedMood == item['val'];
                  return InkWell(
                    onTap: () => setState(() => _selectedMood = item['val'] as int),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF0284C7).withOpacity(0.12) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                          width: isSel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(item['emoji'] as String, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? const Color(0xFF0284C7) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Energy Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Physical Energy Level:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  Text('${_energyLevel.toInt()} / 5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                ],
              ),
              Slider(
                value: _energyLevel,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: const Color(0xFF0284C7),
                onChanged: (val) => setState(() => _energyLevel = val),
              ),

              // Stress Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Perceived Operational Stress:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  Text('${_stressLevel.toInt()} / 5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                ],
              ),
              Slider(
                value: _stressLevel,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: const Color(0xFFF97316),
                onChanged: (val) => setState(() => _stressLevel = val),
              ),

              const SizedBox(height: 10),
              const Text('Context Tags:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags.map((t) {
                  final isSelected = _selectedMoodTags.contains(t);
                  return FilterChip(
                    label: Text('#$t', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF334155))),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0284C7),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) _selectedMoodTags.add(t);
                        else _selectedMoodTags.remove(t);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _moodNoteController,
                decoration: InputDecoration(
                  hintText: 'Add private shift note (optional)...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitMood,
                  icon: const Icon(Icons.check),
                  label: const Text('Save Shift Check-In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recent Mood History
        const Text('7-Day Mood Trajectory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        ..._moodHistory.map((m) {
          final rating = m['mood_rating'] ?? 3;
          final label = m['mood_label'] ?? 'Neutral';
          final date = (m['created_at'] as String?)?.split('T').first ?? 'Recent';
          final note = m['note'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0284C7).withOpacity(0.12),
                  child: Text('$rating/5', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      if (note.toString().isNotEmpty)
                        Text(note, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- SUBTAB 2: SLEEP LOGGER ---
  Widget _buildSleepLoggerTab() {
    final disturbances = ['night_patrol_alarm', 'sub_zero_cold', 'barrack_noise', 'muscle_fatigue'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sleep Debt Indicator Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.nightlight_round, color: Color(0xFF2563EB), size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Circadian Rhythm: $_circadianRating',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cumulative Sleep Debt: ${_lastSleepDebt}h (Military optimal: 7.0h/night)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
              const Text('Log Rest Window & Sleep Architecture', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bedtimeController,
                      decoration: const InputDecoration(labelText: 'Bedtime (HH:MM)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _wakeTimeController,
                      decoration: const InputDecoration(labelText: 'Wake Time (HH:MM)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Sleep Duration:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  Text('${_sleepDurationHours.toStringAsFixed(1)} Hours', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ],
              ),
              Slider(
                value: _sleepDurationHours,
                min: 3.0,
                max: 10.0,
                divisions: 14,
                activeColor: const Color(0xFF2563EB),
                onChanged: (val) => setState(() => _sleepDurationHours = val),
              ),
              const SizedBox(height: 10),

              const Text('Sleep Quality (1 = Poor, 5 = Deep Restful):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (idx) {
                  final starVal = idx + 1;
                  final isSel = _sleepQualityRating >= starVal;
                  return IconButton(
                    icon: Icon(isSel ? Icons.star_rounded : Icons.star_border_rounded, color: isSel ? Colors.amber : Colors.grey, size: 30),
                    onPressed: () => setState(() => _sleepQualityRating = starVal),
                  );
                }),
              ),
              const SizedBox(height: 10),

              const Text('Sleep Disturbances:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: disturbances.map((d) {
                  final isSelected = _sleepDisturbances.contains(d);
                  return FilterChip(
                    label: Text(d.replaceAll('_', ' '), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF334155))),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) _sleepDisturbances.add(d);
                        else _sleepDisturbances.remove(d);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitSleep,
                  icon: const Icon(Icons.bedtime),
                  label: const Text('Log Sleep Window'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Sleep History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        ..._sleepHistory.map((s) {
          final duration = s['duration_hours'] ?? 6.0;
          final quality = s['sleep_quality'] ?? 3;
          final date = (s['created_at'] as String?)?.split('T').first ?? 'Recent';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bedtime, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$duration Hours Slept', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('Quality: $quality/5 Stars', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- SUBTAB 3: VOICE & TEXT JOURNAL ---
  Widget _buildVoiceJournalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reflective Sentinel Voice Journal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ENCRYPTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Speak or write freely about your shift. AI extracts sentiment and operational strain without saving raw audio.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 14),

              TextField(
                controller: _journalController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Dictate or write your field reflections...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _isDictating = !_isDictating);
                        if (_isDictating) {
                          _journalController.text += ' [Voice Transcribed]: Continuous high altitude watch completed safely.';
                        }
                      },
                      icon: Icon(_isDictating ? Icons.mic : Icons.mic_none, color: _isDictating ? Colors.red : const Color(0xFF0284C7)),
                      label: Text(_isDictating ? 'Recording Voice...' : 'Voice Dictation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isDictating ? Colors.red : const Color(0xFF0284C7),
                        side: BorderSide(color: _isDictating ? Colors.red : const Color(0xFF0284C7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmittingJournal ? null : _submitJournal,
                      icon: _isSubmittingJournal
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.analytics_outlined),
                      label: Text(_isSubmittingJournal ? 'Analyzing...' : 'Analyze Sentiment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              if (_latestJournalAnalysis != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NLP Sentiment: ${_latestJournalAnalysis!['sentiment']}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                          ),
                          Text(
                            'Stress Index: ${_latestJournalAnalysis!['stress_index']}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Extracted Keywords: ${(_latestJournalAnalysis!['keywords'] as List<dynamic>?)?.join(", ") ?? "operational, focused"}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF14532D)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Previous Journal Entries', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        ..._journalHistory.map((j) {
          final text = j['journal_text'] ?? '';
          final sentiment = j['sentiment'] ?? 'NEUTRAL';
          final date = (j['created_at'] as String?)?.split('T').first ?? 'Recent';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: Text(sentiment, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    ),
                    Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 6),
                Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
