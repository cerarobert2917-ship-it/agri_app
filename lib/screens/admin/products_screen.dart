import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../services/admin_service.dart';
import '../../widgets/common.dart';
import 'admin_widgets.dart';

/// Product monitoring. Owners manage their own products, prices and stock;
/// admins can only view them and hide / restore inappropriate listings.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _svc = AdminService();
  static const _stockLabels = ['All', 'In stock', 'Low stock', 'Out of stock', 'Hidden'];
  static const _stockValues = {'All': '', 'In stock': 'in', 'Low stock': 'low', 'Out of stock': 'out', 'Hidden': 'hidden'};

  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _cats = [];
  int? _storeId;
  int? _catId;
  String _stock = 'All';
  String _q = '';

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final s = await _svc.stores();
      final c = await _svc.categories();
      if (mounted) {
        setState(() {
          _stores = s;
          _cats = c;
        });
      }
    } catch (_) {
      // the filter lists are optional; the product list shows its own error
    }
  }

  Future<void> _hide(Map<String, dynamic> p, Future<void> Function() reload) async {
    final reason = await reasonDialog(
      context,
      title: 'Hide listing',
      hint: 'Why is this listing inappropriate? (sent to the owner)',
      confirmLabel: 'Hide',
    );
    if (reason == null) return;
    try {
      await _svc.moderateProduct(asInt(p['id']), hidden: true, reason: reason);
      if (mounted) toast(context, 'Listing hidden from viewers.');
      await reload();
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> _restore(Map<String, dynamic> p, Future<void> Function() reload) async {
    final ok = await confirmDialog(context,
        title: 'Restore listing?', message: '"${p['name']}" will be visible to viewers again.', confirmLabel: 'Restore');
    if (!ok) return;
    try {
      await _svc.moderateProduct(asInt(p['id']), hidden: false);
      if (mounted) toast(context, 'Listing restored.');
      await reload();
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product monitoring')),
      body: AsyncView<List<Map<String, dynamic>>>(
        loadKey: '$_storeId|$_catId|$_stock',
        load: () => _svc.products(storeId: _storeId, categoryId: _catId, stock: _stockValues[_stock] ?? ''),
        builder: (context, all, reload) {
          final list = _q.isEmpty
              ? all
              : all.where((p) => '${p['name']} ${p['brand'] ?? ''} ${p['store_name']}'.toLowerCase().contains(_q)).toList();
          final low = list.where((p) => stockStatus(p) == 'low').length;
          final out = list.where((p) => stockStatus(p) == 'out').length;
          final hidden = list.where((p) => asInt(p['is_hidden']) == 1).length;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(14), children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF1565C0)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Store owners manage their own products, prices and stock. Admins can monitor listings and hide inappropriate ones.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1)),
                    ),
                  ),
                ]),
              ),
              SearchField(hint: 'Search product, brand or store...', onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _storeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Store', isDense: true),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All stores')),
                      for (final s in _stores) DropdownMenuItem<int?>(value: asInt(s['id']), child: Text('${s['name']}', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _storeId = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _catId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category', isDense: true),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                      for (final c in _cats) DropdownMenuItem<int?>(value: asInt(c['id']), child: Text('${c['name']}', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _catId = v),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              FilterChips(options: _stockLabels, selected: _stock, onSelected: (v) => setState(() => _stock = v)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('${list.length} products • $low low stock • $out out of stock • $hidden hidden',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
              if (list.isEmpty)
                const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products found', subtitle: 'Try changing the filters.')
              else
                for (final p in list) _ProductCard(product: p, onHide: () => _hide(p, reload), onRestore: () => _restore(p, reload)),
            ]),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onHide;
  final VoidCallback onRestore;
  const _ProductCard({required this.product, required this.onHide, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final hidden = asInt(p['is_hidden']) == 1;
    return AdminCard(
      padding: const EdgeInsets.all(10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ProductImage(name: '${p['name']}', imageUrl: p['image_url'], size: 60, dimmed: hidden),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('${p['store_name']} • ${p['category_name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text('${peso(p['price'])} / ${p['unit']} • ${asInt(p['stock_quantity'])} in stock', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              StockBadge(stockStatus(p)),
              if (hidden) const StatusBadge('hidden'),
            ]),
            if (hidden && hasValue(p['moderation_reason']))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Reason: ${p['moderation_reason']}', style: const TextStyle(fontSize: 11, color: AppColors.error)),
              ),
          ]),
        ),
        PopupMenuButton<String>(
          tooltip: 'Moderation',
          onSelected: (v) => v == 'hide' ? onHide() : onRestore(),
          itemBuilder: (_) => [
            if (!hidden) const PopupMenuItem(value: 'hide', child: Text('Hide listing')) else const PopupMenuItem(value: 'restore', child: Text('Restore listing')),
          ],
        ),
      ]),
    );
  }
}
