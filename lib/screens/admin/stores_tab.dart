import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../services/admin_service.dart';
import 'add_store_screen.dart';
import 'admin_widgets.dart';
import 'store_detail_screen.dart';

/// Store management: search, status filters, cards, view + activate/deactivate.
class AdminStoresTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;
  const AdminStoresTab({super.key, required this.refreshKey, required this.onChanged});

  @override
  State<AdminStoresTab> createState() => _AdminStoresTabState();
}

class _AdminStoresTabState extends State<AdminStoresTab> {
  final _svc = AdminService();
  static const _filters = ['All', 'Approved', 'Pending', 'Rejected', 'Unclaimed', 'Inactive'];
  String _filter = 'All';
  String _q = '';

  bool _match(Map<String, dynamic> s) {
    final inactive = asInt(s['is_active']) == 0;
    switch (_filter) {
      case 'Inactive':
        if (!inactive) return false;
        break;
      case 'All':
        break;
      default:
        if ('${s['status']}' != _filter.toLowerCase()) return false;
    }
    if (_q.isEmpty) return true;
    final hay = '${s['name']} ${s['address']} ${s['barangay']} ${s['owner_name']}'.toLowerCase();
    return hay.contains(_q);
  }

  Future<void> _toggle(Map<String, dynamic> s, Future<void> Function() reload) async {
    final active = asInt(s['is_active']) == 1;
    final ok = await confirmDialog(
      context,
      title: active ? 'Deactivate store?' : 'Activate store?',
      message: active
          ? '"${s['name']}" and its products will be hidden from viewers until you activate it again.'
          : '"${s['name']}" will be visible to viewers again.',
      confirmLabel: active ? 'Deactivate' : 'Activate',
      danger: active,
    );
    if (!ok) return;
    try {
      await _svc.setStoreActive(asInt(s['id']), !active);
      if (mounted) toast(context, active ? 'Store deactivated.' : 'Store activated.');
      await reload();
      widget.onChanged();
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> _open(Map<String, dynamic> s, Future<void> Function() reload) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(storeId: asInt(s['id']))));
    await reload();
    widget.onChanged();
  }

  Future<void> _add(Future<void> Function() reload) async {
    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddStoreScreen()));
    if (added == true) {
      await reload();
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Map<String, dynamic>>>(
      loadKey: widget.refreshKey,
      load: _svc.stores,
      builder: (context, all, reload) {
        final list = all.where(_match).toList();
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(14), children: [
            Row(children: [
              const Expanded(child: SectionTitle('Stores management')),
              ElevatedButton.icon(
                onPressed: () => _add(reload),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add store'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
              ),
            ]),
            SearchField(hint: 'Search store, address or owner...', onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
            const SizedBox(height: 10),
            FilterChips(options: _filters, selected: _filter, onSelected: (v) => setState(() => _filter = v)),
            const SizedBox(height: 12),
            if (list.isEmpty)
              EmptyState(
                icon: Icons.storefront_outlined,
                title: all.isEmpty ? 'No stores yet' : 'No stores match your filters',
                subtitle: all.isEmpty ? 'Tap "Add store" to create the first one.' : 'Try a different search or status.',
              )
            else
              for (final s in list) _StoreCard(store: s, onView: () => _open(s, reload), onToggle: () => _toggle(s, reload)),
          ]),
        );
      },
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Map<String, dynamic> store;
  final VoidCallback onView;
  final VoidCallback onToggle;
  const _StoreCard({required this.store, required this.onView, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final inactive = asInt(store['is_active']) == 0;
    final owner = hasValue(store['owner_name']) ? '${store['owner_name']}' : 'No owner yet';
    final address = [store['address'], store['barangay']].where(hasValue).join(', ');
    return AdminCard(
      onTap: onView,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Opacity(opacity: inactive ? 0.5 : 1, child: StoreImage(name: '${store['name']}', photoUrl: store['photo_url'], size: 72)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${store['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(address.isEmpty ? '-' : address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Expanded(child: Text('$owner • ${asInt(store['product_count'])} products', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              StatusBadge('${store['status']}'),
              StatusBadge(inactive ? 'inactive' : 'active'),
            ]),
          ]),
        ),
        Column(children: [
          IconButton(tooltip: 'View details', icon: const Icon(Icons.visibility_outlined, color: AppColors.primary), onPressed: onView),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            onSelected: (v) => v == 'view' ? onView() : onToggle(),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('View details & products')),
              PopupMenuItem(value: 'toggle', child: Text(inactive ? 'Activate store' : 'Deactivate store')),
            ],
          ),
        ]),
      ]),
    );
  }
}
