import 'package:codenect_project/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login screen shows the sign-in options', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('PLAYER LOGIN'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('PRESS START'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('desktop login screen loads its SVG artwork', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('PLAYER LOGIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player can switch to account creation', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.ensureVisible(find.text('New player? Create account'));
    await tester.tap(find.text('New player? Create account'));
    await tester.pumpAndSettle();

    expect(find.text('NEW PLAYER'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('sign in validates required fields', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.tap(find.text('PRESS START'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    final passwordField = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byType(TextFormField).last,
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isFalse,
    );
  });
}
