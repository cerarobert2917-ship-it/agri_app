import 'package:flutter/material.dart';
import '../core/helpers.dart';
import '../core/theme.dart';
import '../widgets/category_chips.dart';
import '../widgets/common.dart';
import '../widgets/product_row.dart';

class OwnerProductsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final OwnerActions actions;
  final VoidCallback onAdd;
  final Future<void> Function() onRefresh;
  const OwnerProductsScreen({
    super.key,
    required this.products,
    required this.actions,
    required this.onAdd,
    required this.onRefresh,
  });

  @override
  State<OwnerProductsScreen> createState() => _OwnerProductsScreenState();
}

class _OwnerProductsScreenState extends State<OwnerProductsScreen> {
  final _q = TextEditingController();
  String _filter = 'all'; // all, low, out
  String? _cat; // seeds, fertilizer, pesticides, tools

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _list {
    final q = _q.text.trim().toLowerCase();
    return widget.products.where((p) {
      if (q.isNotEmpty && !'${p['name']} ${p['brand']}'.toLowerCase().contains(q)) return false;
      if (_cat != null && groupKeyOf('${p['category_name']}') != _cat) return false;
      return _filter == 'all' || stockStatus(p) == _filter;
    }).toList();
  }

  Widget _chip(String key, String label) {
    final on = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: on ? AppColors.light : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? AppColors.primary : AppColors.line, width: 1.5),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: on ? AppColors.primaryDark : AppColors.text)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Stack(children: [
      Column(children: [
        const GradientHead(title: 'Products', subtitle: 'Tap a price to edit it. Use + and − to update stock.'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 96), children: [
              TextField(
                controller: _q,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search your products...',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
                ),
              ),
              const SizedBox(height: 10),
              CategoryChips(selected: _cat, onChanged: (v) => setState(() => _cat = v)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [_chip('all', 'All'), _chip('low', 'Low Stock'), _chip('out', 'Out of Stock')]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: cardShadow),
                child: list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          widget.products.isEmpty ? 'You have no products yet.\nTap + to add one.' : 'No matches.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      )
                    : Column(children: [
                        for (var i = 0; i < list.length; i++)
                          ProductRow(key: ValueKey('all-${list[i]['id']}'), p: list[i], first: i == 0, actions: widget.actions),
                      ]),
              ),
            ]),
          ),
        ),
      ]),
      Positioned(
        right: 16,
        bottom: 16,
        child: Tooltip(
          message: 'Add product',
          child: Material(
            color: AppColors.primary,
            elevation: 6,
            shadowColor: AppColors.shadow,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onAdd,
              child: const SizedBox(width: 56, height: 56, child: Icon(Icons.add, color: Colors.white, size: 30)),
            ),
          ),
        ),
      ),
    ]);
  }
}
