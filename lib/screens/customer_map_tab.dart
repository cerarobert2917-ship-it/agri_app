import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/config.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../data/catalog_repository.dart';
import '../data/product_images.dart';
import '../data/store_data.dart';

class _StorePin {
  final String key;
  final String name;
  final LatLng pos;
  double? km; // layo mula sa customer, kung napayagan ang location
  _StorePin(this.key, this.name, this.pos);
}

/// Mapa para sa customer: nakikita ang mga tindahan.
class CustomerMapTab extends StatefulWidget {
  const CustomerMapTab({super.key});

  @override
  State<CustomerMapTab> createState() => _CustomerMapTabState();
}

class _CustomerMapTabState extends State<CustomerMapTab> {
  final _map = MapController();
  bool _ready = false;
  bool _loading = false;
  LatLng? _me;
  String? _selected;
  String? _hover; // pin na nakaturo ang mouse

  // galing sa database (GET /catalog), hindi na sa fixed sample data
  List<_StorePin> _stores = [];
  bool _catalogLoading = true;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _locateMe();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      await CatalogRepository.instance.load();
      final pins = [
        for (final m in CatalogRepository.instance.stores) _StorePin(m.key, m.name, LatLng(m.lat, m.lng)),
      ];
      final me = _me;
      if (me != null) {
        for (final p in pins) {
          p.km = Geolocator.distanceBetween(me.latitude, me.longitude, p.pos.latitude, p.pos.longitude) / 1000;
        }
      }
      if (!mounted) return;
      setState(() {
        _stores = pins;
        if (_selected != null && !pins.any((p) => p.key == _selected)) _selected = null;
        _catalogLoading = false;
      });
      _fit();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogError = e.toString();
        _catalogLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  _StorePin? get _selectedPin {
    for (final s in _stores) {
      if (s.key == _selected) return s;
    }
    return null;
  }

  Future<LatLng?> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 8));
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _locateMe() async {
    setState(() => _loading = true);
    final me = await _locate();
    if (!mounted) return;
    setState(() {
      _me = me;
      for (final s in _stores) {
        s.km = me == null
            ? null
            : Geolocator.distanceBetween(me.latitude, me.longitude,
                    s.pos.latitude, s.pos.longitude) /
                1000;
      }
      _loading = false;
    });
  }

  /// Ipakita ang lahat ng tindahan. Hindi isinasama ang lokasyon ng user,
  /// para hindi lumiit ang mapa kapag malayo siya sa Mamburao.
  void _fit() {
    if (!_ready || _stores.isEmpty) return;
    setState(() => _selected = null);
    _map.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(_stores.map((s) => s.pos).toList()),
        padding: const EdgeInsets.all(70)));
  }

  void _select(_StorePin s) {
    setState(() => _selected = s.key);
    if (_ready) _map.move(s.pos, 16);
  }

  List<Marker> get _markers {
    // ang napiling pin ay nasa pinakaitaas
    final ordered = [
      ..._stores.where((s) => s.key != _selected),
      ..._stores.where((s) => s.key == _selected),
    ];
    return [
      for (final s in ordered)
        Marker(
          point: s.pos,
          width: 140,
          height: 64,
          alignment: Alignment.topCenter,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hover = s.key),
            onExit: (_) => setState(() {
              if (_hover == s.key) _hover = null;
            }),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _select(s),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (s.key == _selected || s.key == _hover)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: AppColors.shadow, blurRadius: 6)
                            ]),
                        child: Text(s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    Icon(Icons.location_on,
                        size: 40,
                        color: s.key == _selected
                            ? AppColors.warning
                            : AppColors.primary),
                  ]),
            ),
          ),
        ),
      if (_me != null)
        Marker(
          point: _me!,
          width: 22,
          height: 22,
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4)
                ]),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final sel = _selectedPin;

    return Stack(children: [
      Positioned.fill(
        child: FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: LatLng(AppConfig.defaultLat, AppConfig.defaultLng),
            initialZoom: 14,
            onMapReady: () {
              _ready = true;
              _fit();
            },
            // pindutin ang mapa para isara ang sheet
            onTap: (tapPosition, point) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.agrifind.agri_app',
            ),
            MarkerLayer(markers: _markers),
            const RichAttributionWidget(attributions: [
              TextSourceAttribution('© OpenStreetMap contributors')
            ]),
          ],
        ),
      ),

      // header
      Positioned(
        left: 12,
        right: 12,
        top: top + 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 20,
                    offset: Offset(0, 6))
              ]),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child:
                  const Icon(Icons.storefront, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stores in Mamburao',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                        _catalogError != null
                            ? 'Could not load stores. Tap refresh.'
                            : _catalogLoading
                                ? 'Loading stores...'
                                : '${_stores.length} stores • tap a pin to view',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                  ]),
            ),
            IconButton(
                onPressed: (_loading || _catalogLoading)
                    ? null
                    : () {
                        _loadCatalog();
                        _locateMe();
                      },
                icon: const Icon(Icons.refresh, color: AppColors.primary)),
          ]),
        ),
      ),

      // ipakita ulit ang lahat ng tindahan
      Positioned(
        right: 12,
        top: top + 84,
        child: Material(
          color: Colors.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _fit,
            child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.my_location,
                    color: AppColors.primary, size: 20)),
          ),
        ),
      ),

      if (_catalogLoading && _stores.isEmpty) const Center(child: CircularProgressIndicator()),
      if (!_catalogLoading && _stores.isEmpty)
        Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 20)]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_catalogError ?? 'No stores are available yet.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              TextButton(onPressed: _loadCatalog, child: const Text('Try again')),
            ]),
          ),
        ),

      // sheet sa ibaba: lalabas kapag may napiling pin
      if (sel != null)
        _StoreSheet(
            key: ValueKey(sel.key),
            name: sel.name,
            image: CatalogRepository.instance.metaFor(sel.key)?.image,
            photoUrl: CatalogRepository.instance.metaFor(sel.key)?.photoUrl,
            km: sel.km,
            info: CatalogRepository.instance.info[sel.key]),
    ]);
  }
}

