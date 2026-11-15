import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../services/admin_service.dart';
import '../../widgets/common.dart';
import 'admin_widgets.dart';

/// Store details + its products (read-only) + activate / deactivate.
class StoreDetailScreen extends StatefulWidget {
  final int storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final _svc = AdminService();
  int _tick = 0;

  Future<void> _toggle(Map<String, dynamic> s) async {
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
      await _svc.setStoreActive(widget.storeId, !active);
      if (!mounted) return;
      toast(context, active ? 'Store deactivated.' : 'Store activated.');
      setState(() => _tick++);
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  String _statusOf(Map<String, dynamic> s) {
    if (s['owner_id'] != null) return 'approved';
    final c = s['last_claim'];
    if (c is Map) {
      if (c['status'] == 'pending') return 'pending';
      if (c['status'] == 'rejected') return 'rejected';
    }
    return 'unclaimed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store details')),
      body: AsyncView<Map<String, dynamic>>(
        loadKey: _tick,
        load: () => _svc.storeDetail(widget.storeId),
        builder: (context, s, reload) {
          final inactive = asInt(s['is_active']) == 0;
          final products = (s['products'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
          final claim = s['last_claim'] is Map ? Map<String, dynamic>.from(s['last_claim']) : null;
          final address = [s['address'], s['barangay']].where(hasValue).join(', ');
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(14), children: [
              AdminCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    StoreImage(name: '${s['name']}', photoUrl: s['photo_url'], size: 84),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${s['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          StatusBadge(_statusOf(s)),
                          StatusBadge(inactive ? 'inactive' : 'active'),
                        ]),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  InfoRow(icon: Icons.place_outlined, label: 'Address', value: address),
                  InfoRow(icon: Icons.my_location, label: 'Coordinates', value: '${s['latitude']}, ${s['longitude']}'),
                  if (hasValue(s['description'])) InfoRow(icon: Icons.notes, label: 'Description', value: '${s['description']}'),
                  if (hasValue(s['contact_number'])) InfoRow(icon: Icons.phone_outlined, label: 'Contact number', value: '${s['contact_number']}'),
                  if (hasValue(s['opening_hours'])) InfoRow(icon: Icons.schedule, label: 'Opening hours', value: '${s['opening_hours']}'),
                  InfoRow(icon: Icons.event, label: 'Added', value: fmtDate(s['created_at'])),
                ]),
              ),
              AdminCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Owner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  if (hasValue(s['owner_name'])) ...[
                    InfoRow(icon: Icons.person_outline, label: 'Name', value: '${s['owner_name']}'),
                    InfoRow(icon: Icons.mail_outline, label: 'Email', value: '${s['owner_email']}'),
                    if (hasValue(s['owner_phone'])) InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: '${s['owner_phone']}'),
                  ] else
                    const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('No owner yet. Owners can claim this store from the app.', style: TextStyle(color: AppColors.muted, fontSize: 13))),
                  if (claim != null) ...[
                    const Divider(height: 22),
                    const Text('Latest application', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      StatusBadge('${claim['status']}'),
                      StatusBadge('${claim['permit_status']}', label: 'Permit: ${claim['permit_status']}'),
                      StatusBadge('${claim['storefront_status']}', label: 'Storefront: ${claim['storefront_status']}'),
                    ]),
                    if (hasValue(claim['reviewed_at']))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Reviewed by ${claim['reviewed_by_name'] ?? 'admin'} on ${fmtDate(claim['reviewed_at'])}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ),
                    if (hasValue(claim['rejection_reason']))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Reason: ${claim['rejection_reason']}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                      ),
                  ],
                ]),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _toggle(s),
                  icon: Icon(inactive ? Icons.check_circle_outline : Icons.block),
                  label: Text(inactive ? 'Activate store' : 'Deactivate store'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: inactive ? AppColors.primary : AppColors.error,
                    side: BorderSide(color: inactive ? AppColors.primary : AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionTitle('Products (${products.length})'),
              const Text('Read-only. The store owner manages prices and stock.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 10),
              if (products.isEmpty)
                const AdminCard(child: EmptyState(icon: Icons.inventory_2_outlined, title: 'No products listed yet'))
              else
                for (final p in products) _ProductLine(p),
              const SizedBox(height: 12),
            ]),
          );
        },
      ),
    );
  }
}

class _ProductLine extends StatelessWidget {
  final Map<String, dynamic> p;
  const _ProductLine(this.p);

  @override
  Widget build(BuildContext context) {
    final hidden = asInt(p['is_hidden']) == 1;
    return AdminCard(
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        ProductImage(name: '${p['name']}', imageUrl: p['image_url'], size: 52, dimmed: hidden),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${p['category_name']} • ${peso(p['price'])} / ${p['unit']}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              StockBadge(stockStatus(p)),
              if (hidden) const StatusBadge('hidden'),
            ]),
          ]),
        ),
        Text('${asInt(p['stock_quantity'])}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
