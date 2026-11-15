import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/user_avatar.dart';
import 'admin_widgets.dart';
import 'dashboard_tab.dart' show ActivityTile;

/// Admin settings: profile, change password, activity logs, system settings, logout.
class AdminSettingsTab extends StatefulWidget {
  final void Function(String dest) onNavigate;
  const AdminSettingsTab({super.key, required this.onNavigate});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  int _tick = 0;

  Future<void> _editName(Map<String, dynamic> p) async {
    final ctrl = TextEditingController(text: '${p['full_name']}');
    final formKey = GlobalKey<FormState>();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
            validator: (s) {
              final t = (s ?? '').trim();
              if (t.length < 2) return 'Enter your name (at least 2 characters)';
              if (t.length > 100) return 'Name is too long';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (v == null || v == '${p['full_name']}' || !mounted) return;
    try {
      await context.read<AuthService>().updateProfile({'full_name': v});
      if (!mounted) return;
      toast(context, 'Profile updated.');
      setState(() => _tick++);
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> _changePassword() async {
    final old = TextEditingController(), neu = TextEditingController(), confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: old, obscureText: true, decoration: const InputDecoration(labelText: 'Current password'), validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null),
              const SizedBox(height: 10),
              TextFormField(controller: neu, obscureText: true, decoration: const InputDecoration(labelText: 'New password'), validator: Validators.password),
              const SizedBox(height: 10),
              TextFormField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password'), validator: (v) => v != neu.text ? 'Passwords do not match' : null),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AuthService>().changePassword(old.text, neu.text);
      if (mounted) toast(context, 'Password changed.');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context, title: 'Log out?', message: 'You will need to sign in again.', confirmLabel: 'Log out', danger: true);
    if (!ok || !mounted) return;
    await context.read<AuthService>().logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap, {Color? color}) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: color ?? AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color ?? AppColors.text)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.muted),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<Map<String, dynamic>>(
      loadKey: _tick,
      load: () => context.read<AuthService>().fetchProfile(),
      builder: (context, p, reload) {
        final name = '${p['full_name']}';
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(14), children: [
            AdminCard(
              child: Row(children: [
                EditableAvatar(
                  name: name,
                  avatarPath: p['avatar_url'],
                  size: 60,
                  radius: 30,
                  fontSize: 24,
                  badgeSize: 22,
                  onChanged: (_) => setState(() => _tick++),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('${p['email'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    const StatusBadge('active', label: 'Administrator'),
                  ]),
                ),
                IconButton(tooltip: 'Edit name', icon: const Icon(Icons.edit_outlined), onPressed: () => _editName(p)),
              ]),
            ),
            const SectionTitle('Account'),
            _tile(Icons.lock_outline, 'Change password', 'Use a strong password you do not use elsewhere', _changePassword),
            const SectionTitle('Administration'),
            _tile(Icons.history, 'Activity logs', 'Approvals, rejections and account changes', () => widget.onNavigate('logs')),
            _tile(Icons.bar_chart, 'Reports & analytics', 'Registrations, products and users', () => widget.onNavigate('reports')),
            _tile(Icons.settings_applications_outlined, 'System settings', 'Server status and app information',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSystemScreen()))),
            const SizedBox(height: 8),
            _tile(Icons.logout, 'Log out', 'Sign out of the admin panel', _logout, color: AppColors.error),
          ]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- activity logs
class AdminLogsScreen extends StatelessWidget {
  const AdminLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = AdminService();
    return Scaffold(
      appBar: AppBar(title: const Text('Activity logs')),
      body: AsyncView<List<Map<String, dynamic>>>(
        load: () => svc.logs(limit: 200),
        builder: (context, logs, reload) => RefreshIndicator(
          onRefresh: reload,
          child: logs.isEmpty
              ? ListView(children: const [EmptyState(icon: Icons.history, title: 'No admin activity yet', subtitle: 'Every approval, rejection and account change is recorded here.')])
              : ListView(padding: const EdgeInsets.all(14), children: [for (final l in logs) ActivityTile(l)]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- system settings
class AdminSystemScreen extends StatefulWidget {
  const AdminSystemScreen({super.key});

  @override
  State<AdminSystemScreen> createState() => _AdminSystemScreenState();
}

class _AdminSystemScreenState extends State<AdminSystemScreen> {
  final _svc = AdminService();
  int _tick = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System settings'), actions: [
        IconButton(tooltip: 'Check again', icon: const Icon(Icons.refresh), onPressed: () => setState(() => _tick++)),
      ]),
      body: AsyncView<Map<String, dynamic>>(
        loadKey: _tick,
        load: _svc.health,
        builder: (context, h, reload) => ListView(padding: const EdgeInsets.all(14), children: [
          AdminCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.cloud_done_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Server is online', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
              const SizedBox(height: 8),
              InfoRow(icon: Icons.schedule, label: 'Server time', value: fmtDate(h['time'])),
              InfoRow(icon: Icons.link, label: 'API address', value: AppConfig.baseUrl),
            ]),
          ),
          const AdminCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Application', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(height: 6),
              InfoRow(icon: Icons.apps, label: 'App', value: 'AgriMamView Admin Panel'),
              InfoRow(icon: Icons.tag, label: 'Version', value: '1.0.0'),
              InfoRow(icon: Icons.notifications_active_outlined, label: 'Application alerts', value: 'The bell refreshes every 30 seconds'),
            ]),
          ),
        ]),
      ),
    );
  }
}
