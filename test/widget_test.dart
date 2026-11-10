import 'package:codenect_project/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('login screen provides sign-in options and fields', (
    tester,
  ) async {
    setViewport(tester, const Size(800, 1000));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('PLAYER LOGIN'), findsNWidgets(2));
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('PRESS START'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign in validates email and password before authentication', (
    tester,
  ) async {
    setViewport(tester, const Size(800, 1000));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.tap(find.text('PRESS START'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player can switch to account creation and back', (tester) async {
    setViewport(tester, const Size(800, 1100));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.ensureVisible(find.text('New player? Create account'));
    await tester.tap(find.text('New player? Create account'));
    await tester.pumpAndSettle();

    expect(find.text('NEW PLAYER'), findsNWidgets(2));
    expect(find.text('PLAYER NAME'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));

    await tester.ensureVisible(find.text('Already a player? Sign in'));
    await tester.tap(find.text('Already a player? Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('PLAYER LOGIN'), findsNWidgets(2));
  });

  testWidgets('account creation validates required fields', (tester) async {
    setViewport(tester, const Size(800, 1100));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.ensureVisible(find.text('New player? Create account'));
    await tester.tap(find.text('New player? Create account'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a player name.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(find.text('Confirm your password.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    setViewport(tester, const Size(800, 1000));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    final editablePassword = find.descendant(
      of: find.byKey(const ValueKey('login-password')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editablePassword).obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(tester.widget<EditableText>(editablePassword).obscureText, isFalse);
  });

  testWidgets('wide layout renders without overflow', (tester) async {
    setViewport(tester, const Size(1280, 720));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('PLAYER LOGIN'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('left-panel-artwork')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/left-panel_loginpart.png',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop registration form remains scrollable', (tester) async {
    setViewport(tester, const Size(1280, 720));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.ensureVisible(find.text('New player? Create account'));
    await tester.tap(find.text('New player? Create account'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('short landscape window uses the scrollable stacked layout', (
    tester,
  ) async {
    setViewport(tester, const Size(1280, 540));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('PLAYER LOGIN'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone landscape uses a compact side-by-side login layout', (
    tester,
  ) async {
    setViewport(tester, const Size(844, 390));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(
      find.byKey(const ValueKey('mobile-landscape-brand')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/left-panel_loginpart.png',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('landscape-form-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone landscape registration form stays scrollable', (
    tester,
  ) async {
    setViewport(tester, const Size(844, 390));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.ensureVisible(find.text('New player? Create account'));
    await tester.tap(find.text('New player? Create account'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create-email')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create-confirm-password')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
