import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../services/admin_service.dart';
import 'admin_widgets.dart';

/// Reports and simple charts, all from real database counts.
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = AdminService();
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & analytics')),
      body: AsyncView<Map<String, dynamic>>(
        load: svc.analytics,
        builder: (context, d, reload) {
          final claims = Map<String, dynamic>.from(d['claims_by_status'] as Map? ?? {});
          final months = (d['stores_by_month'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
          final cats = (d['products_by_category'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
          final users = Map<String, dynamic>.from(d['users'] as Map? ?? {});
          final activity = (d['store_activity'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();

          final approved = asInt(claims['approved']);
          final pending = asInt(claims['pending']);
          final rejected = asInt(claims['rejected']);
          final claimMax = [approved, pending, rejected, 1].reduce((a, b) => a > b ? a : b);
          final monthMax = months.fold<int>(1, (m, e) => asInt(e['count']) > m ? asInt(e['count']) : m);
          final catTotal = cats.fold<int>(0, (m, e) => m + asInt(e['count']));
          final owners = asInt(users['owners']);
          final viewers = asInt(users['viewers']);

          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.all(14), children: [
              const SectionTitle('Store applications'),
              AdminCard(
                child: Column(children: [
                  _HBar(label: 'Approved', value: approved, max: claimMax, color: AppColors.primary),
                  _HBar(label: 'Pending', value: pending, max: claimMax, color: AppColors.warning),
                  _HBar(label: 'Rejected', value: rejected, max: claimMax, color: AppColors.error),
                ]),
              ),
              const SectionTitle('Stores added (last 6 months)'),
              AdminCard(
                child: SizedBox(
                  height: 170,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    for (final m in months)
                      Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text('${asInt(m['count'])}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            height: 110 * (asInt(m['count']) / monthMax) + 3,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                          ),
                          const SizedBox(height: 6),
                          Text(_monthLabel('${m['month']}'), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ]),
                      ),
                  ]),
                ),
              ),
              const SectionTitle('Product category distribution'),
              AdminCard(
                child: cats.isEmpty || catTotal == 0
                    ? const EmptyState(icon: Icons.pie_chart_outline, title: 'No products listed yet')
                    : Column(children: [
                        for (final c in cats)
                          _HBar(
                            label: '${c['name']}',
                            value: asInt(c['count']),
                            max: cats.fold<int>(1, (m, e) => asInt(e['count']) > m ? asInt(e['count']) : m),
                            color: const Color(0xFF00897B),
                            suffix: ' (${(asInt(c['count']) * 100 / catTotal).round()}%)',
                          ),
                      ]),
              ),
              const SectionTitle('Registered users'),
              AdminCard(
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _Tile(label: 'Store owners', value: '$owners', color: const Color(0xFF558B2F))),
                    const SizedBox(width: 10),
                    Expanded(child: _Tile(label: 'Viewers', value: '$viewers', color: const Color(0xFF6A1B9A))),
                  ]),
                  const SizedBox(height: 10),
                  if (owners + viewers > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 12,
                        child: Row(children: [
                          if (owners > 0) Expanded(flex: owners, child: Container(color: const Color(0xFF558B2F))),
                          if (viewers > 0) Expanded(flex: viewers, child: Container(color: const Color(0xFF6A1B9A))),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _Tile(label: 'New (30 days)', value: '${asInt(users['new_30d'])}', color: AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _Tile(label: 'Suspended', value: '${asInt(users['suspended'])}', color: AppColors.error)),
                  ]),
                ]),
              ),
              const SectionTitle('Store activity report'),
              if (activity.isEmpty)
                const AdminCard(child: EmptyState(icon: Icons.storefront_outlined, title: 'No approved stores yet', subtitle: 'Activity appears after a store is approved.'))
              else
                for (final s in activity)
                  AdminCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                        StatusBadge(asInt(s['is_active']) == 1 ? 'active' : 'inactive'),
                      ]),
                      const SizedBox(height: 4),
                      Text('${asInt(s['product_count'])} products • ${asInt(s['low_stock'])} low stock • ${asInt(s['out_of_stock'])} out of stock',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      Text('Last price/stock update: ${hasValue(s['last_update']) ? fmtDate(s['last_update']) : 'never'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ]),
                  ),
              const SizedBox(height: 12),
            ]),
          );
        },
      ),
    );
  }

  static String _monthLabel(String ym) {
    final d = DateTime.tryParse('$ym-01');
    return d == null ? ym : DateFormat('MMM').format(d);
  }
}

class _HBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final String suffix;
  const _HBar({required this.label, required this.value, required this.max, required this.color, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    final frac = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 104, child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Stack(children: [
            Container(height: 14, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8))),
            FractionallySizedBox(
              widthFactor: frac,
              child: Container(height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Text('$value$suffix', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Tile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]),
    );
  }
}
