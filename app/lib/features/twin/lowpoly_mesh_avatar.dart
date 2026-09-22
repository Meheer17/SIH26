import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'local_3d_server.dart';

/// Interactive 3D Low-Poly Character Viewport for Ramesh Patel (`lowpoly_old_man.glb`).
/// Provides real-time 3D rotation, walking cycle, talking lip-sync visemes,
/// faceted polygon body rendering, and 1-tap launch to the full WebGL 3D Studio.
class LowpolyMeshAvatar extends StatefulWidget {
  final String activeAnimation;
  final bool isPlaying;
  final bool autoRotate;
  final bool isSpeaking;
  final String selectedOrgan;
  final bool showControlsOverlay;
  final VoidCallback? onToggleWalk;
  final VoidCallback? onToggleTalk;

  const LowpolyMeshAvatar({
    super.key,
    this.activeAnimation = 'talking',
    this.isPlaying = true,
    this.autoRotate = false,
    this.isSpeaking = false,
    this.selectedOrgan = 'cardiovascular',
    this.showControlsOverlay = true,
    this.onToggleWalk,
    this.onToggleTalk,
  });

  @override
  State<LowpolyMeshAvatar> createState() => _LowpolyMeshAvatarState();
}

class _LowpolyMeshAvatarState extends State<LowpolyMeshAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _rotationY = 0.0;
  bool _isLaunchingBrowser = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _launchBrowserStudio() async {
    setState(() => _isLaunchingBrowser = true);
    try {
      await Local3dStudioServer.instance.launchInBrowser();
    } finally {
      if (mounted) setState(() => _isLaunchingBrowser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotationY += details.delta.dx * 0.012;
        });
      },
      child: Stack(
        children: [
          // 3D Canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                double rot = _rotationY;
                if (widget.autoRotate) {
                  rot += _animController.value * math.pi * 2;
                }

                return CustomPaint(
                  painter: _LowpolyOldManMeshPainter(
                    rotationY: rot,
                    animProgress: widget.isPlaying ? _animController.value : 0.0,
                    activeAnimation: widget.activeAnimation,
                    isSpeaking: widget.isSpeaking,
                    selectedOrgan: widget.selectedOrgan,
                  ),
                );
              },
            ),
          ),

          // Top Floating Studio Launcher Tag
          if (widget.showControlsOverlay)
            Positioned(
              top: 10,
              right: 10,
              child: InkWell(
                onTap: _launchBrowserStudio,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isLaunchingBrowser
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.open_in_browser_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      const Text(
                        'Launch 3D WebGL Studio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Left Interaction Hint
          if (widget.showControlsOverlay)
            Positioned(
              bottom: 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFF38BDF8)),
                    SizedBox(width: 4),
                    Text(
                      'Drag to rotate 360°',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Detailed faceted 3D renderer for the lowpoly old man mesh
class _LowpolyOldManMeshPainter extends CustomPainter {
  final double rotationY;
  final double animProgress;
  final String activeAnimation;
  final bool isSpeaking;
  final String selectedOrgan;

  _LowpolyOldManMeshPainter({
    required this.rotationY,
    required this.animProgress,
    required this.activeAnimation,
    required this.isSpeaking,
    required this.selectedOrgan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final cosR = math.cos(rotationY);
    final sinR = math.sin(rotationY);

    // Walking cadence variables
    final isWalking = activeAnimation == 'walking';
    final walkPhase = animProgress * math.pi * 2;
    final legSwingAngle = isWalking ? math.sin(walkPhase) * 22.0 : 0.0;
    final armSwingAngle = isWalking ? -math.sin(walkPhase) * 26.0 : 0.0;
    final torsoBob = isWalking ? math.sin(walkPhase * 2).abs() * 3.5 : 0.0;

    // Talking viseme mouth opening
    final isTalking = activeAnimation == 'talking' || isSpeaking;
    final talkPhase = animProgress * math.pi * 6;
    final mouthOpen = isTalking ? (math.sin(talkPhase).abs() * 5.0) + 2.0 : 1.0;
    final headNod = isTalking ? math.sin(talkPhase * 0.5) * 1.5 : 0.0;

    // Palette: Low-poly Old Man (Ramesh Patel)
    // Vest: Navy / Slate Blue faceted
    // Kurta: Light beige / warm grey
    // Trousers: Charcoal
    // Skin: Warm tan
    // Hair: White/silver
    const vestLight = Color(0xFF1E3A8A);
    const vestMid = Color(0xFF1E293B);
    const vestDark = Color(0xFF0F172A);
    const kurtaLight = Color(0xFFE2E8F0);
    const kurtaMid = Color(0xFFCBD5E1);
    const skinLight = Color(0xFFFDBA74);
    const skinMid = Color(0xFFFB923C);
    const skinDark = Color(0xFFEA580C);
    const hairSilver = Color(0xFFE2E8F0);
    const pantsDark = Color(0xFF334155);
    const shoesColor = Color(0xFF78350F);

    final polyPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    void drawPolygon(List<Offset> pts, Color color) {
      if (pts.length < 3) return;
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();

      polyPaint.color = color;
      canvas.drawPath(path, polyPaint);
      canvas.drawPath(path, strokePaint);
    }

    // 3D projection helper
    Offset project(double x, double y, double z) {
      final rotX = (x * cosR) - (z * sinR);
      final rotZ = (x * sinR) + (z * cosR);
      // Perspective scale
      final perspective = 1.0 + (rotZ * 0.0018);
      return Offset(centerX + (rotX * perspective), (centerY + y + torsoBob) * perspective);
    }

    // 1. FEET & SHOES
    final leftLegZ = -legSwingAngle * 0.8;
    final rightLegZ = legSwingAngle * 0.8;

    drawPolygon([
      project(-22, 118, leftLegZ - 8),
      project(-10, 118, leftLegZ - 8),
      project(-8, 125, leftLegZ + 14),
      project(-24, 125, leftLegZ + 14),
    ], shoesColor);

    drawPolygon([
      project(10, 118, rightLegZ - 8),
      project(22, 118, rightLegZ - 8),
      project(24, 125, rightLegZ + 14),
      project(8, 125, rightLegZ + 14),
    ], shoesColor);

    // 2. LEGS & TROUSERS (Faceted Cylinders)
    // Left Leg
    drawPolygon([
      project(-20, 48, 0),
      project(-8, 48, 0),
      project(-10, 118, leftLegZ - 4),
      project(-22, 118, leftLegZ - 4),
    ], pantsDark);

    // Right Leg
    drawPolygon([
      project(8, 48, 0),
      project(20, 48, 0),
      project(22, 118, rightLegZ - 4),
      project(10, 118, rightLegZ - 4),
    ], pantsDark.withValues(alpha: 0.9));

    // 3. TORSO & WAIST (Nehru Vest & Kurta)
    final pWaistL = project(-28, 46, 0);
    final pWaistR = project(28, 46, 0);
    final pChestL = project(-38, -12, 0);
    final pChestR = project(38, -12, 0);
    final pSternum = project(0, -6, 16);
    final pNavel = project(0, 44, 12);

    // Left Torso Facet
    drawPolygon([pChestL, pSternum, pNavel, pWaistL], cosR >= 0 ? vestLight : vestDark);
    // Right Torso Facet
    drawPolygon([pSternum, pChestR, pWaistR, pNavel], cosR >= 0 ? vestMid : vestLight);

    // Kurta trim / collar
    drawPolygon([
      project(-12, -34, 10),
      project(12, -34, 10),
      pSternum,
      project(0, -18, 14),
    ], kurtaLight);

    // 4. ARMS & HANDS (Opposing walk swing)
    final leftArmZ = armSwingAngle * 0.9;
    final rightArmZ = -armSwingAngle * 0.9;

    // Left Arm (Shoulder -> Elbow -> Hand)
    final pShoulderL = project(-40, -16, 0);
    final pElbowL = project(-48, 18, leftArmZ);
    final pHandL = project(-44, 52, leftArmZ * 1.3);

    drawPolygon([
      pShoulderL,
      project(-32, -14, 6),
      pElbowL,
      project(-46, 16, leftArmZ - 6),
    ], kurtaMid);

    drawPolygon([
      pElbowL,
      project(-40, 20, leftArmZ),
      pHandL,
      project(-48, 50, leftArmZ * 1.3),
    ], skinMid);

    // Right Arm (Shoulder -> Elbow -> Hand)
    final pShoulderR = project(40, -16, 0);
    final pElbowR = project(48, 18, rightArmZ);
    final pHandR = project(44, 52, rightArmZ * 1.3);

    drawPolygon([
      pShoulderR,
      project(32, -14, 6),
      pElbowR,
      project(46, 16, rightArmZ - 6),
    ], kurtaLight);

    drawPolygon([
      pElbowR,
      project(40, 20, rightArmZ),
      pHandR,
      project(48, 50, rightArmZ * 1.3),
    ], skinLight);

    // 5. NECK & HEAD
    final pChin = project(0, -48 + headNod, 16);
    final pForehead = project(0, -84 + headNod, 14);
    final pTempleL = project(-20, -78 + headNod, 8);
    final pTempleR = project(20, -78 + headNod, 8);
    final pJawL = project(-18, -54 + headNod, 10);
    final pJawR = project(18, -54 + headNod, 10);

    // Neck
    drawPolygon([
      project(-10, -36, 4),
      project(10, -36, 4),
      pChin,
      project(0, -44, 8),
    ], skinDark);

    // Face Facets
    drawPolygon([pChin, pJawL, pTempleL, pForehead], skinMid);
    drawPolygon([pChin, pForehead, pTempleR, pJawR], skinLight);

    // Eyes (Low-poly stylized glasses / brow)
    final pEyeL = project(-8, -72 + headNod, 16);
    final pEyeR = project(8, -72 + headNod, 16);
    canvas.drawLine(
      Offset(pEyeL.dx - 4, pEyeL.dy),
      Offset(pEyeL.dx + 4, pEyeL.dy),
      Paint()..color = const Color(0xFF0F172A)..strokeWidth = 2.0,
    );
    canvas.drawLine(
      Offset(pEyeR.dx - 4, pEyeR.dy),
      Offset(pEyeR.dx + 4, pEyeR.dy),
      Paint()..color = const Color(0xFF0F172A)..strokeWidth = 2.0,
    );

    // Indian gentleman mustache (Ramesh Patel lowpoly feature)
    final pMouthCenter = project(0, -56 + headNod, 18);
    drawPolygon([
      project(-10, -60 + headNod, 17),
      project(10, -60 + headNod, 17),
      pMouthCenter,
      project(0, -58 + headNod, 19),
    ], hairSilver);

    // Mouth / Talking lip sync
    if (mouthOpen > 1.5) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pMouthCenter.dx, pMouthCenter.dy + 3),
          width: 8.0,
          height: mouthOpen,
        ),
        Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.fill,
      );
    }

    // Hair / Cap (Silver/Grey lowpoly hair)
    final pTopHead = project(0, -96 + headNod, 0);
    drawPolygon([pForehead, pTempleL, project(-14, -92, 4), pTopHead], hairSilver);
    drawPolygon([pForehead, pTopHead, project(14, -92, 4), pTempleR], hairSilver.withValues(alpha: 0.9));

    // 6. ORGAN HEALTH SENSORS OVERLAY (Embedded in 3D Body)
    final glowPaint = Paint()..style = PaintingStyle.fill;
    final pulseScale = 1.0 + (math.sin(animProgress * math.pi * 4) * 0.15);

    // Heart (Cardiovascular node)
    final pHeart = project(-10, 4, 14);
    final isHeartActive = selectedOrgan == 'cardiovascular';
    glowPaint.color = isHeartActive ? const Color(0xFFEF4444) : const Color(0xFFEF4444).withValues(alpha: 0.6);
    canvas.drawCircle(pHeart, (isHeartActive ? 9 : 6) * pulseScale, glowPaint);
    canvas.drawCircle(
      pHeart,
      (isHeartActive ? 14 : 9) * pulseScale,
      Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Brain (Neurological node)
    final pBrain = project(0, -82 + headNod, 10);
    final isBrainActive = selectedOrgan == 'neurological';
    glowPaint.color = isBrainActive ? const Color(0xFF38BDF8) : const Color(0xFF38BDF8).withValues(alpha: 0.6);
    canvas.drawCircle(pBrain, (isBrainActive ? 8 : 5), glowPaint);

    // Pulmonary (Lungs)
    final pLungL = project(-18, 6, 8);
    final pLungR = project(18, 6, 8);
    final isLungActive = selectedOrgan == 'pulmonary';
    glowPaint.color = isLungActive ? const Color(0xFF06B6D4) : const Color(0xFF06B6D4).withValues(alpha: 0.4);
    canvas.drawOval(Rect.fromCenter(center: pLungL, width: 8, height: 14), glowPaint);
    canvas.drawOval(Rect.fromCenter(center: pLungR, width: 8, height: 14), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _LowpolyOldManMeshPainter oldDelegate) {
    return oldDelegate.rotationY != rotationY ||
        oldDelegate.animProgress != animProgress ||
        oldDelegate.activeAnimation != activeAnimation ||
        oldDelegate.isSpeaking != isSpeaking ||
        oldDelegate.selectedOrgan != selectedOrgan;
  }
}
