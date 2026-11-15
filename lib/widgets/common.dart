import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(Icons.eco, color: Colors.white, size: size * 0.55),
    );
  }
}

/// Opisyal na logo ng AgriMamView (transparent, walang card).
class BrandLogo extends StatelessWidget {
  final double width;
  const BrandLogo({super.key, this.width = 210});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/agrimamview_logo.png', width: width, fit: BoxFit.contain);
  }
}

class StockBadge extends StatelessWidget {
  final String status; // in, low, out
  const StockBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final map = {
      'in': ('In Stock', AppColors.primary, AppColors.primary),
      'low': ('Low Stock', AppColors.warning, AppColors.warningText),
      'out': ('Out of Stock', AppColors.error, AppColors.error),
    };
    final (label, bg, fg) = map[status] ?? map['out']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg.withOpacity(status == 'low' ? 0.18 : 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

/// Berdeng header ng mga tab ng owner (Produkto, Tindahan, Profile).
class GradientHead extends StatelessWidget {
  final String title;
  final String subtitle;
  const GradientHead({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 22 + MediaQuery.of(context).padding.top, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
      ]),
    );
  }
}

const cardShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))];

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.error))),
      ]),
    );
  }
}
