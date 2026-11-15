import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';
import 'role_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthService>();
    final ok = await auth.restoreSession();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const RoleRouter()));
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.light, AppColors.background],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            BrandLogo(width: 270),
            SizedBox(height: 8),
            Text('Prices, stock and stores',
                style: TextStyle(color: AppColors.muted)),
            SizedBox(height: 30),
            CircularProgressIndicator(color: AppColors.primary),
          ]),
        ),
      ),
    );
  }
}