/// Laman ng pop-up sheet: pangalan, oras (bukas/sara), table ng products,
/// at lingguhang oras.
class _StoreDetails extends StatelessWidget {
  final String name;
  final String? image;
  final String? photoUrl;
  final double? km;
  final StoreInfo? info;
  const _StoreDetails(
      {required this.name,
      required this.km,
      required this.info,
      this.image,
      this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final i = info;
    if (i == null) {
      return const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Walang available na data para sa tindahang ito.'));
    }
    final now = StoreInfo.phNow();
    final st = i.status(now);
    final money = NumberFormat('#,##0.00');
    final statusColor = st.open
        ? AppColors.primary
        : (i.hasHours ? AppColors.error : AppColors.muted);
    final hasPhoto = photoUrl != null || (image != null && image!.isNotEmpty);
    final placeholder = Container(
        color: AppColors.background,
        alignment: Alignment.center,
        child: const Icon(Icons.storefront, size: 40, color: AppColors.muted));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      if (hasPhoto) ...[
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: photoUrl != null
                ? Image.network(photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => (image != null && image!.isNotEmpty)
                        ? Image.asset(image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
                        : placeholder)
                : Image.asset(image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
          ),
        ),
      ],
      const SizedBox(height: 10),
      Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.access_time, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(st.text,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ]),
            ),
            if (km != null)
              Text('${km!.toStringAsFixed(1)} km away',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
      const SizedBox(height: 16),
      Row(children: [
        const Expanded(
          child: Text('Products, stock & price',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20)),
          child: Text('${i.products.length} items',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ),
      ]),
      const SizedBox(height: 10),
      for (final g in productGroupOrder)
        if (i.products.any((p) => productGroup(p.category) == g)) ...[
          _GroupHeader(
              title: g,
              count: i.products
                  .where((p) => productGroup(p.category) == g)
                  .length),
          for (final p in i.products.where((p) => productGroup(p.category) == g))
            _ProductCard(product: p, money: money),
        ],
      const SizedBox(height: 18),
      const Text('Store hours',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      if (!i.hasHours)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
              (i.hoursText ?? '').trim().isEmpty
                  ? 'The store has not set its hours yet.'
                  : i.hoursText!,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        )
      else
        ...[
      for (var d = 0; d < 7; d++)
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              color: d == now.weekday - 1
                  ? AppColors.light.withOpacity(0.35)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(
              child: Text(StoreInfo.dayNames[d],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: d == now.weekday - 1
                          ? FontWeight.w700
                          : FontWeight.w500)),
            ),
            Text(
                i.week[d] == null
                    ? 'Closed'
                    : '${StoreInfo.fmt(i.week[d]!.open)} – ${StoreInfo.fmt(i.week[d]!.close)}',
                style: TextStyle(
                    fontSize: 13,
                    color: i.week[d] == null ? AppColors.error : AppColors.text,
                    fontWeight: d == now.weekday - 1
                        ? FontWeight.w700
                        : FontWeight.w500)),
          ]),
        ),
        ],
      const SizedBox(height: 24),
    ]);
  }
}

