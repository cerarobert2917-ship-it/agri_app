import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/admin_service.dart';
import 'admin/claims_screen.dart';
import 'admin/dashboard_tab.dart';
import 'admin/products_screen.dart';
import 'admin/reports_screen.dart';
import 'admin/settings_tab.dart';
import 'admin/stores_tab.dart';
import 'admin/users_tab.dart';

export 'admin/claims_screen.dart' show AdminClaimsScreen;

/// Admin shell: bottom navigation (Dashboard, Stores, Users, Settings) + notification bell.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  static const _titles = ['Dashboard', 'Stores', 'Users', 'Settings'];
  final _svc = AdminService();
  int _index = 0;
  int _pending = 0;
  int _tick = 0; // bumped after admin actions so tabs reload
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCount();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadCount());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCount() async {
    try {
      final c = await _svc.claims('pending');
      if (mounted) setState(() => _pending = c.length);
    } catch (_) {}
  }

  void _refreshAll() {
    if (!mounted) return;
    setState(() => _tick++);
    _loadCount();
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _refreshAll();
  }

  void _go(String dest) {
    switch (dest) {
      case 'stores':
        setState(() => _index = 1);
        break;
      case 'users':
        setState(() => _index = 2);
        break;
      case 'claims':
        _push(const AdminClaimsScreen());
        break;
      case 'products':
        _push(const AdminProductsScreen());
        break;
      case 'reports':
        _push(const AdminReportsScreen());
        break;
      case 'logs':
        _push(const AdminLogsScreen());
        break;
    }
  }

  Widget _bell() {
    return Stack(clipBehavior: Clip.none, children: [
      IconButton(
        tooltip: 'Store applications',
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => _go('claims'),
      ),
      if (_pending > 0)
        Positioned(
          right: 4,
          top: 4,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(9)),
              child: Text(_pending > 99 ? '99+' : '$_pending',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      AdminDashboardTab(refreshKey: _tick, onNavigate: _go),
      AdminStoresTab(refreshKey: _tick, onChanged: _refreshAll),
      AdminUsersTab(refreshKey: _tick, onChanged: _refreshAll),
      AdminSettingsTab(onNavigate: _go),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index], style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [_bell()],
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Stores'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
