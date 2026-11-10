import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_database.dart';

// ----------------------------- Palette -------------------------------------
class C {
  static const ink = Color(0xFF0D0620);
  static const deep = Color(0xFF1A0F3D);
  static const panel = Color(0xFF24145C);
  static const violet = Color(0xFF8F6BFF);
  static const violetDark = Color(0xFF5A38C4);
  static const violetLight = Color(0xFFCDBBFF);
  static const btnBg = Color(0xFF150B34);
  static const gold = Color(0xFFFFC933);
  static const goldLight = Color(0xFFFFF0A8);
  static const goldDark = Color(0xFFD98E04);
  static const pink = Color(0xFFFF5FB0);
  static const text = Color(0xFFD9CDFC);
  static const muted = Color(0xFFC9B3FF);
  static const hint = Color(0xFF8D7FC4);
  static const xpEmpty = Color(0xFF2A1668);
}

TextStyle pixel(double size, Color color, {double spacing = 0}) =>
    GoogleFonts.pressStart2p(
      fontSize: size,
      color: color,
      letterSpacing: spacing,
      height: 1.2,
    );

TextStyle inter(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w400,
  double spacing = 0,
}) => GoogleFonts.inter(
  fontSize: size,
  color: color,
  fontWeight: weight,
  letterSpacing: spacing,
);

