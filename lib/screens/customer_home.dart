import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import 'package:geolocator/geolocator.dart';
import '../data/catalog_repository.dart';
import '../data/product_images.dart';
import '../data/store_data.dart';
import '../services/auth_service.dart';
import '../services/change_notification_service.dart';
import '../widgets/agribot_bubble.dart';
import '../widgets/category_chips.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';
import 'customer_map_tab.dart';
import 'customer_notifications_tab.dart';
import 'profile_settings.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _tab = 0;
  final _notifs = ChangeNotificationService();

  @override
  void initState() {
    super.initState();
    _notifs.start(); // kumukuha ng bagong update kada 45 segundo
  }

  @override
  void dispose() {
    _notifs.dispose();
    super.dispose();
  }

  /// Bubukas ang AgriBot bilang chat window sa ibabaw ng kasalukuyang screen.
  void _openAgriBot() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Material(
            color: AppColors.background,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: ChatScreen(onClose: () => Navigator.pop(ctx)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SearchTab(),
      const CustomerMapTab(),
      CustomerNotificationsTab(key: ValueKey('notif-$_tab'), service: _notifs),
      const _ProfileTab(),
    ];
    return Scaffold(
      body: Stack(children: [
        pages[_tab],
        // Lumulutang na AgriBot, nasa lahat ng tab
        Positioned.fill(child: AgriBotBubble(onTap: _openAgriBot)),
      ]),
      bottomNavigationBar: ListenableBuilder(
        listenable: _notifs,
        builder: (context, _) {
          final n = _notifs.badgeCount;
          return NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) {
              setState(() => _tab = i);
              if (i != 2) _notifs.refresh();
            },
            destinations: [
              const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text(n > 9 ? '9+' : '$n'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: n > 0,
                  label: Text(n > 9 ? '9+' : '$n'),
                  child: const Icon(Icons.notifications),
                ),
                label: 'Notifications',
              ),
              const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          );
        },
      ),
    );
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});
  @override
  State<SearchTab> createState() => _SearchTabState();
}

/// Isang store na may hinahanap na produkto.
class _Offer {
  final StoreMeta store;
  final StoreInfo info;
  final Product product;
  double? km;
  _Offer(this.store, this.info, this.product);
}

/// Isang produkto at lahat ng store na meron nito.
class _Group {
  final String name;
  final List<_Offer> offers = [];
  _Group(this.name);
}

class _SearchTabState extends State<SearchTab> {
  final _q = TextEditingController();
  String? _cat; // napiling kategorya (seeds, fertilizer, pesticides, tools)
  List<_Group> _groups = [];
  bool _searched = false;
  bool _loading = true;
  String? _error;
  double? _myLat, _myLng;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _locate();
  }

  /// Stores and products come from the database, the same data store owners manage.
  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await CatalogRepository.instance.load();
      if (!mounted) return;
      setState(() => _loading = false);
      _search();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      _myLat = pos.latitude;
      _myLng = pos.longitude;
      _search();
    } catch (_) {}
  }

  /// Hanapin sa lahat ng store. Lahat ng salita sa tinype ay dapat nasa pangalan
  /// ng produkto, kaya ang "chicken feed" ay tatama sa "Chicken Starter Feed".
  void _search() {
    final words = _q.text.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final byName = <String, _Group>{};
    final repo = CatalogRepository.instance;
    for (final store in repo.stores) {
      final info = repo.info[store.key];
      if (info == null) continue;
      for (final p in info.products) {
        final n = p.name.toLowerCase();
        if (!words.every(n.contains)) continue;
        if (_cat != null && groupKeyOf(p.category) != _cat) continue;
        final o = _Offer(store, info, p);
        if (_myLat != null && _myLng != null) {
          o.km = Geolocator.distanceBetween(_myLat!, _myLng!, store.lat, store.lng) / 1000;
        }
        byName.putIfAbsent(n, () => _Group(p.name)).offers.add(o);
      }
    }
    final groups = byName.values.toList();
    for (final g in groups) {
      // pinakamurang presyo muna
      g.offers.sort((a, b) => a.product.price.compareTo(b.product.price));
    }
    groups.sort((a, b) => a.name.compareTo(b.name));
    setState(() {
      _groups = groups;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthService>().user?.fullName.split(' ').first ?? '';
    return SafeArea(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          color: AppColors.primary,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, $name!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _q,
              textInputAction: TextInputAction.search,
              onChanged: (_) => _search(), // live na naghahanap habang nagta-type
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search: fertilizer, urea, seeds...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
              ),
            ),
            const SizedBox(height: 10),
            // Mabilis na hanapin ayon sa uri ng produkto
            CategoryChips(
              selected: _cat,
              onGreen: true,
              onChanged: (v) {
                setState(() => _cat = v);
                _search();
              },
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          ErrorBanner(_error!),
                          TextButton(onPressed: _loadCatalog, child: const Text('Try again')),
                        ]),
                      ),
                    )
                  : _searched && _groups.isEmpty
              ? Center(
                  child: Text(CatalogRepository.instance.stores.isEmpty
                      ? 'No stores have listed products yet.'
                      : 'No results found. Try a different keyword.'))
              : RefreshIndicator(
                  onRefresh: _loadCatalog,
                  child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _groups.length,
                  itemBuilder: (_, i) => _ProductGroupCard(_groups[i]),
                  ),
                ),
        ),
      ]),
    );
  }
}

