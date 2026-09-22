import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

/// Lightweight local HTTP server for rendering the GLB 3D Studio in WebGL
/// on platforms where embedded webview is unavailable (Linux desktop) or for
/// launching high-performance 3D studio in Firefox/Chrome.
class Local3dStudioServer {
  static final Local3dStudioServer instance = Local3dStudioServer._();
  Local3dStudioServer._();

  HttpServer? _server;
  int? _port;
  bool _isStarting = false;

  int? get port => _port;
  bool get isRunning => _server != null;
  String get studioUrl => _port != null ? 'http://127.0.0.1:$_port' : '';

  /// Ensure server is started and return the studio URL
  Future<String> start() async {
    if (_server != null) {
      return studioUrl;
    }
    if (_isStarting) {
      while (_isStarting) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return studioUrl;
    }

    _isStarting = true;
    try {
      // Bind to localhost on port 8765, or 0 (ephemeral) if occupied
      try {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8765);
      } catch (_) {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      }

      _port = _server!.port;
      debugPrint('[Local3dStudioServer] Started on port $_port: $studioUrl');

      _server!.listen(_handleRequest, onError: (e) {
        debugPrint('[Local3dStudioServer] Server error: $e');
      });

      return studioUrl;
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    // CORS & cache control headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      if (path == '/' || path == '/index.html' || path == '/3d_studio.html') {
        // Serve HTML Studio
        String htmlContent;
        final htmlFile = File('web/3d_studio.html');
        if (await htmlFile.exists()) {
          htmlContent = await htmlFile.readAsString();
        } else {
          try {
            htmlContent = await rootBundle.loadString('web/3d_studio.html');
          } catch (_) {
            htmlContent = _defaultStudioHtml;
          }
        }

        request.response.headers.contentType = ContentType.html;
        request.response.write(htmlContent);
      } else if (path.endsWith('.glb')) {
        // Serve GLB Model
        List<int>? bytes;
        final directPaths = [
          'assets/lowpoly_old_man.glb',
          'models/lowpoly_old_man.glb',
          '../models/lowpoly_old_man.glb',
        ];

        for (final p in directPaths) {
          final f = File(p);
          if (await f.exists()) {
            bytes = await f.readAsBytes();
            break;
          }
        }

        if (bytes == null) {
          try {
            final byteData = await rootBundle.load('assets/lowpoly_old_man.glb');
            bytes = byteData.buffer.asUint8List();
          } catch (e) {
            debugPrint('[Local3dStudioServer] Could not load GLB from rootBundle: $e');
          }
        }

        if (bytes != null) {
          request.response.headers.set('Content-Type', 'model/gltf-binary');
          request.response.headers.set('Content-Length', bytes.length.toString());
          request.response.add(bytes);
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('GLB Model not found');
        }
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not found: $path');
      }
    } catch (e) {
      debugPrint('[Local3dStudioServer] Request error: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Server Error: $e');
    } finally {
      await request.response.close();
    }
  }

  /// Launch the 3D studio in the default system browser (Firefox/Chrome)
  Future<bool> launchInBrowser() async {
    final url = await start();
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}

    // Fallback on Linux to xdg-open or firefox
    if (!kIsWeb && Platform.isLinux) {
      try {
        final result = await Process.run('xdg-open', [url]);
        if (result.exitCode == 0) return true;
      } catch (_) {}
      try {
        final result = await Process.run('firefox', [url]);
        if (result.exitCode == 0) return true;
      } catch (_) {}
    }

    return false;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
  }

  static const String _defaultStudioHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>SvasthyaSetu 3D Patient Twin</title>
  <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js"></script>
  <style>
    body { margin: 0; background: #0f172a; color: #fff; font-family: sans-serif; height: 100vh; display: flex; flex-direction: column; }
    model-viewer { flex: 1; width: 100%; }
    .bar { padding: 12px; background: #1e293b; display: flex; justify-content: center; gap: 10px; }
    button { background: #0284c7; color: #fff; border: 0; padding: 8px 16px; border-radius: 6px; cursor: pointer; }
  </style>
</head>
<body>
  <div class="bar">
    <button onclick="document.getElementById('mv').animationName='talking';document.getElementById('mv').play();">Talk</button>
    <button onclick="document.getElementById('mv').animationName='walking';document.getElementById('mv').play();">Walk</button>
    <button onclick="document.getElementById('mv').paused ? document.getElementById('mv').play() : document.getElementById('mv').pause();">Play/Pause</button>
  </div>
  <model-viewer id="mv" src="/lowpoly_old_man.glb" auto-rotate camera-controls autoplay animation-name="talking"></model-viewer>
</body>
</html>
''';
}
