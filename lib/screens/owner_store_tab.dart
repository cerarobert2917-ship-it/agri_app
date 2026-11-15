import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../services/owner_service.dart';
import '../widgets/common.dart';
import '../widgets/store_map.dart';

class OwnerStoreTab extends StatefulWidget {
  final Map<String, dynamic> store;
  final PinController pin;
  final Future<void> Function() onSaved;
  final VoidCallback onShowMap;
  const OwnerStoreTab(
      {super.key,
      required this.store,
      required this.pin,
      required this.onSaved,
      required this.onShowMap});

  @override
  State<OwnerStoreTab> createState() => _OwnerStoreTabState();
}

class _OwnerStoreTabState extends State<OwnerStoreTab> {
  final _form = GlobalKey<FormState>();
  final _svc = OwnerService();
  late final TextEditingController _name,
      _desc,
      _address,
      _contact,
      _hours,
      _lat,
      _lng;
  String? _barangay;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _name = TextEditingController(text: '${s['name'] ?? ''}');
    _desc = TextEditingController(text: _clean(s['description']));
    _address = TextEditingController(text: _clean(s['address']));
    _contact = TextEditingController(text: _clean(s['contact_number']));
    _hours = TextEditingController(text: _clean(s['opening_hours']));
    _lat = TextEditingController(text: '${s['latitude']}');
    _lng = TextEditingController(text: '${s['longitude']}');
    final b = _clean(s['barangay']);
    _barangay = b.isEmpty ? null : b;
  }

  String _clean(dynamic v) => (v == null || '$v' == 'null') ? '' : '$v';

  @override
  void dispose() {
    for (final c in [_name, _desc, _address, _contact, _hours, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _svc.saveStore({
        'description': _desc.text.trim(),
        'contact_number': _contact.text.trim(),
        'opening_hours': _hours.text.trim(),
      });
      await widget.onSaved();
      if (mounted) _toast('Store saved.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec([String? hint]) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: 1.5));
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: b(AppColors.line),
      enabledBorder: b(AppColors.line),
      focusedBorder: b(AppColors.primary),
      errorBorder: b(AppColors.error),
      focusedErrorBorder: b(AppColors.error),
    );
  }

  Widget _locked(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(label),
          const SizedBox(height: 4),
          InputDecorator(
            decoration: _dec().copyWith(
                suffixIcon: const Icon(Icons.lock_outline,
                    size: 18, color: AppColors.muted)),
            child: Text(value.isEmpty ? '-' : value,
                style: const TextStyle(color: AppColors.muted)),
          ),
        ]),
      );

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500));

  Widget _field(String label, TextEditingController c,
      {String? Function(String?)? validator,
      int maxLines = 1,
      TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        const SizedBox(height: 4),
        TextFormField(
            controller: c,
            maxLines: maxLines,
            keyboardType: type,
            validator: validator,
            decoration: _dec()),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const GradientHead(
          title: 'My Store',
          subtitle: 'Edit your description, contact number and hours.'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ErrorBanner(_error!),
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: cardShadow),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                                color: AppColors.light.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Row(children: [
                              Icon(Icons.info_outline,
                                  size: 18, color: AppColors.primaryDark),
                              SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                      'To change your store name or location, contact the admin.',
                                      style: TextStyle(fontSize: 12))),
                            ]),
                          ),
                          _locked('Store name', _name.text),
                          _locked('Address', _address.text),
                          _locked('Barangay', _barangay ?? ''),
                          _locked('Location (pin on map)',
                              '${widget.store['latitude']}, ${widget.store['longitude']}'),
                          _field('Description (e.g. fertilizer, seeds, feeds)',
                              _desc,
                              maxLines: 2),
                          _field('Contact number', _contact,
                              type: TextInputType.phone,
                              validator: (v) =>
                                  Validators.required(v, 'contact number')),
                          _field('Opening hours', _hours),
                        ]),
                  ),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Save Changes'),
                  ),
                  const SizedBox(height: 8),
                ]),
          ),
        ),
      ),
    ]);
  }
}
