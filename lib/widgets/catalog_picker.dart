import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/product_catalog.dart';
import '../data/product_images.dart';

/// Bottom sheet para pumili ng produkto sa katalogo. Ibinabalik ang napili
/// (o null kung isinara).
Future<CatalogItem?> pickFromCatalog(BuildContext context) {
  return showModalBottomSheet<CatalogItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _CatalogSheet(),
  );
}

class _CatalogSheet extends StatefulWidget {
  const _CatalogSheet();

  @override
  State<_CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<_CatalogSheet> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<CatalogItem> get _list {
    final words = _q.text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return productCatalog.where((c) {
      final t = '${c.name} ${c.category}'.toLowerCase();
      return words.every(t.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final h = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: h * 0.85,
        child: Column(children: [
          const SizedBox(height: 10),
          Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                  color: AppColors.muted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(5))),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Product catalog',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Pick a product, then just enter your price and stock.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search: urea, rice, tomato...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('No match. You can still add it manually.',
                        style: TextStyle(color: AppColors.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = list[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, c),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line)),
                            child: Row(children: [
                              ProductThumb(name: c.name, size: 56),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text('${c.packaging} • ${c.category}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.muted)),
                                    ]),
                              ),
                              const Icon(Icons.add_circle,
                                  color: AppColors.primary),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
