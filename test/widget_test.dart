import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mylife/app.dart';

void main() {
  testWidgets('shows the Set PIN screen on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyLifeApp());
    await tester.pumpAndSettle();

    expect(find.text('Set PIN for MyLife'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('entering a 4-digit PIN moves to the confirm step', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyLifeApp());
    await tester.pumpAndSettle();

    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Confirm PIN'), findsOneWidget);
    expect(find.text('Set PIN for MyLife'), findsNothing);
  });
}
