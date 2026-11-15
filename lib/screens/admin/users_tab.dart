import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../services/admin_service.dart';
import 'admin_widgets.dart';

/// User management for the two mobile roles: Store Owners and Viewers.
class AdminUsersTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;
  const AdminUsersTab({super.key, required this.refreshKey, required this.onChanged});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _svc = AdminService();
  static const _filters = ['All', 'Active', 'Suspended'];
  String _role = 'store_owner';
  String _filter = 'All';
  String _q = '';

  bool _match(Map<String, dynamic> u) {
    if (_filter != 'All' && '${u['status']}' != _filter.toLowerCase()) return false;
    if (_q.isEmpty) return true;
    return '${u['full_name']} ${u['email']} ${u['phone'] ?? ''} ${u['store_name'] ?? ''}'.toLowerCase().contains(_q);
  }

  Future<void> _toggle(Map<String, dynamic> u, Future<void> Function() reload) async {
    final suspend = '${u['status']}' == 'active';
    final ok = await confirmDialog(
      context,
      title: suspend ? 'Suspend account?' : 'Activate account?',
      message: suspend
          ? '${u['full_name']} will be signed out and will not be able to log in until you activate the account again.'
          : '${u['full_name']} will be able to log in again.',
      confirmLabel: suspend ? 'Suspend' : 'Activate',
      danger: suspend,
    );
    if (!ok) return;
    try {
      await _svc.setUserStatus(asInt(u['id']), suspend ? 'suspended' : 'active');
      if (mounted) toast(context, suspend ? 'Account suspended.' : 'Account activated.');
      await reload();
      widget.onChanged();
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Map<String, dynamic>>>(
      loadKey: '$_role|${widget.refreshKey}',
      load: () => _svc.users(_role),
      builder: (context, all, reload) {
        final list = all.where(_match).toList();
        final owners = _role == 'store_owner';
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(14), children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'store_owner', icon: Icon(Icons.agriculture), label: Text('Store owners')),
                  ButtonSegment(value: 'customer', icon: Icon(Icons.visibility_outlined), label: Text('Viewers')),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() {
                  _role = s.first;
                  _filter = 'All';
                }),
              ),
            ),
            const SizedBox(height: 12),
            SearchField(hint: 'Search name, email or phone...', onChanged: (v) => setState(() => _q = v.trim().toLowerCase())),
            const SizedBox(height: 10),
            FilterChips(options: _filters, selected: _filter, onSelected: (v) => setState(() => _filter = v)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('${list.length} of ${all.length} ${owners ? 'store owners' : 'viewers'}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
            if (list.isEmpty)
              EmptyState(
                icon: Icons.people_outline,
                title: all.isEmpty ? 'No ${owners ? 'store owners' : 'viewers'} registered yet' : 'No accounts match your filters',
              )
            else
              for (final u in list) _UserCard(user: u, owner: owners, onToggle: () => _toggle(u, reload)),
          ]),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool owner;
  final VoidCallback onToggle;
  const _UserCard({required this.user, required this.owner, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final active = '${user['status']}' == 'active';
    final name = '${user['full_name']}';
    return AdminCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.light,
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text('${user['email']}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            if (hasValue(user['phone'])) Text('${user['phone']}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            if (owner)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(hasValue(user['store_name']) ? 'Store: ${user['store_name']}' : 'No store yet', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
            Text('Joined ${fmtShortDate(user['created_at'])}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 6),
            StatusBadge(active ? 'active' : 'suspended'),
          ]),
        ),
        TextButton(
          onPressed: onToggle,
          style: TextButton.styleFrom(foregroundColor: active ? AppColors.error : AppColors.primary),
          child: Text(active ? 'Suspend' : 'Activate'),
        ),
      ]),
    );
  }
}
