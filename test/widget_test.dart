// Widget tests for the login screen of the attendance app.
//
// These render LoginScreen directly (rather than the full app) so they don't
// depend on platform plugins like secure storage or the camera.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tubesapb/screens/login_screen.dart';

void main() {
  testWidgets('Login screen shows the core UI elements', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Sistem Presensi'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
    expect(find.text('Mahasiswa'), findsWidgets);
    expect(find.text('Dosen'), findsWidgets);
    // Email + password fields are present.
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('Submitting an empty form shows a validation message', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final loginButton = find.widgetWithText(FilledButton, 'Masuk');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump(); // build the SnackBar

    expect(find.text('Email dan password harus diisi.'), findsOneWidget);
  });
}
