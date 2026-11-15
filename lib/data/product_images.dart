import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Larawan ng produkto. Hinahanap sa assets/images/products/ ayon sa pangalan
/// ng produkto (hal. "Urea 46-0-0 Fertilizer" -> urea_46_0_0_fertilizer.png).
/// Kapag walang nahanap na larawan, placeholder ang ipapakita.
///
/// Para palitan ng totoong litrato: ilagay lang ang file na may parehong
/// pangalan sa assets/images/products/ (png o jpg na pinangalanan sa .png).
String productImagePath(String productName) {
  final slug = productName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'assets/images/products/$slug.png';
}

class ProductThumb extends StatelessWidget {
  final String name;
  final double size;
  final bool dimmed;
  const ProductThumb(
      {super.key, required this.name, this.size = 64, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.background,
      alignment: Alignment.center,
      child: Icon(Icons.eco_outlined,
          size: size * 0.45, color: AppColors.light),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Opacity(
          opacity: dimmed ? 0.45 : 1,
          child: Image.asset(
            productImagePath(name),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        ),
      ),
    );
  }
}
