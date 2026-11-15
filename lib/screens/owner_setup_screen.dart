import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../services/owner_service.dart';
import '../widgets/common.dart';

const mamburaoBarangays = [
  'Balansay',
  'Fatima',
  'Payompon',
  'Poblacion 1',
  'Poblacion 2',
  'Poblacion 3',
  'Poblacion 4',
  'Poblacion 5',
  'Poblacion 6',
  'Poblacion 7',
  'Poblacion 8',
  'San Luis',
  'Talabaan',
  'Tangkalan',
  'Tayamaan',
];

class OwnerSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? store; // may laman kapag nag-e-edit
  final Future<void> Function() onSaved;
  const OwnerSetupScreen({super.key, this.store, required this.onSaved});

  @override
  State<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends State<OwnerSetupScreen> {
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
  bool _locating = false;
  String? _error;

  bool get _editing => widget.store != null;

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _name = TextEditingController(text: s?['name'] ?? '');
    _desc = TextEditingController(text: s?['description'] ?? '');
    _address = TextEditingController(text: s?['address'] ?? '');
    _contact = TextEditingController(text: s?['contact_number'] ?? '');
    _hours = TextEditingController(
        text: s?['opening_hours'] ?? 'Mon-Sat 7:00AM-6:00PM');
    _lat = TextEditingController(
        text: s != null ? '${s['latitude']}' : AppConfig.defaultLat.toString());
    _lng = TextEditingController(
        text:
            s != null ? '${s['longitude']}' : AppConfig.defaultLng.toString());
    final b = s?['barangay'];
    _barangay = (b != null && '$b'.isNotEmpty) ? '$b' : null;
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _address, _contact, _hours, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _error =
            'Location permission denied. Please enter the coordinates manually.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _lat.text = pos.latitude.toStringAsFixed(6);
      _lng.text = pos.longitude.toStringAsFixed(6);
    } catch (_) {
      setState(() => _error =
          'Unable to get your location. Please enter the coordinates manually.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String? _coord(String? v, double min, double max) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null) return 'Numbers only';
    if (n < min || n > max) return 'Out of range';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _svc.saveStore({
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'address': _address.text.trim(),
        'barangay': _barangay ?? '',
        'latitude': double.parse(_lat.text.trim()),
        'longitude': double.parse(_lng.text.trim()),
        'contact_number': _contact.text.trim(),
        'opening_hours': _hours.text.trim(),
      });
      await widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Store saved.')));
      if (_editing && Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final barangays =
        {...mamburaoBarangays, if (_barangay != null) _barangay!}.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Store' : 'Set Up Your Store'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<AuthService>().logout();
                if (context.mounted)
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_editing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                          'Enter your store details. Viewers will see it once an admin approves it.',
                          style: TextStyle(color: AppColors.muted)),
                    ),
                  if (_error != null) ErrorBanner(_error!),
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Store name',
                        prefixIcon: Icon(Icons.storefront_outlined)),
                    validator: (v) => Validators.required(v, 'store name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _desc,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText:
                            'Description (e.g. fertilizer, seeds, feeds)',
                        prefixIcon: Icon(Icons.notes)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.place_outlined)),
                    validator: (v) => Validators.required(v, 'address'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _barangay,
                    items: [
                      for (final b in barangays)
                        DropdownMenuItem(value: b, child: Text(b))
                    ],
                    onChanged: (v) => setState(() => _barangay = v),
                    decoration: const InputDecoration(
                        labelText: 'Barangay',
                        prefixIcon: Icon(Icons.map_outlined)),
                    validator: (v) => v == null ? 'Select a barangay' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contact,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Contact number',
                        prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) => Validators.required(v, 'contact number'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hours,
                    decoration: const InputDecoration(
                        labelText: 'Opening hours',
                        prefixIcon: Icon(Icons.schedule)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Store location',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Used for the map and distance calculation.',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _locating ? null : _useMyLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: const Text('Use my current location'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lat,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration:
                            const InputDecoration(labelText: 'Latitude'),
                        validator: (v) => _coord(v, -90, 90),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lng,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                        validator: (v) => _coord(v, -180, 180),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  const Text(
                      'Tip: in Google Maps, right-click your store and copy the coordinates.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text(
                            _editing ? 'Save Changes' : 'Submit for Approval'),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
