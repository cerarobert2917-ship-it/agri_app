import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../widgets/user_avatar.dart';

/// Profile at settings screen. Ginagamit ng Customer at ng Store Owner.
/// [badge] = dagdag na label sa ilalim ng pangalan (hal. status ng store).
class ProfileSettings extends StatefulWidget {
  final String? badge;
  final VoidCallback onLogout;
  const ProfileSettings({super.key, this.badge, required this.onLogout});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  static const _appName = 'AgriMamView';
  static const _appVersion = '1.0.0';
  final _store = const FlutterSecureStorage();

  Map<String, dynamic>? _p;
  String? _loadError;
  bool _alerts = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final p = await context.read<AuthService>().fetchProfile();
      final a = await _store.read(key: 'pref_price_alerts');
      if (!mounted) return;
      setState(() {
        _p = p;
        _alerts = a != 'off';
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save(Map<String, dynamic> changes) async {
    try {
      final p = await context.read<AuthService>().updateProfile(changes);
      if (!mounted) return;
      setState(() => _p = p);
      _toast('Profile updated.');
    } catch (e) {
      _toast('$e');
    }
  }

  Future<void> _editName() async {
    final v = await showDialog<String>(
      context: context,
      builder: (_) => _PromptDialog(
        title: 'Edit name',
        label: 'Full name',
        initial: '${_p!['full_name']}',
        icon: Icons.person_outline,
        validator: (s) {
          final t = (s ?? '').trim();
          if (t.length < 2) return 'Enter your name (at least 2 characters)';
          if (t.length > 100) return 'Name is too long';
          return null;
        },
      ),
    );
    if (v != null && v != '${_p!['full_name']}') await _save({'full_name': v});
  }

  Future<void> _editPhone() async {
    final v = await showDialog<String>(
      context: context,
      builder: (_) => _PromptDialog(
        title: 'Phone number',
        label: '09XXXXXXXXX',
        hint: 'Leave blank to remove',
        initial: '${_p!['phone'] ?? ''}',
        icon: Icons.phone_outlined,
        keyboard: TextInputType.phone,
        validator: (s) =>
            (s == null || s.trim().isEmpty) ? null : Validators.phone(s),
      ),
    );
    if (v != null && v != '${_p!['phone'] ?? ''}') await _save({'phone': v});
  }

  Future<void> _changePassword() async {
    final ok = await showDialog<bool>(
        context: context, builder: (_) => const _PasswordDialog());
    if (ok == true) _toast('Password changed.');
  }

  Future<void> _setAlerts(bool v) async {
    setState(() => _alerts = v);
    await _store.write(key: 'pref_price_alerts', value: v ? 'on' : 'off');
  }

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (yes == true) widget.onLogout();
  }

  void _showHelp() {
    const faqs = [
      (
        'How do I find a product?',
        'Open the Search tab and type a product, like "urea" or "palay". You will see every store that has it, with price and stock, cheapest first.'
      ),
      (
        'How do I see where a store is?',
        'Open the Map tab. Hover (or tap) a pin to see the store name, then tap it to see its products, stock, prices and hours.'
      ),
      (
        'What does "Low Stock" mean?',
        'The store has fewer than 10 left. Call or visit early so you do not miss out.'
      ),
      (
        'How do I know if a store is open?',
        'Each store shows Open or Closed based on its hours in Philippine time, plus the full weekly schedule.'
      ),
      (
        'Need more help?',
        'Ask AgriBot in the AgriBot tab about prices, stock and stores in Mamburao.'
      ),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const Text('Help & FAQ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final f in faqs)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(f.$1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$2,
                        style: const TextStyle(
                            color: AppColors.muted, height: 1.4))
                  ],
                ),
            ]),
      ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms & Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'What we collect\n'
            'Your name, email and account type (store owners also give a contact phone number). If you allow it, your device location is used only to show nearby stores and distances.\n\n'
            'How it is used\n'
            'To sign you in, show products and stores in Mamburao, and let store owners manage their listings. We do not sell your data.\n\n'
            'Prices and stock\n'
            'Prices, stock and store hours are provided by the stores and may change without notice.\n\n'
            'Your control\n'
            'You can edit your details in Profile at any time.',
            style: TextStyle(height: 1.4),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: _appName,
      applicationVersion: _appVersion,
      applicationIcon:
          const Icon(Icons.eco, color: AppColors.primary, size: 40),
      children: const [
        SizedBox(height: 8),
        Text(
            'Find fertilizer, seeds and farm supplies from stores in Mamburao, Occidental Mindoro.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }
    final p = _p;
    if (p == null) return const Center(child: CircularProgressIndicator());

    final name = '${p['full_name']}';
    final phone = '${p['phone'] ?? ''}';
    final google = p['google_linked'] == true;
    final roleLabel = switch ('${p['role']}') {
      'store_owner' => 'Store Owner',
      'admin' => 'Admin',
      _ => 'Viewer',
    };

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              // --- header
              Center(
                child: EditableAvatar(
                  name: name,
                  avatarPath: p['avatar_url'],
                  onChanged: (profile) => setState(() => _p = profile),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800))),
              const SizedBox(height: 2),
              Center(
                  child: Text('${p['email']}',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 13))),
              const SizedBox(height: 8),
              Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                _pill(roleLabel),
                if (widget.badge != null) _pill(widget.badge!),
              ]),
              const SizedBox(height: 22),

              _Section('Account', [
                _Tile(Icons.person_outline, 'Full name', name,
                    onTap: _editName),
                // Phone number: para sa Store Owner/Admin lang. Wala nito ang Viewer.
                if (roleLabel != 'Viewer')
                  _Tile(Icons.phone_outlined, 'Phone number',
                      phone.isEmpty ? 'Add phone number' : phone,
                      onTap: _editPhone),
                _Tile(Icons.mail_outline, 'Email', '${p['email']}'),
                google
                    ? const _Tile(
                        Icons.lock_outline, 'Password', 'Signed in with Google')
                    : _Tile(Icons.lock_outline, 'Change password',
                        'Update your password',
                        onTap: _changePassword),
              ]),
              _Section('Preferences', [
                _Tile(Icons.notifications_none, 'Price alerts',
                    'Notify me about price changes',
                    trailing: Switch(
                        value: _alerts,
                        activeColor: AppColors.primary,
                        onChanged: _setAlerts)),
              ]),
              _Section('Support', [
                _Tile(Icons.help_outline, 'Help & FAQ',
                    'Answers to common questions',
                    onTap: _showHelp),
                _Tile(Icons.privacy_tip_outlined, 'Terms & Privacy',
                    'How your data is used',
                    onTap: _showTerms),
                _Tile(Icons.info_outline, 'About', '$_appName v$_appVersion',
                    onTap: _showAbout),
              ]),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              ),
            ]),
      ),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted)),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line)),
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, indent: 56, color: AppColors.line),
              children[i],
            ],
          ]),
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _Tile(this.icon, this.title, this.subtitle,
      {this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.muted)
              : null),
    );
  }
}

/// Prompt na may isang text field (pangalan, phone).
class _PromptDialog extends StatefulWidget {
  final String title, label, initial;
  final String? hint;
  final IconData icon;
  final TextInputType keyboard;
  final String? Function(String?) validator;
  const _PromptDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.icon,
    required this.validator,
    this.hint,
    this.keyboard = TextInputType.text,
  });

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final _c = TextEditingController(text: widget.initial);
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    if (_key.currentState!.validate()) Navigator.pop(context, _c.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _key,
        child: TextFormField(
          controller: _c,
          autofocus: true,
          keyboardType: widget.keyboard,
          validator: widget.validator,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: Icon(widget.icon)),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

/// Prompt para sa pagpapalit ng password.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  final _key = GlobalKey<FormState>();
  bool _show = false, _busy = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().changePassword(_old.text, _new.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_show ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _show = !_show),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!,
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            TextFormField(
              controller: _old,
              obscureText: !_show,
              decoration: _dec('Current password'),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Enter your current password'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _new,
              obscureText: !_show,
              decoration: _dec('New password'),
              validator: Validators.password,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirm,
              obscureText: !_show,
              decoration: _dec('Confirm new password'),
              validator: (v) =>
                  v != _new.text ? 'Passwords do not match' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
