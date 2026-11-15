import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => AuthService(), child: const AgriApp()));
}

class AgriApp extends StatelessWidget {
  const AgriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriMamView',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) => PhoneFrame(child: child!),
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}

/// Kapag malapad ang window (Chrome/desktop), ipapakita ang app sa loob ng
/// phone-sized na frame. Sa totoong phone o emulator, walang epekto.
class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({super.key, required this.child});

  static const double _w = 412;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= 600) return child; // phone na talaga

    final h = (mq.size.height - 40).clamp(520.0, 880.0).toDouble();
    return ColoredBox(
      color: const Color(0xFF263238),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(42),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: SizedBox(
              width: _w,
              height: h,
              child: MediaQuery(
                data: mq.copyWith(size: Size(_w, h)),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
