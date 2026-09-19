import 'dart:async';
import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class TacticalResourcesTab extends StatefulWidget {
  const TacticalResourcesTab({super.key});

  @override
  State<TacticalResourcesTab> createState() => _TacticalResourcesTabState();
}

class _TacticalResourcesTabState extends State<TacticalResourcesTab> with SingleTickerProviderStateMixin {
  final RakshaSetuService _service = RakshaSetuService();

  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;

  bool _isBreathingActive = false;
  int _breathPhase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  int _cycleCount = 0;
  Timer? _phaseTimer;
  final List<String> _phaseLabels = ['INHALE (सांस लें)', 'HOLD (रोकें)', 'EXHALE (छोड़ें)', 'HOLD (शांत रहें)'];
  final List<Color> _phaseColors = [const Color(0xFF0284C7), const Color(0xFF0D9488), const Color(0xFF16A34A), const Color(0xFF4F46E5)];

  List<dynamic> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _loadResources();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    try {
      final res = await _service.fetchResources();
      if (mounted) {
        setState(() {
          _resources = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleBreathing() {
    if (_isBreathingActive) {
      _stopBreathing();
    } else {
      _startBreathing();
    }
  }

  void _startBreathing() {
    setState(() {
      _isBreathingActive = true;
      _breathPhase = 0;
      _cycleCount = 0;
    });

    _breathingController.forward();
    _startPhaseTimer();
  }

  void _startPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_isBreathingActive) {
        timer.cancel();
        return;
      }

      setState(() {
        _breathPhase = (_breathPhase + 1) % 4;
        if (_breathPhase == 0) {
          _cycleCount++;
          _breathingController.forward(from: 0.0);
        } else if (_breathPhase == 2) {
          _breathingController.reverse(from: 1.0);
        }
      });
    });
  }

  void _stopBreathing() {
    _phaseTimer?.cancel();
    _breathingController.stop();
    setState(() => _isBreathingActive = false);

    if (_cycleCount >= 1) {
      _service.logResourceActivity('RES-001', 'BOX_BREATHING', 4);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completed $_cycleCount breathing cycles! +40 Resilience Points awarded.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  void _openResourceModal(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['category'] ?? 'Wellness',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                  Text('${item['duration_mins'] ?? 10} Mins Session', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item['title'] ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                item['hindi_title'] ?? '',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Text(
                item['description'] ?? '',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.play_circle_fill, color: Color(0xFF0284C7), size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Simulated Audio Session Playing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text('High quality vocal guidance with ambient theta waves', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _service.logResourceActivity(item['id'] ?? 'RES-001', 'AUDIO_MEDITATION', item['duration_mins'] ?? 10);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session completed! +50 Points awarded.'), backgroundColor: Color(0xFF16A34A)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Complete & Earn Points'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Tactical Box Breathing Interactive Visualizer
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.air, color: Color(0xFF0284C7), size: 22),
                      SizedBox(width: 8),
                      Text('4-4-4-4 Tactical Box Breathing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Cycles: $_cycleCount',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'De-escalate acute sympathetic heart rate spikes and calm mind during high-vigil posts.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Animated Breathing Sphere
              Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    final scale = _isBreathingActive ? _scaleAnimation.value : 1.0;
                    final curColor = _phaseColors[_breathPhase];

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: curColor.withOpacity(0.14),
                          border: Border.all(color: curColor, width: 3),
                          boxShadow: [
                            BoxShadow(color: curColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 4),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _phaseLabels[_breathPhase].split(' ').first,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: curColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _phaseLabels[_breathPhase].split(' ').last,
                                style: TextStyle(fontSize: 11, color: curColor),
                              ),
                              const SizedBox(height: 4),
                              const Text('4 SECONDS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _toggleBreathing,
                icon: Icon(_isBreathingActive ? Icons.stop_rounded : Icons.play_arrow_rounded),
                label: Text(_isBreathingActive ? 'Stop Exercise' : 'Start 4-4-4-4 Breathing Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBreathingActive ? Colors.red : const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Curated Defense Wellness Library
        const Text('Curated Operational Wellness Library', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._resources.map((item) {
          final title = item['title'] ?? '';
          final hindi = item['hindi_title'] ?? '';
          final desc = item['description'] ?? '';
          final mins = item['duration_mins'] ?? 10;
          final cat = item['category'] ?? 'Military Resilience';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.headphones_rounded, color: Color(0xFF0284C7), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                      const SizedBox(height: 2),
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text(hindi, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('⏱ $mins Mins Session', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          ElevatedButton.icon(
                            onPressed: () => _openResourceModal(item as Map<String, dynamic>),
                            icon: const Icon(Icons.play_arrow, size: 14),
                            label: const Text('Play Audio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
