// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tubesapb/main.dart';

void main() {
  testWidgets('Login opens dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Sistem Absensi Kampus'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);

    await tester.enterText(find.byWidgetPredicate((widget) {
      return widget is TextField && widget.decoration?.labelText == 'Email';
    }), 'admin@kampus.com');
    await tester.enterText(find.byWidgetPredicate((widget) {
      return widget is TextField && widget.decoration?.labelText == 'Kata Sandi';
    }), '123456');

    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Absensi'), findsOneWidget);
    expect(find.text('Ringkasan Hari Ini'), findsOneWidget);
  });
}
