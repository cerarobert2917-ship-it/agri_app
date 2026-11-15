import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show BrowserContextMenu;
import '../core/helpers.dart';
import '../core/theme.dart';
import '../widgets/product_row.dart';
import '../widgets/store_map.dart';

/// Unang tab ng owner: mapa na may pin ng tindahan at sheet ng mga produkto.
class OwnerMapTab extends StatefulWidget {
  final Map<String, dynamic> store;
  final List<Map<String, dynamic>> products;
  final PinController pin;
  final OwnerActions actions;
  const OwnerMapTab(
      {super.key,
      required this.store,
      required this.products,
      required this.pin,
      required this.actions});

  @override
  State<OwnerMapTab> createState() => _OwnerMapTabState();
}

class _OwnerMapTabState extends State<OwnerMapTab> {
  final _sheet = DraggableScrollableController();
  bool _rightDrag = false;

  @override
  void initState() {
    super.initState();
    // sa web: walang lalabas na browser menu kapag right-click drag ang ginamit
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
  }

  @override
  void dispose() {
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
    _sheet.dispose();
    super.dispose();
  }

  static const _boxShadow = [
    BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 6))
  ];

  Widget _statusChip() {
    final s = '${widget.store['status']}';
    final (label, color) = switch (s) {
      'approved' => ('Approved', AppColors.primary),
      'rejected' => ('Rejected', AppColors.error),
      _ => ('Pending', AppColors.warningText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _stat(String label, int n, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text('$n',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final products = widget.products;
    final low = products.where((p) => stockStatus(p) == 'low').length;
    final out = products.where((p) => stockStatus(p) == 'out').length;
    final barangay = '${widget.store['barangay'] ?? ''}';

    return LayoutBuilder(builder: (context, c) {
      // collapsed ~238px, expanded up to just under the floating header
      final minSize = (238 / c.maxHeight).clamp(0.2, 0.6).toDouble();
      final maxSize = ((c.maxHeight - top - 84) / c.maxHeight)
          .clamp(minSize + 0.1, 0.95)
          .toDouble();
      return Stack(children: [
        Positioned.fill(child: StoreMap(pin: widget.pin)),

        // floating header
        Positioned(
          left: 12,
          right: 12,
          top: top + 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _boxShadow),
            child: Row(children: [
              Image.asset('assets/images/agrimamview_logo.png',
                  width: 64, height: 46, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.store['name']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(
                          barangay.isEmpty ? 'Mamburao' : '$barangay, Mamburao',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ]),
              ),
              const SizedBox(width: 8),
              _statusChip(),
            ]),
          ),
        ),

        // coordinates
        Positioned(
          left: 12,
          top: top + 84,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _boxShadow),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Store location',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ListenableBuilder(
                listenable: widget.pin,
                builder: (_, __) => Text(
                    '${widget.pin.lat.toStringAsFixed(5)}, ${widget.pin.lng.toStringAsFixed(5)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),

        // recenter
        Positioned(
          right: 12,
          top: top + 84,
          child: Tooltip(
            message: 'Recenter',
            child: Material(
              color: Colors.white,
              elevation: 4,
              shadowColor: AppColors.shadow,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: widget.pin.recenter,
                child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.my_location,
                        color: AppColors.primary, size: 20)),
              ),
            ),
          ),
        ),

        // bottom sheet: hilahin pataas para makita ang lahat ng produkto
        Positioned.fill(
          child: ScrollConfiguration(
            // payagan ang mouse: pindutin at hilahin pataas/pababa
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            }),
            child: Listener(
              // right mouse button: pindutin nang hawak, tapos hilahin
              onPointerDown: (e) {
                _rightDrag = e.kind == PointerDeviceKind.mouse &&
                    (e.buttons & kSecondaryMouseButton) != 0;
              },
              onPointerMove: (e) {
                if (!_rightDrag || !_sheet.isAttached) return;
                final next = (_sheet.size - e.delta.dy / c.maxHeight)
                    .clamp(minSize, maxSize)
                    .toDouble();
                _sheet.jumpTo(next);
              },
              onPointerUp: (e) {
                if (!_rightDrag) return;
                _rightDrag = false;
                if (!_sheet.isAttached) return;
                final mid = (minSize + maxSize) / 2;
                _sheet.animateTo(_sheet.size > mid ? maxSize : minSize,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut);
              },
              onPointerCancel: (_) => _rightDrag = false,
              child: DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: minSize,
                minChildSize: minSize,
                maxChildSize: maxSize,
                snap: true,
                builder: (context, scroll) => Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(26)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 28,
                          offset: Offset(0, -8))
                    ],
                  ),
                  child: CustomScrollView(
                    controller: scroll,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.fromLTRB(10, 10, 10, 12),
                              alignment: Alignment.center,
                              child: Container(
                                  width: 48,
                                  height: 5,
                                  decoration: BoxDecoration(
                                      color: AppColors.muted.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(5))),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                            child: Row(children: [
                              _stat('Products', products.length,
                                  AppColors.primary),
                              const SizedBox(width: 8),
                              _stat('Low', low, AppColors.warning),
                              const SizedBox(width: 8),
                              _stat('Out', out, AppColors.error),
                            ]),
                          ),
                        ]),
                      ),
                      if (products.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                              child: Text(
                                  'You have no products yet.\nGo to the Products tab to add one.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.muted))),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => ProductRow(
                                key: ValueKey('map-${products[i]['id']}'),
                                p: products[i],
                                first: i == 0,
                                actions: widget.actions,
                              ),
                              childCount: products.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}
