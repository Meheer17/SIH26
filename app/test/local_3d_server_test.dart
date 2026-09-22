import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/twin/local_3d_server.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Local3dStudioServer starts, serves studio HTML and GLB, and stops', () async {
    final url = await Local3dStudioServer.instance.start();
    expect(url, startsWith('http://127.0.0.1:'));
    expect(Local3dStudioServer.instance.isRunning, isTrue);

    // Test GET /
    final resHtml = await http.get(Uri.parse(url));
    expect(resHtml.statusCode, HttpStatus.ok);
    expect(resHtml.headers['content-type'], contains('text/html'));
    expect(resHtml.body, contains('model-viewer'));

    // Test GET /lowpoly_old_man.glb
    final resGlb = await http.get(Uri.parse('$url/lowpoly_old_man.glb'));
    expect(resGlb.statusCode, HttpStatus.ok);
    expect(resGlb.headers['content-type'], equals('model/gltf-binary'));
    expect(resGlb.bodyBytes.length, greaterThan(1000000)); // ~3.4MB

    await Local3dStudioServer.instance.stop();
    expect(Local3dStudioServer.instance.isRunning, isFalse);
  });
}
