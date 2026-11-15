import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/helpers.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/owner_service.dart';
import '../widgets/common.dart';
import '../widgets/product_row.dart';
import '../widgets/store_map.dart';
import 'owner_map_tab.dart';
import 'owner_products_screen.dart';
import 'owner_profile_tab.dart';
import 'owner_claim_screen.dart';
import 'owner_store_tab.dart';
import 'product_form_screen.dart';

class OwnerHome extends StatefulWidget {
  final String? storeStatus;
  const OwnerHome({super.key, this.storeStatus});

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  final _svc = OwnerService();
  final _pin = PinController(AppConfig.defaultLat, AppConfig.defaultLng);
  int _tab = 0;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _store;
  List<Map<String, dynamic>> _products = [];

  late final OwnerActions _actions = OwnerActions(
    setPrice: (p, v) => _run(() => _svc.quickUpdate(asInt(p['id']), price: v)),
    setStock: (p, n) => _run(() => _svc.quickUpdate(asInt(p['id']), stock: n)),
    edit: (p) => _openForm(p),
    menu: _showMenu,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final store = await _svc.getStore();
      final approved = store != null && '${store['status']}' == 'approved';
      final products =
          approved ? await _svc.products() : <Map<String, dynamic>>[];
      if (!mounted) return;
      if (store != null) {
        final la = asDouble(store['latitude']);
        final ln = asDouble(store['longitude']);
        // ibalik lang ang pin kapag nagbago ang naka-save na lokasyon
        if (la != _pin.refLat || ln != _pin.refLng) _pin.resetRef(la, ln);
      }
      setState(() {
        _store = store;
        _products = products;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load(silent: true);
    } catch (e) {
      if (mounted) _toast(e.toString());
    }
  }

  Future<void> _openForm([Map<String, dynamic>? product]) async {
    final saved = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)));
    if (saved == true) {
      await _load(silent: true);
      if (mounted) _toast('Product saved.');
    }
  }

  // long-press sa produkto: edit, available, burahin
  void _showMenu(Map<String, dynamic> p) {
    final available = '${p['is_available']}' == '1';
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${p['name']}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700))),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit product'),
            onTap: () {
              Navigator.pop(ctx);
              _openForm(p);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_outlined),
            title: const Text('Visible to viewers'),
            value: available,
            activeColor: AppColors.primary,
            onChanged: (v) {
              Navigator.pop(ctx);
              _run(() => _svc.quickUpdate(asInt(p['id']), available: v));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(p);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this product?'),
        content:
            Text('This will delete "${p['name']}". This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) await _run(() => _svc.deleteProduct(asInt(p['id'])));
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (mounted)
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget? _statusBanner() {
    final s = '${_store?['status']}';
    if (s == 'approved') return null;
    final rejected = s == 'rejected';
    final color = rejected ? AppColors.error : AppColors.warning;
    final text = rejected
        ? 'Store rejected: ${_store?['rejection_reason'] ?? 'no reason given'}. Edit it in the Store tab and resubmit.'
        : 'Waiting for admin approval. Viewers will only see your products once approved.';
    return Container(
      width: double.infinity,
      color: color.withOpacity(0.15),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Icon(rejected ? Icons.error_outline : Icons.hourglass_top,
            color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_error != null && _store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Store Owner'), actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ]),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ErrorBanner(_error!),
            ElevatedButton(onPressed: _load, child: const Text('Try again')),
          ]),
        ),
      );
    }

    // wala pang approved na store: mag-claim muna (o hintayin ang approval ng admin)
    if (_store == null || '${_store!['status']}' != 'approved') {
      return OwnerClaimScreen(
          claim: _store, onChanged: () => _load(silent: true));
    }

    final banner = _statusBanner();
    final pages = <Widget>[
      OwnerMapTab(
          store: _store!, products: _products, pin: _pin, actions: _actions),
      OwnerProductsScreen(
        products: _products,
        actions: _actions,
        onAdd: () => _openForm(),
        onRefresh: () => _load(silent: true),
      ),
      OwnerStoreTab(
        store: _store!,
        pin: _pin,
        onSaved: () => _load(silent: true),
        onShowMap: () => setState(() => _tab = 0),
      ),
      OwnerProfileTab(storeStatus: '${_store!['status']}', onLogout: _logout),
    ];

    return Scaffold(
      body: Column(children: [
        if (banner != null) SafeArea(bottom: false, child: banner),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: banner != null,
            child: IndexedStack(index: _tab, children: pages),
          ),
        ),
      ]),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line))),
        child: NavigationBar(
          height: 64,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map'),
            NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Products'),
            NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Store'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
