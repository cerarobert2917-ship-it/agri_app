import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/owner_service.dart';
import '../widgets/common.dart';

/// Ipinapakita sa owner na wala pang approved na store:
///  - walang claim o rejected  -> "Claim your store" (pumili ng store + upload ng patunay)
///  - pending                  -> "Under review"
class OwnerClaimScreen extends StatefulWidget {
  /// null kapag wala pang claim; may laman kapag pending o rejected
  final Map<String, dynamic>? claim;
  final Future<void> Function() onChanged;
  const OwnerClaimScreen({super.key, this.claim, required this.onChanged});

  @override
  State<OwnerClaimScreen> createState() => _OwnerClaimScreenState();
}

class _OwnerClaimScreenState extends State<OwnerClaimScreen> {
  final _svc = OwnerService();
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _stores = [];
  int? _storeId;
  Uint8List? _permit, _front;
  bool _loading = false, _submitting = false;
  String? _error;

  bool get _pending => '${widget.claim?['status']}' == 'pending';
  bool get _rejected => '${widget.claim?['status']}' == 'rejected';

  @override
  void initState() {
    super.initState();
    if (!_pending) _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _loading = true);
    try {
      final s = await _svc.availableStores();
      if (!mounted) return;
      setState(() {
        _stores = s;
        _error = null;
        // kapag rejected, naka-pili na ulit ang dating store kung available pa
        final prev = int.tryParse('${widget.claim?['store_id']}');
        if (prev != null && s.any((e) => '${e['id']}' == '$prev')) _storeId = prev;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(bool permit) async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 70);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => permit ? _permit = bytes : _front = bytes);
  }

  Future<void> _submit() async {
    if (_storeId == null) return setState(() => _error = 'Select your store first.');
    if (_permit == null) return setState(() => _error = 'Upload a photo of your business permit or valid ID.');
    if (_front == null) return setState(() => _error = 'Upload a photo of your storefront.');
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _svc.claimStore(
        storeId: _storeId!,
        permitBase64: base64Encode(_permit!),
        frontBase64: base64Encode(_front!),
      );
      await widget.onChanged();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _photoBox(String label, Uint8List? bytes, bool permit) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => _pick(permit),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bytes == null ? AppColors.line : AppColors.primary, width: 1.5),
            ),
            child: bytes == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 30),
                    const SizedBox(height: 6),
                    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ])
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(bytes, fit: BoxFit.cover, width: double.infinity)),
          ),
        ),
      );

  Widget _pendingView() {
    final name = '${widget.claim?['name'] ?? ''}';
    return ListView(padding: const EdgeInsets.all(14), children: [
      _card([
        const Icon(Icons.hourglass_top, color: AppColors.warning, size: 40),
        const SizedBox(height: 10),
        const Text('Under review',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Waiting for admin approval.\nYour claim for "$name" has been submitted. You will be able to manage this store once approved.',
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: widget.onChanged, child: const Text('Refresh status')),
      ]),
    ]);
  }

  Widget _formView() {
    return ListView(padding: const EdgeInsets.all(14), children: [
      if (_rejected)
        ErrorBanner('Your claim was rejected: ${widget.claim?['rejection_reason'] ?? 'no reason given'}. You can resubmit below.'),
      if (_error != null) ErrorBanner(_error!),
      _card([
        const Text('1. Select your store', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('Stores are added by the admin. Name and location cannot be changed.',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
        else if (_stores.isEmpty)
          const Text('No stores available to claim right now. Please contact the admin.',
              style: TextStyle(color: AppColors.muted))
        else
          for (final s in _stores)
            RadioListTile<int>(
              contentPadding: EdgeInsets.zero,
              value: int.parse('${s['id']}'),
              groupValue: _storeId,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _storeId = v),
              title: Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${s['address'] ?? ''}${s['barangay'] != null ? ', ${s['barangay']}' : ''}',
                  style: const TextStyle(fontSize: 12)),
            ),
      ]),
      _card([
        const Text('2. Proof of ownership', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('Upload a business permit / DTI or a valid ID, and a photo of your storefront.',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 10),
        _photoBox('Business permit / DTI / valid ID', _permit, true),
        _photoBox('Photo of your storefront', _front, false),
      ]),
      ElevatedButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(_rejected ? 'Resubmit claim' : 'Submit claim'),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pending ? 'Claim status' : 'Claim your store'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: SafeArea(child: _pending ? _pendingView() : _formView()),
    );
  }
}