/// Isang card bawat produkto, nakalista ang bawat store na meron nito
/// kasama ang presyo at stock.
class _ProductGroupCard extends StatelessWidget {
  final _Group g;
  const _ProductGroupCard(this.g);

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final n = g.offers.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ProductThumb(name: g.name, size: 60),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Available in $n ${n == 1 ? 'store' : 'stores'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 6),
          for (var i = 0; i < n; i++) ...[
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.line, width: i == 0 ? 0 : 1))),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _offerRow(g.offers[i], money, best: i == 0 && n > 1),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _offerRow(_Offer o, NumberFormat money, {required bool best}) {
    final p = o.product;
    final status = p.stock == 0 ? 'out' : (p.stock < 10 ? 'low' : 'in');
    final st = o.info.status(StoreInfo.phNow());
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.storefront, size: 16, color: AppColors.muted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(o.store.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            if (best) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.light.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                child: const Text('Lowest price',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(
              [p.unit, if (o.km != null) '${o.km!.toStringAsFixed(1)} km away'].join(' • '),
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          Text(st.text,
              style: TextStyle(
                  fontSize: 11,
                  color: st.open ? AppColors.primary : (o.info.hasHours ? AppColors.error : AppColors.muted))),
        ]),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(money.format(p.price),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        StockBadge(status),
        const SizedBox(height: 2),
        Text(p.stock == 0 ? 'No stock' : '${p.stock} in stock',
            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ]),
    ]);
  }
}

class ProductTile extends StatelessWidget {
  final Map p;
  const ProductTile(this.p, {super.key});

  @override
  Widget build(BuildContext context) {
    final updated = DateTime.tryParse('${p['last_updated']}');
    final money = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${p['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            StockBadge('${p['stock_status']}'),
          ]),
          if ('${p['brand']}'.isNotEmpty) Text('${p['brand']}', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text('${money.format(double.parse('${p['price']}'))} / ${p['unit']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.storefront, size: 16, color: AppColors.muted),
            const SizedBox(width: 4),
            Expanded(child: Text('${p['store_name']} • ${p['distance_km']} km')),
          ]),
          if (updated != null)
            Text('Updated: ${DateFormat('MMM d, h:mm a').format(updated)}${p['is_stale'] == true ? '  (outdated)' : ''}',
                style: TextStyle(fontSize: 12, color: p['is_stale'] == true ? AppColors.warning : AppColors.muted)),
        ]),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return ProfileSettings(onLogout: () async {
      await auth.logout();
      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    });
  }
}
