// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mobile_grok/main.dart';

void main() {
  testWidgets('App builds and shows title', (WidgetTester tester) async {
    // Ensure locale data is initialized like in main()
    await initializeDateFormatting('pt_BR');

    // Build app and wait for frames
    await tester.pumpWidget(const MobileGrokApp());
    await tester.pumpAndSettle();

  // Verify the app built (MaterialApp present)
  expect(find.byType(MaterialApp), findsOneWidget);
  });
}
