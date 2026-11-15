import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';
import '../widgets/google_button.dart';
import 'role_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context
          .read<AuthService>()
          .login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const RoleRouter()));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      var r = await auth.loginWithGoogle();
      if (r == GoogleResult.needsRole) {
        // new account: ask whether customer or store owner
        if (!mounted) return;
        final role = await askGoogleRole(context);
        if (role == null) return;
        r = await auth.loginWithGoogle(role: role);
      }
      if (r == GoogleResult.signedIn && mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const RoleRouter()));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// There is no email-based password reset on the server yet, so be honest about it.
  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot password?'),
        content: const Text(
          'Password reset by email is not available yet. Please contact the AgriMamView administrator and they will help you get back into your account.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.light),
      focusedBorder: border(AppColors.primary, 1.8),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // wheat field background: soft blur + light cream overlay so the form stays readable
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
          child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFBF9EC).withOpacity(0.60),
                const Color(0xFFF6F4E2).withOpacity(0.72),
                const Color(0xFFEAF3DC).withOpacity(0.88),
              ],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight - 36),
                child: Form(
                  key: _form,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandLogo(width: 200)),
                        const SizedBox(height: 4),
                        const Text('Monitor  •  Manage  •  Grow',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.4,
                                color: AppColors.primaryDark)),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.90),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x1F1B5E20),
                                  blurRadius: 24,
                                  offset: Offset(0, 10))
                            ],
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Welcome back!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark)),
                                const SizedBox(height: 6),
                                const Text('Log in to find products and stores',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14.5,
                                        color: AppColors.muted)),
                                const SizedBox(height: 24),
                                if (_error != null) ErrorBanner(_error!),
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: _field(
                                      'Email address', Icons.email_outlined),
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _hide,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: _field(
                                    'Password',
                                    Icons.lock_outline,
                                    suffix: IconButton(
                                      tooltip: _hide
                                          ? 'Show password'
                                          : 'Hide password',
                                      icon: Icon(
                                          _hide
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppColors.muted),
                                      onPressed: () =>
                                          setState(() => _hide = !_hide),
                                    ),
                                  ),
                                  validator: (v) =>
                                      Validators.required(v, 'password'),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 8)),
                                    child: const Text('Forgot password?',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(54),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white))
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                              Icon(Icons.login, size: 20),
                                              SizedBox(width: 10),
                                              Text('Login'),
                                            ]),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Row(children: [
                                    Expanded(
                                        child: Divider(color: AppColors.light)),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 14),
                                      child: Text('OR',
                                          style: TextStyle(
                                              fontSize: 12,
                                              letterSpacing: 1.4,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.muted)),
                                    ),
                                    Expanded(
                                        child: Divider(color: AppColors.light)),
                                  ]),
                                ),
                                GoogleButton(
                                    onPressed: _google,
                                    loading: _loading,
                                    showDivider: false,
                                    height: 54,
                                    radius: 16),
                                const SizedBox(height: 10),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('New user?',
                                          style: TextStyle(fontSize: 14.5)),
                                      TextButton(
                                        onPressed: () => Navigator.pushNamed(
                                            context, '/register'),
                                        style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 10)),
                                        child: const Text('Register',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800)),
                                      ),
                                    ]),
                              ]),
                        ),
                        const SizedBox(height: 18),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
