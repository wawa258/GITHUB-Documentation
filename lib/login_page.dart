import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'auth_database.dart';

const _background = Color(0xFF0D0620);
const _panel = Color(0xFF1A0F3D);
const _purple = Color(0xFF8F6BFF);
const _lavender = Color(0xFFC9B3FF);
const _yellow = Color(0xFFFFC933);
const _loginArtwork = 'assets/images/codenect-login-screen (1).svg';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthDatabase.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AuthStatusPage(
            message:
                'Could not check your sign-in status. Please restart the app.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _background,
            body: Center(child: CircularProgressIndicator(color: _yellow)),
          );
        }
        final user = snapshot.data;
        return user == null ? const LoginPage() : _SignedInPage(user: user);
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _creatingAccount = false;
  bool _obscurePassword = true;
  bool _isBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    try {
      final authDatabase = AuthDatabase.instance;
      if (_creatingAccount) {
        await authDatabase.createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          playerName: _nameController.text,
        );
      } else {
        await authDatabase.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage('Could not sign in: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Enter your email address first.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      await AuthDatabase.instance.sendPasswordResetEmail(email);
      _showMessage('Password reset email sent to $email.');
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage('Could not send the reset email: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signInWithProvider(AuthProvider provider) async {
    setState(() => _isBusy = true);
    try {
      await AuthDatabase.instance.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage('Could not sign in with this provider: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'The email or password is incorrect.',
      'email-already-in-use' => 'An account already exists for this email.',
      'weak-password' => 'Choose a stronger password (at least 6 characters).',
      'operation-not-allowed' =>
        'This sign-in method is not enabled in Firebase Authentication.',
      'account-exists-with-different-credential' =>
        'This email is already linked to another sign-in method.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'popup-closed-by-user' ||
      'web-context-cancelled' => 'Sign-in was cancelled.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (isWide)
                SvgPicture.asset(
                  _loginArtwork,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                )
              else
                const _MobileBackdrop(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, safeConstraints) {
                    final cardWidth = isWide
                        ? safeConstraints.maxWidth * 0.428
                        : safeConstraints.maxWidth - 32;
                    return Align(
                      alignment: isWide
                          ? Alignment.centerRight
                          : Alignment.center,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide
                              ? safeConstraints.maxWidth * 0.056
                              : 16,
                          vertical: 24,
                        ),
                        child: SizedBox(
                          width: cardWidth,
                          child: _buildCard(isWide: isWide),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard({required bool isWide}) {
    return Container(
      padding: EdgeInsets.all(isWide ? 32 : 24),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _purple, width: 2),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isWide) ...[
              const Text(
                'CODENECT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _yellow,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              _creatingAccount ? 'NEW PLAYER' : 'PLAYER LOGIN',
              style: const TextStyle(
                color: _yellow,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _creatingAccount
                  ? 'Create your account and join the team.'
                  : 'Welcome back. Your team is waiting.',
              style: const TextStyle(color: Color(0xFFD9CDFC), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    label: 'Google',
                    mark: 'G',
                    onPressed: _isBusy
                        ? null
                        : () => _signInWithProvider(GoogleAuthProvider()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    label: 'Facebook',
                    mark: 'f',
                    onPressed: _isBusy
                        ? null
                        : () => _signInWithProvider(FacebookAuthProvider()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: Divider(color: _purple)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or use player ID',
                    style: TextStyle(color: _lavender, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: _purple)),
              ],
            ),
            const SizedBox(height: 18),
            if (_creatingAccount) ...[
              _buildLabel('PLAYER NAME'),
              const SizedBox(height: 7),
              _buildTextField(
                controller: _nameController,
                hint: 'Your player name',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
            ],
            _buildLabel('EMAIL'),
            const SizedBox(height: 7),
            _buildTextField(
              controller: _emailController,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildLabel('PASSWORD'),
            const SizedBox(height: 7),
            _buildTextField(
              controller: _passwordController,
              hint: 'Enter password',
              obscureText: _obscurePassword,
              textInputAction: _creatingAccount
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: _creatingAccount ? null : (_) => _submit(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: _lavender,
                ),
              ),
              validator: (value) {
                if ((value ?? '').length < 6) {
                  return 'Use at least 6 characters.';
                }
                return null;
              },
            ),
            if (_creatingAccount) ...[
              const SizedBox(height: 14),
              _buildLabel('CONFIRM PASSWORD'),
              const SizedBox(height: 7),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Re-enter password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isBusy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _yellow,
                  foregroundColor: const Color(0xFF2A1608),
                  disabledBackgroundColor: _yellow.withValues(alpha: 0.5),
                  shape: const RoundedRectangleBorder(),
                  elevation: 4,
                ),
                child: _isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2A1608),
                        ),
                      )
                    : Text(
                        _creatingAccount ? 'CREATE ACCOUNT' : 'PRESS START',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            if (!_creatingAccount)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isBusy ? null : _sendPasswordReset,
                  style: TextButton.styleFrom(foregroundColor: _lavender),
                  child: const Text('Forgot password?'),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isBusy
                    ? null
                    : () {
                        setState(() {
                          _creatingAccount = !_creatingAccount;
                          _formKey.currentState?.reset();
                        });
                      },
                style: TextButton.styleFrom(foregroundColor: _yellow),
                child: Text(
                  _creatingAccount
                      ? 'Already a player? Sign in'
                      : 'New player? Create account',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _yellow,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8D7FC4), fontSize: 14),
        filled: true,
        fillColor: _background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        suffixIcon: suffixIcon,
        errorMaxLines: 2,
        errorStyle: const TextStyle(height: 1.1),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _purple, width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _yellow, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.zero,
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.mark,
    required this.onPressed,
  });

  final String label;
  final String mark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: _purple),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: const RoundedRectangleBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            mark,
            style: TextStyle(
              color: label == 'Google' ? _yellow : const Color(0xFF70A7FF),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBackdrop extends StatelessWidget {
  const _MobileBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_background, Color(0xFF21134A), _background],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _SignedInPage extends StatelessWidget {
  const _SignedInPage({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final email = user.email ?? 'Signed in with a linked account';
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _panel,
              border: Border.all(color: _purple, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports, color: _yellow, size: 52),
                const SizedBox(height: 16),
                const Text(
                  'YOU’RE IN!',
                  style: TextStyle(
                    color: _yellow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome${user.displayName == null ? '' : ', ${user.displayName}'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _lavender),
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
                            content: Text(
                              error.message ?? 'Could not sign out.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: const Color(0xFF2A1608),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('SIGN OUT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthStatusPage extends StatelessWidget {
  const _AuthStatusPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
