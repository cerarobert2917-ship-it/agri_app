import 'package:flutter/material.dart';
import '../core/helpers.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../data/product_catalog.dart';
import '../data/product_images.dart';
import '../services/owner_service.dart';
import '../widgets/catalog_picker.dart';
import '../widgets/category_chips.dart';
import '../widgets/common.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product; // may laman kapag nag-e-edit
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const units = ['kg', 'sack', 'liter', 'piece'];

  final _form = GlobalKey<FormState>();
  final _svc = OwnerService();
  late final TextEditingController _name, _brand, _price, _stock, _low;
  List<Map<String, dynamic>> _cats = [];
  int? _catId;
  String _unit = 'piece';
  CatalogItem? _picked; // napili sa katalogo
  bool _saving = false;
  String? _error;

  /// Aling sa 4 na grupo ang napiling kategorya (null kung ibang kategorya, hal. Animal Feeds).
  String? get _groupOfSelected {
    for (final c in _cats) {
      if (asInt(c['id']) == _catId) return groupKeyOf('${c['name']}');
    }
    return null;
  }

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?['name'] ?? '');
    _brand = TextEditingController(text: p?['brand'] ?? '');
    _price = TextEditingController(
        text: p != null ? asDouble(p['price']).toString() : '');
    _stock = TextEditingController(
        text: p != null ? asInt(p['stock_quantity']).toString() : '0');
    _low = TextEditingController(
        text: p != null ? asInt(p['low_stock_threshold']).toString() : '5');
    if (p != null) {
      _catId = asInt(p['category_id']);
      if (units.contains('${p['unit']}')) _unit = '${p['unit']}';
    }
    _name.addListener(() => setState(() {}));
    _loadCategories();
  }

  @override
  void dispose() {
    for (final c in [_name, _brand, _price, _stock, _low]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final c = await _svc.categories();
      setState(() {
        _cats = c;
        if (_picked != null) _applyCategoryFor(_picked!);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  /// Hanapin sa mga kategorya ng backend ang katumbas ng kategorya ng katalogo.
  void _applyCategoryFor(CatalogItem item) {
    final cat = item.category.toLowerCase();
    final keys = cat.contains('rice')
        ? ['rice', 'seed']
        : cat.contains('vegetable')
            ? ['vegetable', 'seed']
            : ['fertilizer'];
    for (final k in keys) {
      for (final c in _cats) {
        if ('${c['name']}'.toLowerCase().contains(k)) {
          _catId = asInt(c['id']);
          return;
        }
      }
    }
  }

  Future<void> _chooseFromCatalog() async {
    final item = await pickFromCatalog(context);
    if (item == null || !mounted) return;
    _name.text = item.name; // may listener na nagre-rebuild
    setState(() {
      _picked = item;
      _unit = item.unit;
      _applyCategoryFor(item);
    });
  }

  String? _number(String? v, {bool decimal = false}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Required';
    final n = decimal ? double.tryParse(t) : int.tryParse(t);
    if (n == null) return 'Numbers only';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _svc.saveProduct({
        if (_editing) 'id': asInt(widget.product!['id']),
        'category_id': _catId,
        'name': _name.text.trim(),
        'brand': _brand.text.trim(),
        'unit': _unit,
        'price': double.parse(_price.text.trim()),
        'stock_quantity': int.parse(_stock.text.trim()),
        'low_stock_threshold': int.parse(_low.text.trim()),
        'is_available': _editing ? asInt(widget.product!['is_available']) : 1,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text(_editing ? 'Edit Product' : 'Add Product')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ErrorBanner(_error!),
                  if (!_editing) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _chooseFromCatalog,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.light)),
                        child: Row(children: [
                          const Icon(Icons.grid_view_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pick from product catalog',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                      'Name, picture and packaging are filled in for you.',
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.muted)),
                                ]),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.primary),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_name.text.trim().isNotEmpty) ...[
                    Row(children: [
                      ProductThumb(name: _name.text.trim(), size: 72),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_name.text.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                              if (_picked != null)
                                Text('${_picked!.packaging} • ${_picked!.category}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.muted)),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Product name (e.g. Urea 46-0-0)',
                        prefixIcon: Icon(Icons.inventory_2_outlined)),
                    validator: (v) =>
                        Validators.required(v, 'product name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _brand,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Brand (optional)',
                        prefixIcon: Icon(Icons.sell_outlined)),
                  ),
                  const SizedBox(height: 12),
                  // Piliin kung seeds, fertilizer, pesticides o tools/equipment
                  FormField<int>(
                    initialValue: _catId,
                    validator: (_) => _catId == null ? 'Choose a category' : null,
                    builder: (state) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Category',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 8),
                      CategoryChips(
                        selected: _groupOfSelected,
                        onChanged: (key) {
                          if (key == null) return;
                          for (final c in _cats) {
                            if (groupKeyOf('${c['name']}') == key) {
                              setState(() => _catId = asInt(c['id']));
                              state.didChange(_catId);
                              return;
                            }
                          }
                        },
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(state.errorText!,
                              style: const TextStyle(fontSize: 12, color: AppColors.error)),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        items: [
                          for (final u in units)
                            DropdownMenuItem(value: u, child: Text(u))
                        ],
                        onChanged: (v) => setState(() => _unit = v ?? 'piece'),
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Price (₱)'),
                        validator: (v) => _number(v, decimal: true),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        validator: _number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _low,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Low stock alert'),
                        validator: _number,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  const Text(
                      'When stock reaches or drops to the "Low stock alert" level, it shows as "Low Stock".',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text(_editing ? 'Save' : 'Add Product'),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
