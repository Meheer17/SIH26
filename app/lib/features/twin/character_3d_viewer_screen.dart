import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'local_3d_server.dart';
import 'lowpoly_mesh_avatar.dart';

/// Full-screen interactive 3D Character Controller for the rigged GLB model
class Character3DViewerScreen extends StatefulWidget {
  final String modelPath;
  final String title;

  const Character3DViewerScreen({
    super.key,
    this.modelPath = 'assets/lowpoly_old_man.glb',
    this.title = '3D Patient Twin Character Controller',
  });

  @override
  State<Character3DViewerScreen> createState() => _Character3DViewerScreenState();
}

class _Character3DViewerScreenState extends State<Character3DViewerScreen> {
  // Available animations in the GLB file: 'talking' (default) and 'walking'
  String _activeAnimation = 'talking';
  bool _isPlaying = true;
  bool _autoRotate = false;

  bool get _isEmbeddedGlbSupported {
    if (kIsWeb) return true;
    try {
      return WebViewPlatform.instance != null;
    } catch (_) {
      return false;
    }
  }

  void _switchAnimation(String animName) {
    setState(() {
      _activeAnimation = animName;
      _isPlaying = true;
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleAutoRotate() {
    setState(() {
      _autoRotate = !_autoRotate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Launch WebGL 3D Studio (Browser)',
            icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF38BDF8)),
            onPressed: () => Local3dStudioServer.instance.launchInBrowser(),
          ),
          IconButton(
            tooltip: _autoRotate ? 'Disable Auto-Rotate' : 'Enable Auto-Rotate',
            icon: Icon(
              Icons.rotate_right_rounded,
              color: _autoRotate ? const Color(0xFF38BDF8) : Colors.white70,
            ),
            onPressed: _toggleAutoRotate,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isPlaying ? Icons.play_circle_fill : Icons.pause_circle_filled,
                        color: _isPlaying ? const Color(0xFF4ADE80) : const Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ACTION: ${_activeAnimation.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isPlaying
                          ? const Color(0xFF059669).withValues(alpha: 0.25)
                          : const Color(0xFFD97706).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isPlaying ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _isPlaying ? 'Playing • 60 FPS' : 'Paused',
                      style: TextStyle(
                        color: _isPlaying ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3D Model Viewport
            Expanded(
              child: Container(
                color: const Color(0xFF0B0F19),
                child: _isEmbeddedGlbSupported
                    ? ModelViewer(
                        key: ValueKey('${widget.modelPath}-$_activeAnimation-$_isPlaying-$_autoRotate'),
                        src: widget.modelPath,
                        alt: '3D Lowpoly Rigged Patient Character',
                        ar: true,
                        autoRotate: _autoRotate,
                        cameraControls: true,
                        backgroundColor: const Color(0xFF0B0F19),
                        animationName: _isPlaying ? _activeAnimation : null,
                        autoPlay: _isPlaying,
                        shadowIntensity: 1.0,
                        shadowSoftness: 0.8,
                        exposure: 1.2,
                      )
                    : LowpolyMeshAvatar(
                        activeAnimation: _activeAnimation,
                        isPlaying: _isPlaying,
                        autoRotate: _autoRotate,
                        showControlsOverlay: true,
                        onToggleWalk: () => _switchAnimation('walking'),
                        onToggleTalk: () => _switchAnimation('talking'),
                      ),
              ),
            ),

            // Model Information Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GLB Asset: ${widget.modelPath} • Skeletal Rigging • ARKit Visemes',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Control Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Walk Button
                  _buildActionButton(
                    label: 'Walk',
                    icon: Icons.directions_walk_rounded,
                    isSelected: _activeAnimation == 'walking' && _isPlaying,
                    onTap: () => _switchAnimation('walking'),
                  ),

                  // Talk Button
                  _buildActionButton(
                    label: 'Talk',
                    icon: Icons.record_voice_over_rounded,
                    isSelected: _activeAnimation == 'talking' && _isPlaying,
                    onTap: () => _switchAnimation('talking'),
                  ),

                  // Play / Pause Button
                  _buildActionButton(
                    label: _isPlaying ? 'Pause' : 'Play',
                    icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    isSelected: false,
                    onTap: _togglePlayPause,
                  ),

                  // Auto Rotate Button
                  _buildActionButton(
                    label: _autoRotate ? 'Rotating' : 'Orbit',
                    icon: Icons.threed_rotation_rounded,
                    isSelected: _autoRotate,
                    onTap: _toggleAutoRotate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF0284C7) : const Color(0xFF334155),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: Color(0xFF38BDF8), width: 1.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}
