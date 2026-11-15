import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../core/theme.dart';
import '../../services/admin_service.dart';
import 'admin_widgets.dart';

/// Store applications ("notifications"): All / Pending / Approved / Rejected.
class AdminClaimsScreen extends StatelessWidget {
  const AdminClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const _ClaimsBody(),
    );
  }
}

class _ClaimsBody extends StatefulWidget {
  const _ClaimsBody();

  @override
  State<_ClaimsBody> createState() => _ClaimsBodyState();
}

class _ClaimsBodyState extends State<_ClaimsBody> {
  final _svc = AdminService();
  static const _filters = ['All', 'Pending', 'Approved', 'Rejected'];
  String _filter = 'Pending';
  int _tick = 0;

  Future<void> _open(Map<String, dynamic> c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ClaimReviewScreen(claim: c)));
    if (mounted) setState(() => _tick++);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Map<String, dynamic>>>(
      loadKey: _tick,
      load: () => _svc.claims('all'),
      builder: (context, all, reload) {
        final list = _filter == 'All' ? all : all.where((c) => '${c['status']}' == _filter.toLowerCase()).toList();
        int count(String s) => all.where((c) => '${c['status']}' == s).length;
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(14), children: [
            FilterChips(
              options: _filters,
              selected: _filter,
              onSelected: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text('${all.length} total • ${count('pending')} pending • ${count('approved')} approved • ${count('rejected')} rejected',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
            if (list.isEmpty)
              EmptyState(
                icon: Icons.notifications_none,
                title: _filter == 'Pending' ? 'No pending applications' : 'Nothing to show',
                subtitle: _filter == 'Pending' ? 'New store applications will appear here.' : 'No $_filter applications yet.',
              )
            else
              for (final c in list) _ClaimCard(claim: c, onOpen: () => _open(c)),
          ]),
        );
      },
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final Map<String, dynamic> claim;
  final VoidCallback onOpen;
  const _ClaimCard({required this.claim, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final c = claim;
    final pending = '${c['status']}' == 'pending';
    final address = [c['address'], c['barangay']].where(hasValue).join(', ');
    final decided = '${c['status']}' == 'approved' ? 'Approved' : 'Rejected';
    return AdminCard(
      onTap: onOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${c['store_name']}'.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          StatusBadge('${c['status']}'),
        ]),
        const SizedBox(height: 2),
        Text(address.isEmpty ? '-' : address, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 8),
        Text('${c['owner_name']} (${c['owner_email'] ?? ''})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Text('Submitted ${fmtDate(c['created_at'])}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          StatusBadge('${c['permit_status']}', label: 'Permit: ${c['permit_status']}'),
          StatusBadge('${c['storefront_status']}', label: 'Storefront: ${c['storefront_status']}'),
        ]),
        if (!pending && hasValue(c['reviewed_at']))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('$decided by ${c['reviewed_by_name'] ?? 'admin'} • ${fmtDate(c['reviewed_at'])}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
        if (!pending && hasValue(c['rejection_reason']))
          Text('Reason: ${c['rejection_reason']}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onOpen,
            icon: Icon(pending ? Icons.fact_check_outlined : Icons.visibility_outlined),
            label: Text(pending ? 'Review permit + storefront' : 'View details'),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- review page
/// Review one application. Permit and storefront are verified separately.
/// Approve is only possible after BOTH are verified, and always needs an explicit tap + confirmation.
class ClaimReviewScreen extends StatefulWidget {
  final Map<String, dynamic> claim;
  const ClaimReviewScreen({super.key, required this.claim});

  @override
  State<ClaimReviewScreen> createState() => _ClaimReviewScreenState();
}

class _ClaimReviewScreenState extends State<ClaimReviewScreen> {
  final _svc = AdminService();
  late String _permit = '${widget.claim['permit_status']}';
  late String _front = '${widget.claim['storefront_status']}';
  bool _busy = false;

  Map<String, dynamic> get _c => widget.claim;
  int get _id => asInt(_c['id']);
  bool get _isPending => '${_c['status']}' == 'pending';
  String get _decision => '${_c['status']}' == 'approved' ? 'Approved' : 'Rejected';
  bool get _canApprove => _isPending && _permit == 'verified' && _front == 'verified' && !_busy;

  String _coords() {
    final lat = double.tryParse('${_c['latitude']}');
    final lng = double.tryParse('${_c['longitude']}');
    return (lat == null || lng == null) ? '-' : '${lat.toStringAsFixed(7)}, ${lng.toStringAsFixed(7)}';
  }

  Future<void> _setStatus(String part, String status) async {
    setState(() => _busy = true);
    try {
      await _svc.verifyClaim(_id, part, status);
      if (!mounted) return;
      setState(() => part == 'permit' ? _permit = status : _front = status);
    } catch (e) {
      if (mounted) toast(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() async {
    final ok = await confirmDialog(
      context,
      title: 'Approve application?',
      message: '${_c['owner_name']} will become the owner of "${_c['store_name']}". Only approve if the permit and storefront match this store.',
      confirmLabel: 'Approve',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await _svc.reviewClaim(_id, approve: true);
      if (!mounted) return;
      toast(context, 'Application approved.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, '$e');
      }
    }
  }

  Future<void> _reject() async {
    final reason = await reasonDialog(
      context,
      title: 'Reject application',
      hint: 'Reason (shown to the owner)',
      confirmLabel: 'Reject',
    );
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      await _svc.reviewClaim(_id, approve: false, reason: reason);
      if (!mounted) return;
      toast(context, 'Application rejected.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, '$e');
      }
    }
  }

  Widget _doc({required String title, required String part, required dynamic url, required String status}) {
    return AdminCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
          StatusBadge(status),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => showImageViewer(context, title, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              width: double.infinity,
              color: AppColors.background,
              child: hasValue(url)
                  ? Image.network(adminImgUrl(url),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('Cannot load image.'))))
                  : const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No image uploaded.'))),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.only(top: 4), child: Text('Tap the image to zoom', style: TextStyle(fontSize: 11, color: AppColors.muted))),
        if (_isPending) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Pending')),
                ButtonSegment(value: 'verified', label: Text('Verified')),
                ButtonSegment(value: 'rejected', label: Text('Invalid')),
              ],
              selected: {status},
              onSelectionChanged: _busy ? null : (s) => _setStatus(part, s.first),
            ),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = [_c['address'], _c['barangay']].where(hasValue).join(', ');
    return Scaffold(
      appBar: AppBar(title: const Text('Review application')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('${_c['store_name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              StatusBadge('${_c['status']}'),
            ]),
            const SizedBox(height: 4),
            const Text('Store in the app. It must match the documents:', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            InfoRow(icon: Icons.badge_outlined, label: 'Business name', value: '${_c['store_name']}'),
            InfoRow(icon: Icons.place_outlined, label: 'Address', value: address),
            InfoRow(icon: Icons.my_location, label: 'Coordinates', value: _coords()),
            const Divider(height: 20),
            InfoRow(icon: Icons.person_outline, label: 'Applicant', value: '${_c['owner_name']}'),
            InfoRow(icon: Icons.mail_outline, label: 'Email', value: '${_c['owner_email'] ?? ''}'),
            if (hasValue(_c['owner_phone'])) InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: '${_c['owner_phone']}'),
            InfoRow(icon: Icons.event, label: 'Submitted', value: fmtDate(_c['created_at'])),
          ]),
        ),
        _doc(title: '1. Business permit / ID', part: 'permit', url: _c['permit_url'], status: _permit),
        _doc(title: '2. Storefront photo', part: 'storefront', url: _c['storefront_url'], status: _front),
        if (!_isPending)
          AdminCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Decision', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('$_decision by ${_c['reviewed_by_name'] ?? 'admin'}'),
              Text(fmtDate(_c['reviewed_at']), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              if (hasValue(_c['rejection_reason']))
                Padding(padding: const EdgeInsets.only(top: 6), child: Text('Reason: ${_c['rejection_reason']}', style: const TextStyle(color: AppColors.error))),
            ]),
          ),
        if (_isPending)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Check the business name, owner, address and coordinates against the permit, and confirm the storefront photo shows the same business. '
              'Mark each document as Verified, then approve. Applications are never approved automatically.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        const SizedBox(height: 70),
      ]),
      bottomNavigationBar: _isPending
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                color: Colors.white,
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _reject,
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, minimumSize: const Size.fromHeight(48)),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canApprove ? _approve : null,
                      child: _busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Approve'),
                    ),
                  ),
                ]),
              ),
            )
          : null,
    );
  }
}
