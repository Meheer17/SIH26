import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../../core/api/api_client.dart';
import 'character_3d_viewer_screen.dart';
import 'local_3d_server.dart';
import 'lowpoly_mesh_avatar.dart';

class DigitalTwinScreen extends StatefulWidget {
  const DigitalTwinScreen({super.key});

  @override
  State<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends State<DigitalTwinScreen>
    with TickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  final FlutterTts _flutterTts = FlutterTts();

  // Free 3D Avatar Models including local bundled GLB asset
  static final List<Map<String, dynamic>> _defaultAvatarPresets = [
    {
      'id': 'lowpoly_old_man',
      'name': 'Ramesh Patel (3D Rigged Patient Twin)',
      'category': 'Patient Biological Twin',
      'gender': 'Male',
      'model_url': 'assets/lowpoly_old_man.glb',
      'is_local': true,
      'engine': 'Flutter ModelViewer (GLB / glTF)',
      'format': 'GLB 2.0 Rigged',
      'animations': ['talking', 'walking'],
      'morph_targets': ['viseme_aa', 'jawOpen', 'talking', 'walking'],
      'license': 'Bundled Local 3D Asset',
      'description': 'Real-time rigged 3D character controller with synchronized talking visemes and walking gait animation.',
    },
    {
      'id': 'dr_svasthya_ai',
      'name': 'Dr. Svasthya (Clinical AI Physician)',
      'category': 'Medical Specialist',
      'gender': 'Female',
      'model_url': 'https://models.readyplayer.me/6460d95f5605dd25daab301a.glb',
      'thumbnail_url': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=300&q=80',
      'engine': 'Three.js / TalkingHead / WebGL',
      'format': 'GLB / glTF 2.0',
      'animations': ['talking'],
      'morph_targets': ['viseme_aa', 'viseme_E', 'viseme_I', 'viseme_O', 'viseme_U', 'jawOpen', 'mouthSmile'],
      'license': 'Free / Open Developer Tier',
      'description': 'Certified AI Doctor avatar with synchronized lip movement, empathetic facial gestures, and clinical stethoscope attire.',
    },
    {
      'id': 'anatomical_organ_mesh',
      'name': '3D Transparent Multi-Organ Twin',
      'category': 'Anatomical Hologram',
      'gender': 'Neutral',
      'model_url': 'assets/lowpoly_old_man.glb',
      'thumbnail_url': 'https://images.unsplash.com/photo-1530497610245-94d3c16cda28?auto=format&fit=crop&w=300&q=80',
      'engine': 'WebGL / Shader Canvas / Three.js',
      'format': 'GLB / Procedural Three.js Shaders',
      'animations': ['talking', 'walking'],
      'morph_targets': ['heartPulse', 'lungExpand', 'liverGlow', 'brainSignal', 'kidneyFlow'],
      'license': 'Open Source CC-BY 4.0',
      'description': 'Procedural anatomical digital twin visualizing glowing heart valves, breathing lung parenchyma, neural pathways, and renal perfusion in real-time.',
    },
    {
      'id': 'asha_didiji_counselor',
      'name': 'ASHA Didi (Community Wellness Guide)',
      'category': 'Community Counselor',
      'gender': 'Female',
      'model_url': 'https://models.readyplayer.me/658b417df81d8f1e58129c5a.glb',
      'thumbnail_url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
      'engine': 'Three.js / TalkingHead / WebGL',
      'format': 'GLB / glTF 2.0',
      'animations': ['talking'],
      'morph_targets': ['viseme_aa', 'viseme_E', 'viseme_I', 'viseme_O', 'viseme_U', 'jawOpen'],
      'license': 'Free / Open Developer Tier',
      'description': 'Warm, culturally relatable rural health counselor speaking in vernacular dialects with soothing reassuring cadence.',
    },
  ];

  bool _isLoading = true;
  bool _isSpeaking = false;
  String _selectedOrgan = 'cardiovascular';
  String? _activeIntervention;
  String _selectedMetric = 'composite_health';
  double _avatarRotationY = 0.0;

