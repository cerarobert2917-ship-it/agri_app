import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Ang 4 na pangunahing kategorya ng produkto, ginagamit ng Viewer at ng Owner.
class ProductGroup {
  final String key;
  final String label;
  final String asset; // icon na larawan ng kategorya
  final List<String> keywords; // tugma sa pangalan ng kategorya sa database
  const ProductGroup(this.key, this.label, this.asset, this.keywords);
}

const productGroups = [
  ProductGroup('seeds', 'Seeds', 'assets/images/categories/seeds.png', ['seed']),
  ProductGroup('fertilizer', 'Fertilizer', 'assets/images/categories/fertilizer.png', ['fertilizer']),
  ProductGroup('pesticides', 'Pesticides', 'assets/images/categories/pesticides.png', ['pestic', 'herbic', 'insectic']),
  ProductGroup('tools', 'Tools/Equipment', 'assets/images/categories/tools.png', ['tool', 'equipment', 'irrigation']),
];

/// Anong grupo ang kinabibilangan ng kategoryang may ganitong pangalan? null kung wala sa apat.
String? groupKeyOf(String? categoryName) {
  final n = (categoryName ?? '').toLowerCase();
  if (n.isEmpty) return null;
  for (final g in productGroups) {
    if (g.keywords.any(n.contains)) return g.key;
  }
  return null;
}

/// Hilera ng apat na button. Pindutin ulit ang napiling button para alisin ang filter.
class CategoryChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  /// true kapag nasa ibabaw ng berdeng header (puti ang itsura).
  final bool onGreen;
  const CategoryChips({super.key, required this.selected, required this.onChanged, this.onGreen = false});

  @override
  Widget build(BuildContext context) {
    // Pantay ang lapad ng apat na button para kasya lahat sa isang hilera
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < productGroups.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _chip(productGroups[i])),
        ],
      ]),
    );
  }

  Widget _chip(ProductGroup g) {
    final on = selected == g.key;
    final bg = onGreen ? (on ? Colors.white : Colors.white.withOpacity(0.16)) : (on ? AppColors.light : Colors.white);
    final fg = onGreen ? (on ? AppColors.primaryDark : Colors.white) : (on ? AppColors.primaryDark : AppColors.text);
    final border = onGreen ? (on ? Colors.white : Colors.white54) : (on ? AppColors.primary : AppColors.line);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(on ? null : g.key),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Walang background; ang icon lang
          SizedBox(
            width: 28,
            height: 28,
            child: Image.asset(g.asset, fit: BoxFit.contain),
          ),
          const SizedBox(height: 3),
          // Isang linya; lumiliit ang letra kung kulang ang espasyo para hindi maputol
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(g.label,
                maxLines: 1,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
          ),
        ]),
      ),
    );
  }
}
