import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/helpers.dart';
import '../../widgets/common.dart' show cardShadow;
import '../../core/theme.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'admin_widgets.dart';

/// Dashboard: real counts from the database + recent admin activity.
class AdminDashboardTab extends StatelessWidget {
  final int refreshKey;
  final void Function(String dest) onNavigate;
  const AdminDashboardTab(
      {super.key, required this.refreshKey, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final svc = AdminService();
    final name = context.watch<AuthService>().user?.fullName ?? 'Admin';
    return AsyncView<Map<String, dynamic>>(
      loadKey: refreshKey,
      load: svc.dashboard,
      builder: (context, d, reload) {
        final pending = asInt(d['stores_pending']);
        final stockAlerts = asInt(d['products_low']) + asInt(d['products_out']);
        final activity = (d['recent_activity'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(children: [
                Image.asset('assets/images/agrimamview_logo.png',
                    width: 120, fit: BoxFit.contain),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, $name',
                            style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 19,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('AgriMamView Admin Panel',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 12.5)),
                      ]),
                ),
              ]),
            ),
            if (pending > 0)
              AdminCard(
                onTap: () => onNavigate('claims'),
                child: Row(children: [
                  const Icon(Icons.pending_actions,
                      color: AppColors.warningText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        '$pending store application${pending == 1 ? '' : 's'} waiting for review',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ]),
              ),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: StatCard.height,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10),
              children: [
                StatCard(
                    icon: Icons.storefront,
                    label: 'Registered stores',
                    value: '${asInt(d['stores_total'])}',
                    color: AppColors.primary,
                    onTap: () => onNavigate('stores')),
                StatCard(
                    icon: Icons.check_circle,
                    label: 'Approved stores',
                    value: '${asInt(d['stores_approved'])}',
                    color: const Color(0xFF1976D2),
                    onTap: () => onNavigate('stores')),
                StatCard(
                    icon: Icons.schedule,
                    label: 'Pending applications',
                    value: '$pending',
                    color: AppColors.warningText,
                    onTap: () => onNavigate('claims')),
                StatCard(
                    icon: Icons.cancel,
                    label: 'Rejected applications',
                    value: '${asInt(d['claims_rejected'])}',
                    color: AppColors.error,
                    onTap: () => onNavigate('claims')),
                StatCard(
                    icon: Icons.inventory_2,
                    label: 'Listed products',
                    value: '${asInt(d['products_total'])}',
                    color: const Color(0xFF00897B),
                    onTap: () => onNavigate('products')),
                StatCard(
                    icon: Icons.visibility,
                    label: 'Registered viewers',
                    value: '${asInt(d['viewers_total'])}',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => onNavigate('users')),
                StatCard(
                    icon: Icons.agriculture,
                    label: 'Store owners',
                    value: '${asInt(d['owners_total'])}',
                    color: const Color(0xFF558B2F),
                    onTap: () => onNavigate('users')),
                StatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Stock alerts',
                    value: '$stockAlerts',
                    color: const Color(0xFFEF6C00),
                    onTap: () => onNavigate('products')),
              ],
            ),
            const SizedBox(height: 22),
            const SectionTitle('Quick actions'),
            Row(children: [
              Expanded(
                  child: _Quick(
                      icon: Icons.inventory_2_outlined,
                      label: 'Products',
                      onTap: () => onNavigate('products'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _Quick(
                      icon: Icons.bar_chart,
                      label: 'Reports',
                      onTap: () => onNavigate('reports'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _Quick(
                      icon: Icons.history,
                      label: 'Logs',
                      onTap: () => onNavigate('logs'))),
            ]),
            const SizedBox(height: 22),
            SectionTitle('Recent admin activities',
                trailing: TextButton(
                    onPressed: () => onNavigate('logs'),
                    child: const Text('See all'))),
            if (activity.isEmpty)
              const AdminCard(
                  child: EmptyState(
                      icon: Icons.history,
                      title: 'No admin activity yet',
                      subtitle:
                          'Approvals, rejections and account changes will appear here.'))
            else
              for (final a in activity) ActivityTile(a),
            const SizedBox(height: 12),
          ]),
        );
      },
    );
  }
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Quick({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16), boxShadow: cardShadow),
          child: Column(children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

/// One row of the admin activity log.
class ActivityTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const ActivityTile(this.log, {super.key});

  IconData _icon(String a) {
    if (a.contains('approved') ||
        a.contains('activated') ||
        a.contains('restored') ||
        a.contains('verified')) return Icons.check_circle_outline;
    if (a.contains('rejected') ||
        a.contains('suspended') ||
        a.contains('deactivated') ||
        a.contains('hidden')) return Icons.block;
    if (a.contains('created')) return Icons.add_circle_outline;
    return Icons.history;
  }

  Color _color(String a) {
    if (a.contains('rejected') ||
        a.contains('suspended') ||
        a.contains('deactivated') ||
        a.contains('hidden')) return AppColors.error;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final action = '${log['action']}';
    return AdminCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Icon(_icon(action), color: _color(action)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                hasValue(log['details'])
                    ? '${log['details']}'
                    : action.replaceAll('_', ' '),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${log['admin_name']} • ${fmtDate(log['created_at'])}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
      ]),
    );
  }
}