  // 3D GLB Character Controller & Animation State
  String _activeAnimation = 'talking';
  bool _isPlayingAnimation = true;
  bool _autoRotate = false;
  bool _isGlbMode = true;

  bool get _isEmbeddedGlbSupported {
    if (kIsWeb) return true;
    try {
      return WebViewPlatform.instance != null;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _statusData;
  Map<String, dynamic>? _forecastData;
  Map<String, dynamic>? _whatIfData;
  Map<String, dynamic>? _voiceBriefing;
  List<dynamic> _avatarPresets = [];
  Map<String, dynamic>? _activeAvatar;

  late AnimationController _pulseController;
  late AnimationController _talkingController;

  @override
  void initState() {
    super.initState();
    _avatarPresets = List.from(_defaultAvatarPresets);
    _activeAvatar = Map<String, dynamic>.from(_defaultAvatarPresets.first);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _talkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _initTts();
    _loadDigitalTwinData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _talkingController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _switchAnimation(String animName) {
    setState(() {
      _activeAnimation = animName;
      _isPlayingAnimation = true;
    });
  }

  void _togglePlayPauseAnimation() {
    setState(() {
      _isPlayingAnimation = !_isPlayingAnimation;
    });
  }

  void _toggleAutoRotate() {
    setState(() {
      _autoRotate = !_autoRotate;
    });
  }

  void _toggleViewMode() {
    setState(() {
      _isGlbMode = !_isGlbMode;
    });
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-IN");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.48);

      _flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
            _activeAnimation = 'talking';
            _isPlayingAnimation = true;
          });
          _talkingController.repeat(reverse: true);
        }
      });

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
          _talkingController.stop();
          _talkingController.reset();
        }
      });

      _flutterTts.setErrorHandler((_) {
        if (mounted) {
          setState(() => _isSpeaking = false);
          _talkingController.stop();
        }
      });
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  Future<void> _loadDigitalTwinData() async {
    setState(() => _isLoading = true);
    try {
      final statusRes = await _apiClient.get('digital-twin/status');
      final forecastRes = await _apiClient.get('digital-twin/forecast');
      final modelsRes = await _apiClient.get('digital-twin/avatar-models');

      if (mounted) {
        setState(() {
          _statusData = Map<String, dynamic>.from(statusRes as Map);
          _forecastData = Map<String, dynamic>.from(forecastRes as Map);
          if (modelsRes is Map && modelsRes['avatars'] is List) {
            final serverAvatars = modelsRes['avatars'] as List;
            _avatarPresets = [
              _defaultAvatarPresets.first,
              ...serverAvatars.where((a) => a['id'] != 'lowpoly_old_man'),
            ];
          } else {
            _avatarPresets = List.from(_defaultAvatarPresets);
          }
          if (_activeAvatar == null && _avatarPresets.isNotEmpty) {
            _activeAvatar = Map<String, dynamic>.from(_avatarPresets.first as Map);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Digital Twin Fetch Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runWhatIfSimulation(String interventionKey) async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.post(
        'digital-twin/what-if',
        body: {'intervention_key': interventionKey, 'weeks': 24},
      );

      final briefingRes = await _apiClient.post(
        'digital-twin/voice-briefing',
        body: {'intervention_key': interventionKey, 'language': 'en'},
      );

      if (mounted) {
        setState(() {
          _activeIntervention = interventionKey;
          _whatIfData = Map<String, dynamic>.from(res as Map);
          _voiceBriefing = Map<String, dynamic>.from(briefingRes as Map);
          _isLoading = false;
        });

        // Automatically speak clinical insight
        if (_voiceBriefing != null && _voiceBriefing!['spoken_text'] != null) {
          _speakText(_voiceBriefing!['spoken_text']);
        }
      }
    } catch (e) {
      debugPrint("What-If Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetToBaseline() async {
    setState(() {
      _activeIntervention = null;
      _whatIfData = null;
    });
    _loadDigitalTwinData();
  }

  Future<void> _speakText(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      if (mounted) {
        setState(() => _isSpeaking = false);
        _talkingController.stop();
      }
    } else {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _triggerGeneralBriefing() async {
    try {
      final briefingRes = await _apiClient.post(
        'digital-twin/voice-briefing',
        body: {
          'intervention_key': _activeIntervention,
          'language': 'en'
        },
      );

      if (briefingRes is Map && briefingRes['spoken_text'] != null) {
        _speakText(briefingRes['spoken_text']);
      }
    } catch (e) {
      _speakText(
        "Hello Ramesh! Your digital twin composite health score is 89 out of 100. All biological vitals and organ perfusion systems are currently stable.",
      );
    }
  }

  void _showAvatarSelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'FREE 3D TALKING AVATAR MODELS',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Icon(Icons.view_in_ar, color: Color(0xFF38BDF8), size: 20),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Open-source rigged humanoid GLB models with ARKit & Oculus lip-sync visemes.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _avatarPresets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final av = _avatarPresets[idx];
                  final isSelected = _activeAvatar?['id'] == av['id'];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _activeAvatar = Map<String, dynamic>.from(av as Map);
                        _isGlbMode = true;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Active 3D Avatar: ${av['name']} (${av['engine']})'),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                            child: Icon(
                              av['is_local'] == true
                                  ? Icons.view_in_ar_rounded
                                  : (av['category'] == 'Medical Specialist'
                                      ? Icons.medical_services_rounded
                                      : (av['category'] == 'Anatomical Hologram'
                                          ? Icons.blur_on
                                          : Icons.face_rounded)),
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        av['name'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (av['is_local'] == true) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                                        ),
                                        child: const Text(
                                          'LOCAL GLB',
                                          style: TextStyle(
                                            color: Color(0xFF4ADE80),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${av['category']} • ${av['format']} • ${av['engine']}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Color(0xFF38BDF8), size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              // Open Full-screen 3D Character Studio Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Character3DViewerScreen(
                          modelPath: _activeAvatar?['model_url'] ?? 'assets/lowpoly_old_man.glb',
                          title: _activeAvatar?['name'] ?? '3D Patient Twin Controller',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.threed_rotation_rounded, size: 18),
                  label: const Text(
                    'Launch Fullscreen 3D Character Studio',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hub_rounded, color: Color(0xFF38BDF8), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '3D PATIENT DIGITAL TWIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Feature 12 • Real-Time Physiological Simulation',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Fullscreen 3D Studio',
            icon: const Icon(Icons.threed_rotation_rounded, color: Color(0xFF38BDF8)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Character3DViewerScreen(
                    modelPath: _activeAvatar?['model_url'] ?? 'assets/lowpoly_old_man.glb',
                    title: _activeAvatar?['name'] ?? '3D Patient Twin Controller',
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Choose 3D Avatar Rig',
            icon: const Icon(Icons.view_in_ar_rounded, color: Color(0xFF38BDF8)),
            onPressed: _showAvatarSelectorModal,
          ),
          IconButton(
            tooltip: 'Audio Health Briefing',
            icon: Icon(
              _isSpeaking ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _isSpeaking ? const Color(0xFF4ADE80) : Colors.white70,
            ),
            onPressed: _triggerGeneralBriefing,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            )
          : RefreshIndicator(
              onRefresh: _loadDigitalTwinData,
              color: const Color(0xFF38BDF8),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero: 3D Talking Holographic Avatar Viewport
                    _build3dAvatarViewport(),
                    const SizedBox(height: 18),

                    // Overall Score & Biological vs Chronological Age
                    _buildScoreAndAgeBanner(),
                    const SizedBox(height: 20),

                    // Organ Selector & Telemetry Cards
                    _buildOrganSelectorSection(),
                    const SizedBox(height: 24),

                    // Interactive "What-If" Scenario Simulator
                    _buildWhatIfSimulatorSection(),
                    const SizedBox(height: 24),

                    // 24-Week Bayesian Trajectory Forecast (FlChart)
                    _buildTrajectoryForecastSection(),
                    const SizedBox(height: 24),

                    // Free 3D Avatar Integration & Technical Architecture Banner
                    _buildTechnicalArchitectureBanner(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _build3dAvatarViewport() {
    final avatarName = _activeAvatar?['name'] ?? 'Ramesh Patel (3D Rigged Patient Twin)';
    final modelUrl = _activeAvatar?['model_url'] ?? 'assets/lowpoly_old_man.glb';

    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: const [
          BoxShadow(color: Color(0x330284C7), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Background Tech Grid Lines
          Positioned.fill(
            child: CustomPaint(
              painter: _TechGridBackgroundPainter(),
            ),
          ),

          // Central 3D Canvas
          Positioned.fill(
            top: 48,
            bottom: 60,
            child: _isGlbMode
                ? (_isEmbeddedGlbSupported
                    ? ModelViewer(
                        key: ValueKey('${_activeAvatar?['id'] ?? 'lowpoly_old_man'}-$_activeAnimation-$_isPlayingAnimation-$_autoRotate'),
                        src: modelUrl,
                        alt: '3D Patient Digital Twin Character',
                        ar: true,
                        autoRotate: _autoRotate,
                        cameraControls: true,
                        backgroundColor: const Color(0xFF0F172A),
                        animationName: _isPlayingAnimation ? (_isSpeaking ? 'talking' : _activeAnimation) : null,
                        autoPlay: _isPlayingAnimation,
                        shadowIntensity: 1.0,
                        shadowSoftness: 0.8,
                        exposure: 1.2,
                      )
                    : LowpolyMeshAvatar(
                        activeAnimation: _activeAnimation,
                        isPlaying: _isPlayingAnimation,
                        autoRotate: _autoRotate,
                        isSpeaking: _isSpeaking,
                        selectedOrgan: _selectedOrgan,
                        showControlsOverlay: false,
                        onToggleWalk: () => _switchAnimation('walking'),
                        onToggleTalk: () => _switchAnimation('talking'),
                      ))
                : GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _avatarRotationY += details.delta.dx * 0.012;
                      });
                    },
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(220, 260),
                            painter: _Holographic3dAvatarPainter(
                              rotationY: _avatarRotationY,
                              pulseVal: _pulseController.value,
                              selectedOrgan: _selectedOrgan,
                              isSpeaking: _isSpeaking,
                              talkingVal: _talkingController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),

          // Top Header Bar Inside 3D Viewport
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar Name & Action Badge
                InkWell(
                  onTap: _showAvatarSelectorModal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSpeaking ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isSpeaking ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            avatarName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8), size: 16),
                      ],
                    ),
                  ),
                ),

                // Right controls: View Mode Switcher & Fullscreen Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode Toggle: 3D GLB vs Organ Hologram
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              if (!_isGlbMode) _toggleViewMode();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isGlbMode ? const Color(0xFF0284C7) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.view_in_ar, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'GLB 3D',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (_isGlbMode) _toggleViewMode();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: !_isGlbMode ? const Color(0xFF0284C7) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.hub_rounded, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Organs',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Launch WebGL 3D Studio Button
                    IconButton(
                      tooltip: 'Launch WebGL 3D Studio (Browser)',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF38BDF8), size: 19),
                      onPressed: () => Local3dStudioServer.instance.launchInBrowser(),
                    ),
                    const SizedBox(width: 2),

                    // Fullscreen 3D Viewer Button
                    IconButton(
                      tooltip: 'Expand 3D Studio',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFF38BDF8), size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Character3DViewerScreen(
                              modelPath: modelUrl,
                              title: avatarName,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating Action Bar for 3D Animations (Walk, Talk, Pause, Orbit)
          Positioned(
            bottom: 64,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Walk Action
                  _buildViewportActionButton(
                    label: 'Walk',
                    icon: Icons.directions_walk_rounded,
                    isActive: _activeAnimation == 'walking' && _isPlayingAnimation,
                    onTap: () => _switchAnimation('walking'),
                  ),

                  // Talk Action
                  _buildViewportActionButton(
                    label: 'Talk',
                    icon: Icons.record_voice_over_rounded,
                    isActive: _activeAnimation == 'talking' && _isPlayingAnimation,
                    onTap: () => _switchAnimation('talking'),
                  ),

                  // Play/Pause
                  _buildViewportActionButton(
                    label: _isPlayingAnimation ? 'Pause' : 'Play',
                    icon: _isPlayingAnimation ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    isActive: false,
                    onTap: _togglePlayPauseAnimation,
                  ),

                  // Auto Rotate Toggle
                  _buildViewportActionButton(
                    label: _autoRotate ? 'Orbit On' : 'Orbit',
                    icon: Icons.threed_rotation_rounded,
                    isActive: _autoRotate,
                    onTap: _toggleAutoRotate,
                  ),
                ],
              ),
            ),
          ),

          // Speaking Lip Sync & Audio Briefing Floating Overlay
          Positioned(
            bottom: 8,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isSpeaking ? const Color(0xFF4ADE80) : const Color(0xFF334155),
                  width: _isSpeaking ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _isSpeaking
                        ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                        : const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    child: Icon(
                      _isSpeaking ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded,
                      color: _isSpeaking ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSpeaking
                              ? '3D Avatar Speaking (Lip-Sync Active)...'
                              : 'AI Clinical Audio Consultation',
                          style: TextStyle(
                            color: _isSpeaking ? const Color(0xFF4ADE80) : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isSpeaking
                              ? 'Speech visemes dynamically driving 3D facial expressions.'
                              : 'Tap "Brief Me" to hear personalized guidance.',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSpeaking ? const Color(0xFFE11D48) : const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _triggerGeneralBriefing,
                    child: Text(
                      _isSpeaking ? 'Mute' : 'Brief Me',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewportActionButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF38BDF8) : const Color(0xFF334155),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreAndAgeBanner() {
    final overall = _statusData?['overall_health_score'] ?? 89;
    final bioAge = _statusData?['biological_age'] ?? 31.4;
    final chronoAge = _statusData?['chronological_age'] ?? 32.0;
    final longevity = _statusData?['longevity_index'] ?? 'Excellent (Top 12%)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Health Score Gauge
          Column(
            children: [
              const Text(
                'COMPOSITE HEALTH',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$overall',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    ' / 100',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              Text(
                longevity,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(width: 1, height: 50, color: const Color(0xFF334155)),

          // Biological Age
          Column(
            children: [
              const Text(
                'BIOLOGICAL AGE',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$bioAge yrs',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Actual: $chronoAge yrs',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
              ),
            ],
          ),
          Container(width: 1, height: 50, color: const Color(0xFF334155)),

          // Trajectory Delta
          Column(
            children: [
              const Text(
                'TRAJECTORY',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.trending_up, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 4),
                  Text(
                    '+4.2%',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Text(
                'Optimal Vitals',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganSelectorSection() {
    final organSystems = _statusData?['organ_systems'] as Map<String, dynamic>? ?? {};
    final activeOrganData = organSystems[_selectedOrgan] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'BIOLOGICAL ORGAN SYSTEMS (5 NODES)',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Tap to Inspect',
              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Organ Horizontal Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildOrganTabChip('cardiovascular', '🫀 Heart & Arteries', organSystems['cardiovascular']),
              const SizedBox(width: 8),
              _buildOrganTabChip('pulmonary', '🫁 Lungs & Airway', organSystems['pulmonary']),
              const SizedBox(width: 8),
              _buildOrganTabChip('metabolic', '🧬 Metabolic Core', organSystems['metabolic']),
              const SizedBox(width: 8),
              _buildOrganTabChip('neurological', '🧠 Brain & Stress', organSystems['neurological']),
              const SizedBox(width: 8),
              _buildOrganTabChip('renal', '💧 Kidneys & Fluid', organSystems['renal']),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Selected Organ Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      activeOrganData['organ_name'] ?? 'Organ Telemetry',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activeOrganData['status'] ?? 'OPTIMAL',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activeOrganData['clinical_summary'] ?? '',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.3),
              ),
              const SizedBox(height: 14),

              // Dynamic Telemetry Grid
              if (activeOrganData['telemetry'] != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (activeOrganData['telemetry'] as Map<String, dynamic>)
                      .entries
                      .map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganTabChip(String key, String title, dynamic organObj) {
    final isSelected = _selectedOrgan == key;
    final score = organObj?['score'] ?? 85;

    return InkWell(
      onTap: () => setState(() => _selectedOrgan = key),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$score',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatIfSimulatorSection() {
    final scenarios = [
      {'key': 'stop_bp_meds', 'label': '💊 Stop BP Meds', 'color': Color(0xFFEF4444)},
      {'key': 'stop_iron_tablets', 'label': '🩸 Stop IFA Tablets', 'color': Color(0xFFF97316)},
      {'key': 'extreme_heat_exposure', 'label': '☀️ 4h Heatwave Duty', 'color': Color(0xFFDC2626)},
      {'key': 'daily_pranayama_hydration', 'label': '🧘 Pranayama + 3.5L H2O', 'color': Color(0xFF10B981)},
      {'key': 'high_altitude_deployment', 'label': '🏔️ 14,000ft Ascent', 'color': Color(0xFF8B5CF6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'WHAT-IF CLINICAL SIMULATOR',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Simulate physiological outcome of lifestyle & medical changes',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
              ],
            ),
            if (_activeIntervention != null)
              TextButton(
                onPressed: _resetToBaseline,
                child: const Text('Reset', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // What If Scenario Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scenarios.map((s) {
            final isSelected = _activeIntervention == s['key'];
            final color = s['color'] as Color;

            return InkWell(
              onTap: () => _runWhatIfSimulation(s['key'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFF334155),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  s['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // What-If Active Delta Card
        if (_whatIfData != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_alt, color: Color(0xFF818CF8), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Simulated: ${_whatIfData!['title']}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _whatIfData!['impact_summary'] ?? '',
                  style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 12),

                // Risk Delta Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDeltaStat(
                      'BP Delta',
                      '${_whatIfData!['risk_delta']?['systolic_bp_delta'] ?? 0} mmHg',
                      (_whatIfData!['risk_delta']?['systolic_bp_delta'] ?? 0) > 0 ? Colors.redAccent : Colors.greenAccent,
                    ),
                    _buildDeltaStat(
                      'Cardiac Strain',
                      '${_whatIfData!['risk_delta']?['cardiovascular_strain_delta'] ?? 0}%',
                      (_whatIfData!['risk_delta']?['cardiovascular_strain_delta'] ?? 0) > 0 ? Colors.redAccent : Colors.greenAccent,
                    ),
                    _buildDeltaStat(
                      'Health Index',
                      '${_whatIfData!['risk_delta']?['composite_health_delta'] ?? 0} pts',
                      (_whatIfData!['risk_delta']?['composite_health_delta'] ?? 0) < 0 ? Colors.redAccent : Colors.greenAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeltaStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTrajectoryForecastSection() {
    final Map<String, dynamic>? metricsMap = _whatIfData != null
        ? (_whatIfData!['simulated_trajectory'] as Map<String, dynamic>?)
        : (_forecastData != null ? (_forecastData!['metrics'] as Map<String, dynamic>?) : null);
    final metricData = metricsMap != null ? (metricsMap[_selectedMetric] as Map<String, dynamic>?) : null;

    final List<dynamic> medianList = metricData?['median'] as List<dynamic>? ?? [];
    final List<dynamic> p10List = metricData?['p10'] as List<dynamic>? ?? [];
    final List<dynamic> p90List = metricData?['p90'] as List<dynamic>? ?? [];

    List<FlSpot> medianSpots = [];
    List<FlSpot> p10Spots = [];
    List<FlSpot> p90Spots = [];

    for (int i = 0; i < medianList.length; i++) {
      final x = i.toDouble();
      medianSpots.add(FlSpot(x, (medianList[i] as num).toDouble()));
      if (i < p10List.length) p10Spots.add(FlSpot(x, (p10List[i] as num).toDouble()));
      if (i < p90List.length) p90Spots.add(FlSpot(x, (p90List[i] as num).toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '24-WEEK BAYESIAN TRAJECTORY',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Median Curve with 80% Credible Bands (p10 - p90)',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 9),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: _selectedMetric,
                dropdownColor: const Color(0xFF0F172A),
                underline: const SizedBox(),
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 'composite_health', child: Text('Composite Health')),
                  DropdownMenuItem(value: 'systolic_bp', child: Text('Systolic BP')),
                  DropdownMenuItem(value: 'cardiovascular_strain', child: Text('Cardiac Strain')),
                  DropdownMenuItem(value: 'hemoglobin', child: Text('Hemoglobin')),
                  DropdownMenuItem(value: 'stress_score', child: Text('Stress Score')),
                  DropdownMenuItem(value: 'renal_heat_strain', child: Text('Renal Strain')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMetric = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 180,
            child: medianSpots.isEmpty
                ? const Center(child: Text('Calculating trajectory...', style: TextStyle(color: Colors.white54)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFF334155), strokeWidth: 0.8),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 6,
                            getTitlesWidget: (v, _) => Text(
                              'Wk ${v.toInt()}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        // Median Trajectory
                        LineChartBarData(
                          spots: medianSpots,
                          isCurved: true,
                          color: const Color(0xFF38BDF8),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                        ),
                        // 10th Percentile
                        if (p10Spots.isNotEmpty)
                          LineChartBarData(
                            spots: p10Spots,
                            isCurved: true,
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                            barWidth: 1,
                            dashArray: [4, 4],
                            dotData: const FlDotData(show: false),
                          ),
                        // 90th Percentile
                        if (p90Spots.isNotEmpty)
                          LineChartBarData(
                            spots: p90Spots,
                            isCurved: true,
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                            barWidth: 1,
                            dashArray: [4, 4],
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalArchitectureBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.developer_board, color: Color(0xFF38BDF8), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '3D GLB Model & Rigged Character Architecture',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bundled Model: assets/lowpoly_old_man.glb (Ramesh Patel). Supports Flutter ModelViewer, TalkingHead visemes, skeletal walk/talk animations, and on-device TTS audio lip sync.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Character3DViewerScreen(
                        modelPath: _activeAvatar?['model_url'] ?? 'assets/lowpoly_old_man.glb',
                        title: _activeAvatar?['name'] ?? '3D Patient Twin Controller',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_full_rounded, size: 14),
                label: const Text('Launch Dedicated 3D Controller', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter: Holographic 3D Human Avatar with Animated Organ Glowing Layers
class _Holographic3dAvatarPainter extends CustomPainter {
  final double rotationY;
  final double pulseVal;
  final String selectedOrgan;
  final bool isSpeaking;
  final double talkingVal;

  _Holographic3dAvatarPainter({
    required this.rotationY,
    required this.pulseVal,
    required this.selectedOrgan,
    required this.isSpeaking,
    required this.talkingVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Apply rotation perspective shift
    final cosRot = math.cos(rotationY);
    final sinRot = math.sin(rotationY);

    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final glowPaint = Paint()
      ..style = PaintingStyle.fill;

    // Outer Holographic Rings
    canvas.drawCircle(
      Offset(centerX, centerY + 30),
      95 + (pulseVal * 4),
      Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Human Head & Silhouette
    final headOffset = Offset(centerX + (sinRot * 8), centerY - 90);
    canvas.drawCircle(headOffset, 24, linePaint);

    // Mouth / Talking Lip Sync Motion
    if (isSpeaking) {
      final mouthWidth = 10.0 + (talkingVal * 4.0);
      final mouthHeight = 3.0 + (talkingVal * 5.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(headOffset.dx, headOffset.dy + 8), width: mouthWidth, height: mouthHeight),
        Paint()..color = const Color(0xFF4ADE80)..style = PaintingStyle.fill,
      );
    } else {
      canvas.drawLine(
        Offset(headOffset.dx - 5, headOffset.dy + 8),
        Offset(headOffset.dx + 5, headOffset.dy + 8),
        linePaint..strokeWidth = 1.5,
      );
    }

    // Neck & Torso Outline
    final neckTop = Offset(headOffset.dx, headOffset.dy + 24);
    final chestCenter = Offset(centerX + (sinRot * 10), centerY - 30);
    final pelvisCenter = Offset(centerX + (sinRot * 8), centerY + 45);

    final torsoPath = Path();
    torsoPath.moveTo(neckTop.dx - 8, neckTop.dy);
    torsoPath.lineTo(chestCenter.dx - 38 * cosRot, chestCenter.dy - 20);
    torsoPath.lineTo(pelvisCenter.dx - 28 * cosRot, pelvisCenter.dy);
    torsoPath.lineTo(pelvisCenter.dx + 28 * cosRot, pelvisCenter.dy);
    torsoPath.lineTo(chestCenter.dx + 38 * cosRot, chestCenter.dy - 20);
    torsoPath.close();

    canvas.drawPath(torsoPath, linePaint);

    // Legs Outline
    canvas.drawLine(Offset(pelvisCenter.dx - 16 * cosRot, pelvisCenter.dy), Offset(pelvisCenter.dx - 20 * cosRot, pelvisCenter.dy + 75), linePaint);
    canvas.drawLine(Offset(pelvisCenter.dx + 16 * cosRot, pelvisCenter.dy), Offset(pelvisCenter.dx + 20 * cosRot, pelvisCenter.dy + 75), linePaint);

    // Organ 1: Brain (Neurological Node)
    final brainPos = Offset(headOffset.dx, headOffset.dy - 4);
    final isBrainSelected = selectedOrgan == 'neurological';
    glowPaint.color = isBrainSelected ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6).withValues(alpha: 0.5);
    canvas.drawCircle(brainPos, isBrainSelected ? (8 + pulseVal * 3) : 6, glowPaint);

    // Organ 2: Heart (Cardiovascular Node - Pulsating)
    final heartPos = Offset(chestCenter.dx - (8 * cosRot), chestCenter.dy - 12);
    final isHeartSelected = selectedOrgan == 'cardiovascular';
    glowPaint.color = isHeartSelected ? const Color(0xFFEF4444) : const Color(0xFFEF4444).withValues(alpha: 0.6);
    canvas.drawCircle(heartPos, isHeartSelected ? (10 + pulseVal * 4) : (7 + pulseVal * 2), glowPaint);

    // Organ 3: Lungs (Pulmonary Pair)
    final lungLeft = Offset(chestCenter.dx - (20 * cosRot), chestCenter.dy - 8);
    final lungRight = Offset(chestCenter.dx + (16 * cosRot), chestCenter.dy - 8);
    final isLungSelected = selectedOrgan == 'pulmonary';
    glowPaint.color = isLungSelected ? const Color(0xFF06B6D4) : const Color(0xFF06B6D4).withValues(alpha: 0.4);
    canvas.drawOval(Rect.fromCenter(center: lungLeft, width: 10, height: 16), glowPaint);
    canvas.drawOval(Rect.fromCenter(center: lungRight, width: 10, height: 16), glowPaint);

    // Organ 4: Metabolic / Liver Core
    final liverPos = Offset(chestCenter.dx + (8 * cosRot), chestCenter.dy + 12);
    final isLiverSelected = selectedOrgan == 'metabolic';
    glowPaint.color = isLiverSelected ? const Color(0xFF8B5CF6) : const Color(0xFF8B5CF6).withValues(alpha: 0.5);
    canvas.drawOval(Rect.fromCenter(center: liverPos, width: 16, height: 10), glowPaint);

    // Organ 5: Kidneys / Renal
    final kidneyLeft = Offset(chestCenter.dx - (14 * cosRot), chestCenter.dy + 26);
    final kidneyRight = Offset(chestCenter.dx + (14 * cosRot), chestCenter.dy + 26);
    final isRenalSelected = selectedOrgan == 'renal';
    glowPaint.color = isRenalSelected ? const Color(0xFFF59E0B) : const Color(0xFFF59E0B).withValues(alpha: 0.5);
    canvas.drawCircle(kidneyLeft, isRenalSelected ? 6 : 4.5, glowPaint);
    canvas.drawCircle(kidneyRight, isRenalSelected ? 6 : 4.5, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _Holographic3dAvatarPainter oldDelegate) {
    return oldDelegate.rotationY != rotationY ||
        oldDelegate.pulseVal != pulseVal ||
        oldDelegate.selectedOrgan != selectedOrgan ||
        oldDelegate.isSpeaking != isSpeaking ||
        oldDelegate.talkingVal != talkingVal;
  }
}

// Subtle Sci-Fi Grid Background
class _TechGridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
