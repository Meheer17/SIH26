import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/twin/character_3d_viewer_screen.dart';
import 'package:app/features/twin/digital_twin_screen.dart';

void main() {
  testWidgets('Character3DViewerScreen renders correctly with controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Character3DViewerScreen(),
      ),
    );

    // Verify Action status
    expect(find.text('ACTION: TALKING'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Talk'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    // Tap Walk button
    await tester.tap(find.text('Walk'));
    await tester.pump();
    expect(find.text('ACTION: WALKING'), findsOneWidget);
  });

  testWidgets('DigitalTwinScreen renders with 3D viewport controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DigitalTwinScreen(),
      ),
    );

    expect(find.byType(DigitalTwinScreen), findsOneWidget);
  });
}
