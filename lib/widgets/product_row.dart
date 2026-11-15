import 'package:flutter/material.dart';
import '../core/helpers.dart';
import '../core/theme.dart';
import '../data/product_images.dart';
import 'common.dart';

/// Mga aksyon sa produkto, galing sa OwnerHome.
class OwnerActions {
  final Future<void> Function(Map<String, dynamic> p, double price) setPrice;
  final Future<void> Function(Map<String, dynamic> p, int newStock) setStock;
  final void Function(Map<String, dynamic> p) edit;
  final void Function(Map<String, dynamic> p) menu;
  const OwnerActions({required this.setPrice, required this.setStock, required this.edit, required this.menu});
}

/// Isang hilera ng produkto: pangalan, presyo (i-tap para baguhin), badge at stock na may + / −.
class ProductRow extends StatefulWidget {
  final Map<String, dynamic> p;
  final bool first;
  final OwnerActions actions;
  const ProductRow({super.key, required this.p, required this.actions, this.first = false});

  @override
  State<ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<ProductRow> {
  bool _editing = false;
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _startEdit() {
    _c.text = asDouble(widget.p['price']).toString();
    _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
    setState(() => _editing = true);
  }

  void _commit() {
    if (!_editing) return;
    setState(() => _editing = false);
    final n = double.tryParse(_c.text.trim());
    if (n != null && n >= 0 && n != asDouble(widget.p['price'])) widget.actions.setPrice(widget.p, n);
  }

  Widget _stepBtn(IconData icon, bool filled, VoidCallback? onTap) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: filled ? AppColors.primary : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Icon(icon, size: 18, color: filled ? Colors.white : AppColors.primary.withOpacity(onTap == null ? 0.35 : 1)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final stock = asInt(p['stock_quantity']);
    final brand = '${p['brand'] ?? ''}';
    final sub = [if (brand.isNotEmpty && brand != 'null') brand, '${p['unit']}'].join(' • ');

    return Container(
      decoration: BoxDecoration(border: widget.first ? null : const Border(top: BorderSide(color: AppColors.line))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ProductThumb(name: '${p['name']}', size: 52, dimmed: stock == 0),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.actions.edit(p),
              onLongPress: () => widget.actions.menu(p),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p['name']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height: 3),
            if (_editing)
              SizedBox(
                width: 110,
                child: Focus(
                  onFocusChange: (f) {
                    if (!f) _commit();
                  },
                  child: TextField(
                    controller: _c,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    onSubmitted: (_) => _commit(),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      prefixText: '₱',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                ),
              )
            else
              InkWell(
                onTap: _startEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${peso(p['price'])} ✎',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          StockBadge(stockStatus(p)),
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _stepBtn(Icons.remove, false, stock > 0 ? () => widget.actions.setStock(p, stock - 1) : null),
            SizedBox(
              width: 42,
              child: Text('$stock', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            _stepBtn(Icons.add, true, () => widget.actions.setStock(p, stock + 1)),
          ]),
        ]),
      ]),
    );
  }
}