// ----------------------------- Screen --------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _playerName = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _creatingAccount = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _playerName.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      if (_creatingAccount) {
        await AuthDatabase.instance.createAccount(
          email: _email.text.trim(),
          password: _password.text,
          playerName: _playerName.text.trim(),
        );
      } else {
        await AuthDatabase.instance.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage(
        'Unable to ${_creatingAccount ? 'create your account' : 'sign in'}: $error',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithProvider(AuthProvider provider) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AuthDatabase.instance.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage('Unable to sign in with this provider: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final validationError = _validateEmail(_email.text);
    if (validationError != null) {
      _showMessage('Enter a valid email address to reset your password.');
      return;
    }
    try {
      await AuthDatabase.instance.sendPasswordResetEmail(_email.text.trim());
      _showMessage('Password reset email sent.');
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage('Unable to send password reset email: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'The email or password is incorrect.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'popup-closed-by-user':
        return 'The sign-in window was closed before completing sign-in.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Background(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final desktopWide = c.maxWidth >= 960 && c.maxHeight >= 640;
                final landscape = c.maxWidth >= 600 && c.maxWidth > c.maxHeight;
                final horizontalLayout = desktopWide || landscape;
                final compactLandscape = landscape && !desktopWide;
                final card = _LoginCard(
                  formKey: _formKey,
                  playerName: _playerName,
                  email: _email,
                  password: _password,
                  confirmPassword: _confirmPassword,
                  creatingAccount: _creatingAccount,
                  busy: _busy,
                  compact: compactLandscape,
                  onSubmit: _submit,
                  onGoogle: () => _signInWithProvider(GoogleAuthProvider()),
                  onFacebook: () => _signInWithProvider(FacebookAuthProvider()),
                  onForgotPassword: _resetPassword,
                  onToggleMode: () {
                    setState(() {
                      _creatingAccount = !_creatingAccount;
                      _formKey.currentState?.reset();
                    });
                  },
                );
                if (horizontalLayout) {
                  return SingleChildScrollView(
                    child: SizedBox(
                      height: c.maxHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: compactLandscape ? 3 : 5,
                            child: Padding(
                              padding: compactLandscape
                                  ? const EdgeInsets.all(8)
                                  : const EdgeInsets.fromLTRB(72, 56, 24, 40),
                              child: compactLandscape
                                  ? const _LandscapeBrandPanel()
                                  : const _BrandPanel(),
                            ),
                          ),
                          Expanded(
                            flex: compactLandscape ? 7 : 6,
                            child: SingleChildScrollView(
                              key: compactLandscape
                                  ? const ValueKey('landscape-form-scroll')
                                  : null,
                              padding: EdgeInsets.all(
                                compactLandscape ? 10 : 32,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: compactLandscape ? 620 : 556,
                                  ),
                                  child: card,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 556),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _BrandPanel(compact: true),
                          const SizedBox(height: 32),
                          card,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------- Background ----------------------------------
class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/login_bg.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D0620), Color(0xFF2A1668)],
              ),
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [0, 0.45, 1],
              colors: [
                Color(0xE00D0620), // .88
                Color(0xB81A0F3D), // .72
                Color(0x8C1A0F3D), // .55
              ],
            ),
          ),
        ),
        CustomPaint(painter: _GridPainter()),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = C.violet.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ----------------------------- Brand panel ---------------------------------
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => _LeftPanelArtwork(
    compact: compact,
    key: const ValueKey('left-panel-artwork'),
  );
}

class _LandscapeBrandPanel extends StatelessWidget {
  const _LandscapeBrandPanel();

  @override
  Widget build(BuildContext context) =>
      _LeftPanelArtwork(key: const ValueKey('mobile-landscape-brand'));
}

class _LeftPanelArtwork extends StatelessWidget {
  const _LeftPanelArtwork({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final artwork = Image.asset(
      'assets/images/left-panel_loginpart.png',
      fit: BoxFit.contain,
      semanticLabel: 'Codenect logo, gamepad, tagline, and XP bar',
    );
    if (compact) {
      return SizedBox(height: 220, child: Center(child: artwork));
    }
    return Center(child: artwork);
  }
}

/// "CODENECT" in pixel font with a stacked 3D extrusion and gradient faces.
class PixelWordmark extends StatelessWidget {
  const PixelWordmark({super.key, this.size = 40});
  final double size;

  static const _warm = [
    Color(0xFFFFF1B8),
    Color(0xFFFFC233),
    Color(0xFFEE7A2A),
    Color(0xFFA8301F),
  ];
  static const _green = [
    Color(0xFFF4FFD2),
    Color(0xFF8FD43A),
    Color(0xFF4C9A2A),
    Color(0xFF245A17),
  ];

  Widget _row(Color? flat) {
    Widget word(String t, List<Color> g) {
      final text = Text(t, style: pixel(size, flat ?? Colors.white));
      if (flat != null) return text;
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (b) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: g,
        ).createShader(b),
        child: text,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [word('CODE', _warm), word('NECT', _green)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = size / 20; // extrusion unit
    final layers = <Widget>[
      Transform.translate(offset: Offset(u * 1.8, u * 1.8), child: _row(C.ink)),
    ];
    for (int i = 6; i >= 1; i--) {
      layers.add(
        Transform.translate(
          offset: Offset(u * i * 0.5, u * i * 0.5),
          child: _row(i.isEven ? C.xpEmpty : const Color(0xFF4B2A9C)),
        ),
      );
    }
    layers.add(_row(null));
    return Stack(clipBehavior: Clip.none, children: layers);
  }
}

/// Pixel-art gamepad icon.
class PixelGamepad extends StatelessWidget {
  const PixelGamepad({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(154, 91), painter: _GamepadPainter());
}

class _GamepadPainter extends CustomPainter {
  const _GamepadPainter();

  void _r(Canvas c, double x, double y, double w, double h, Color col) =>
      c.drawRect(Rect.fromLTWH(x, y, w, h), Paint()..color = col);

  @override
  void paint(Canvas c, Size s) {
    // Outline (inflated body + grips)
    const o = 5.0;
    void body(Color col, double inset) {
      _r(c, 7 + inset, 7 + inset, 140 - inset * 2, 56 - inset * 2, col);
      _r(c, 0 + inset, 42 + inset, 42 - inset * 2, 49 - inset * 2, col);
      _r(c, 112 + inset, 42 + inset, 42 - inset * 2, 49 - inset * 2, col);
    }

    // drop shadow
    c.save();
    c.translate(7, 7);
    body(C.ink.withValues(alpha: 0.6), -o);
    c.restore();
    body(C.ink, -o);
    body(C.violet, 0);
    // highlight / shade strips
    _r(c, 7, 7, 140, 7, C.violetLight);
    _r(c, 0, 49, 7, 35, C.violetLight);
    _r(c, 7, 56, 140, 7, C.violetDark);
    _r(c, 0, 84, 42, 7, C.violetDark);
    _r(c, 112, 84, 42, 7, C.violetDark);

    // D-pad
    _r(c, 28, 28, 7, 28, C.ink);
    _r(c, 21, 35, 21, 14, C.ink);
    _r(c, 22, 29, 5, 26, Colors.white);
    _r(c, 15, 36, 18, 5, Colors.white);
    _r(c, 22, 29, 5, 26, Colors.white);

    // Buttons
    _r(c, 95, 25, 14, 14, C.gold);
    _r(c, 95, 25, 14, 7, C.goldLight);
    _r(c, 109, 46, 14, 14, C.pink);
    _r(c, 109, 46, 14, 7, const Color(0xFFFFD6EC));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.filled, required this.total});
  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('XP', style: pixel(11, C.gold)),
        const SizedBox(height: 10),
        Container(
          width: 360,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: C.ink,
            border: Border.all(color: C.violet, width: 4),
            boxShadow: const [
              BoxShadow(color: C.ink, offset: Offset(4, 4), blurRadius: 0),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: List.generate(total, (i) {
                final on = i < filled;
                return Expanded(
                  child: Container(
                    height: 12,
                    margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                    child: on
                        ? Column(
                            children: [
                              Expanded(child: Container(color: C.goldLight)),
                              Expanded(child: Container(color: C.gold)),
                              Expanded(child: Container(color: C.goldDark)),
                            ],
                          )
                        : Container(color: C.xpEmpty),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------- Login card ----------------------------------
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.playerName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.creatingAccount,
    required this.busy,
    required this.compact,
    required this.onSubmit,
    required this.onGoogle,
    required this.onFacebook,
    required this.onForgotPassword,
    required this.onToggleMode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController playerName;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool creatingAccount;
  final bool busy;
  final bool compact;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final VoidCallback onForgotPassword;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // glow
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: C.violet.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(compact ? 14 : 40),
          decoration: BoxDecoration(
            color: C.panel.withValues(alpha: 0.94),
            border: Border.all(color: C.violet, width: 4),
            boxShadow: const [
              BoxShadow(color: C.ink, offset: Offset(10, 10), blurRadius: 0),
            ],
          ),
          child: Form(
            key: formKey,
            child: LayoutBuilder(
              builder: (context, c) {
                final twoCols = c.maxWidth >= (compact ? 400 : 440);
                final title = creatingAccount ? 'NEW PLAYER' : 'PLAYER LOGIN';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Stack(
                      children: [
                        Transform.translate(
                          offset: const Offset(3, 3),
                          child: Text(
                            title,
                            style: pixel(compact ? 16 : 24, C.ink, spacing: 1),
                          ),
                        ),
                        Text(
                          title,
                          style: pixel(compact ? 16 : 24, C.gold, spacing: 1),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 18),
                    Text(
                      creatingAccount
                          ? 'Create your player account to join the team.'
                          : 'Welcome back. Your team is waiting.',
                      style: inter(compact ? 12 : 15, C.text),
                    ),
                    SizedBox(height: compact ? 10 : 26),

                    // Social buttons
                    _responsiveRow(
                      twoCols,
                      SocialButton(
                        label: 'Google',
                        icon: _GoogleG(size: compact ? 18 : 22),
                        onPressed: onGoogle,
                        enabled: !busy,
                        height: compact ? 40 : 52,
                      ),
                      SocialButton(
                        label: 'Facebook',
                        icon: _FacebookF(size: compact ? 18 : 22),
                        onPressed: onFacebook,
                        enabled: !busy,
                        height: compact ? 40 : 52,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(height: 3, color: C.violetDark),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 8 : 14,
                          ),
                          child: Text(
                            'or use player ID',
                            style: inter(compact ? 10 : 13, C.muted),
                          ),
                        ),
                        Expanded(
                          child: Container(height: 3, color: C.violetDark),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 10 : 24),

                    if (creatingAccount) ...[
                      _responsiveRow(
                        twoCols,
                        PixelField(
                          label: 'PLAYER NAME',
                          hint: 'Your player name',
                          controller: playerName,
                          compact: compact,
                          validator: (value) => (value?.trim().isEmpty ?? true)
                              ? 'Enter a player name.'
                              : null,
                        ),
                        PixelField(
                          key: const ValueKey('create-email'),
                          label: 'EMAIL',
                          hint: 'you@example.com',
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          compact: compact,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 14),
                      _responsiveRow(
                        twoCols,
                        PixelField(
                          key: const ValueKey('create-password'),
                          label: 'PASSWORD',
                          hint: 'Create a password',
                          controller: password,
                          obscure: true,
                          validator: _validatePassword,
                          compact: compact,
                        ),
                        PixelField(
                          key: const ValueKey('create-confirm-password'),
                          label: 'CONFIRM PASSWORD',
                          hint: 'Enter password again',
                          controller: confirmPassword,
                          obscure: true,
                          compact: compact,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Confirm your password.';
                            }
                            return value != password.text
                                ? 'Passwords do not match.'
                                : null;
                          },
                        ),
                      ),
                    ] else
                      _responsiveRow(
                        twoCols,
                        PixelField(
                          key: const ValueKey('login-email'),
                          label: 'EMAIL',
                          hint: 'you@example.com',
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          compact: compact,
                        ),
                        PixelField(
                          key: const ValueKey('login-password'),
                          label: 'PASSWORD',
                          hint: 'Enter password',
                          controller: password,
                          obscure: true,
                          validator: _validatePassword,
                          compact: compact,
                        ),
                      ),
                    SizedBox(height: compact ? 8 : 30),

                    PressStartButton(
                      onPressed: onSubmit,
                      label: creatingAccount ? 'CREATE ACCOUNT' : 'PRESS START',
                      semanticLabel: creatingAccount
                          ? 'Create account'
                          : 'Press start to sign in',
                      busy: busy,
                      compact: compact,
                    ),
                    SizedBox(height: compact ? 8 : 26),

                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: compact ? 6 : 10,
                      spacing: compact ? 8 : 16,
                      children: [
                        if (!creatingAccount)
                          InkWell(
                            onTap: busy ? null : onForgotPassword,
                            child: Text(
                              'Forgot password?',
                              style: inter(
                                compact ? 11 : 14,
                                C.muted,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: busy ? null : onToggleMode,
                          child: Text(
                            creatingAccount
                                ? 'Already a player? Sign in'
                                : 'New player? Create account',
                            style: inter(
                              compact ? 11 : 14,
                              C.gold,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Corner studs
        const Positioned(left: -9, top: -9, child: _Stud()),
        const Positioned(right: -9, top: -9, child: _Stud()),
        const Positioned(left: -9, bottom: -9, child: _Stud()),
        const Positioned(right: -9, bottom: -9, child: _Stud()),
      ],
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) return 'Use at least 6 characters.';
    return null;
  }

  Widget _responsiveRow(bool twoCols, Widget a, Widget b) {
    if (twoCols) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          SizedBox(width: compact ? 8 : 16),
          Expanded(child: b),
        ],
      );
    }
    return Column(
      children: [
        a,
        SizedBox(height: compact ? 8 : 14),
        b,
      ],
    );
  }
}

class _Stud extends StatelessWidget {
  const _Stud();

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    color: C.ink,
    padding: const EdgeInsets.all(3),
    child: Container(color: C.gold),
  );
}

// ----------------------------- Components ----------------------------------
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.height = 52,
  });
  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: C.btnBg,
          border: Border.all(color: C.violetDark, width: 3),
          boxShadow: const [
            BoxShadow(color: C.ink, offset: Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: inter(15, Colors.white, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class PixelField extends StatefulWidget {
  const PixelField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.compact = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool compact;

  @override
  State<PixelField> createState() => _PixelFieldState();
}

class _PixelFieldState extends State<PixelField> {
  late bool _hidden = widget.obscure;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: inter(
            widget.compact ? 10 : 12,
            C.gold,
            weight: FontWeight.w700,
            spacing: widget.compact ? 1 : 1.5,
          ),
        ),
        SizedBox(height: widget.compact ? 4 : 10),
        Container(
          constraints: BoxConstraints(minHeight: widget.compact ? 42 : 52),
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 14),
          decoration: BoxDecoration(
            color: C.ink,
            border: Border.all(
              color: _focus.hasFocus ? C.gold : C.violetDark,
              width: 3,
            ),
          ),
          alignment: Alignment.center,
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: _hidden,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            cursorColor: C.gold,
            style: inter(widget.compact ? 12 : 15, Colors.white),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: inter(widget.compact ? 12 : 15, C.hint),
              suffixIcon: widget.obscure
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _hidden = !_hidden),
                      child: Tooltip(
                        message: _hidden ? 'Show password' : 'Hide password',
                        child: Icon(
                          _hidden ? Icons.visibility : Icons.visibility_off,
                          size: 18,
                          color: C.hint,
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PressStartButton extends StatefulWidget {
  const PressStartButton({
    super.key,
    required this.onPressed,
    this.label = 'PRESS START',
    this.semanticLabel = 'Press start to sign in',
    this.busy = false,
    this.compact = false,
  });
  final VoidCallback onPressed;
  final String label;
  final String semanticLabel;
  final bool busy;
  final bool compact;

  @override
  State<PressStartButton> createState() => _PressStartButtonState();
}

class _PressStartButtonState extends State<PressStartButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 8.0;
    final height = widget.compact ? 54.0 : 72.0;
    final fontSize = widget.compact ? 13.0 : 18.0;
    return Semantics(
      button: true,
      enabled: !widget.busy,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: widget.busy ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: widget.busy
            ? null
            : (_) {
                setState(() => _down = false);
                widget.onPressed();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: double.infinity,
          height: height,
          margin: EdgeInsets.only(
            top: _down ? depth : 0,
            bottom: _down ? 0 : depth,
          ),
          decoration: BoxDecoration(
            color: C.gold,
            border: Border.all(color: C.ink, width: 4),
            boxShadow: _down
                ? []
                : const [
                    BoxShadow(
                      color: C.ink,
                      offset: Offset(0, depth),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // top highlight
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 5,
                child: Container(color: C.goldLight),
              ),
              // bottom shade
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 7,
                child: Container(color: C.goldDark),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: widget.busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF2A1608),
                          ),
                        )
                      : Text(
                          widget.label,
                          style: pixel(
                            fontSize,
                            const Color(0xFF2A1608),
                            spacing: widget.compact ? 1 : 2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------- Brand icons ---------------------------------
class _GoogleG extends StatelessWidget {
  const _GoogleG({this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleGPainter());
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final stroke = s.width * 0.22;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      s.width - stroke,
      s.height - stroke,
    );
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const pi = 3.1415926;
    canvas.drawArc(
      rect,
      -0.35 * pi,
      -0.65 * pi,
      false,
      p(const Color(0xFFEA4335)),
    );
    canvas.drawArc(
      rect,
      -pi * 1.0,
      -0.55 * pi,
      false,
      p(const Color(0xFFFBBC05)),
    );
    canvas.drawArc(
      rect,
      pi * 0.55,
      0.45 * pi,
      false,
      p(const Color(0xFF34A853)),
    );
    canvas.drawArc(
      rect,
      pi * 0.1,
      0.45 * pi,
      false,
      p(const Color(0xFF4285F4)),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        s.width * 0.5,
        s.height * 0.42,
        s.width * 0.47,
        stroke * 0.9,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FacebookF extends StatelessWidget {
  const _FacebookF({this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Color(0xFF1877F2),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.bottomCenter,
    child: Text(
      'f',
      style: GoogleFonts.inter(
        fontSize: size * 0.85,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.15,
      ),
    ),
  );
}

class LoginPage extends LoginScreen {
  const LoginPage({super.key});
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthDatabase.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: C.ink,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to check your sign-in status: ${snapshot.error}',
                  style: inter(16, Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: C.ink,
              body: Center(child: CircularProgressIndicator(color: C.violet)),
            );
          }
          return const LoginPage();
        }
        return _SignedInPage(user: snapshot.data!);
      },
    );
  }
}

class _SignedInPage extends StatelessWidget {
  const _SignedInPage({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final name = user.displayName;
    return Scaffold(
      backgroundColor: C.ink,
      appBar: AppBar(title: const Text('Codenect'), backgroundColor: C.deep),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelWordmark(size: 32),
              const SizedBox(height: 24),
              Text(
                name == null || name.isEmpty
                    ? 'Signed in as ${user.email ?? 'player'}'
                    : 'Welcome, $name!',
                style: inter(16, Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  try {
                    await AuthDatabase.instance.signOut();
                  } on FirebaseAuthException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.message ?? 'Unable to sign out.'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