/// Pamagat ng grupo ng produkto (Fertilizers, Rice Seeds, Vegetable Seeds).
class _GroupHeader extends StatelessWidget {
  final String title;
  final int count;
  const _GroupHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final icon = title == 'Fertilizers'
        ? Icons.science_outlined
        : title == 'Rice Seeds'
            ? Icons.grass
            : title == 'Vegetable Seeds'
                ? Icons.eco_outlined
                : Icons.inventory_2_outlined;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark)),
        const SizedBox(width: 6),
        Text('$count',
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(height: 1, color: AppColors.line)),
      ]),
    );
  }
}

/// Isang product card: larawan sa kaliwa, pangalan + sukat + stock sa gitna,
/// presyo sa kanan.
class _ProductCard extends StatelessWidget {
  final Product product;
  final NumberFormat money;
  const _ProductCard({required this.product, required this.money});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
              color: Color(0x141B5E20), blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        ProductThumb(name: p.name, size: 64, dimmed: p.stock == 0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 2),
                Text(p.unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.muted)),
                const SizedBox(height: 6),
                _StockBadge(p.stock),
              ]),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text('₱${money.format(p.price)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark)),
                ),
                const SizedBox(height: 2),
                const Text('per unit',
                    style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ]),
        ),
      ]),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge(this.stock);

  @override
  Widget build(BuildContext context) {
    final out = stock == 0;
    final low = stock > 0 && stock < 10;
    final color = out
        ? AppColors.error
        : low
            ? AppColors.warningText
            : AppColors.primary;
    final label = out
        ? 'Out of stock'
        : low
            ? 'Low • $stock left'
            : '$stock in stock';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

/// Pop-up sa ibaba: pwedeng i-drag (touch o mouse) pataas/pababa,
/// o i-tap ang handle para mag-toggle ng taas.
class _StoreSheet extends StatefulWidget {
  final String name;
  final String? image;
  final String? photoUrl;
  final double? km;
  final StoreInfo? info;
  const _StoreSheet(
      {super.key,
      required this.name,
      required this.km,
      required this.info,
      this.image,
      this.photoUrl});

  @override
  State<_StoreSheet> createState() => _StoreSheetState();
}

class _StoreSheetState extends State<_StoreSheet> {
  static const _min = 0.12, _mid = 0.4, _max = 0.92;
  final _ctl = DraggableScrollableController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_ctl.isAttached) return;
    // kung hindi pa puno -> itaas nang todo; kung puno na -> ibaba
    final target = _ctl.size < _max - 0.05 ? _max : _mid;
    _ctl.animateTo(target,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      // payagan ang pag-drag gamit ang mouse (Chrome/desktop)
      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      }),
      child: DraggableScrollableSheet(
        controller: _ctl,
        initialChildSize: _mid,
        minChildSize: _min,
        maxChildSize: _max,
        snap: true,
        snapSizes: const [_min, _mid, _max],
        builder: (context, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 28,
                  offset: Offset(0, -8))
            ],
          ),
          child: ListView(
              controller: scroll,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggle,
                    child: SizedBox(
                      height: 32,
                      child: Center(
                          child: Container(
                              width: 54,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: AppColors.muted.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(5)))),
                    ),
                  ),
                ),
                _StoreDetails(
                    name: widget.name,
                    image: widget.image,
                    photoUrl: widget.photoUrl,
                    km: widget.km,
                    info: widget.info),
              ]),
        ),
      ),
    );
  }
}
