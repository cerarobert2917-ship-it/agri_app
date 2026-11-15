import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../services/admin_service.dart';
import '../../widgets/common.dart';
import '../owner_setup_screen.dart' show mamburaoBarangays;
import 'admin_widgets.dart';
import 'location_picker_screen.dart';

/// Create a store that owners can later claim. Pops `true` when a store was added.
class AddStoreScreen extends StatefulWidget {
  const AddStoreScreen({super.key});

  @override
  State<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = AdminService();
  final _picker = ImagePicker();
  final _name = TextEditingController(), _address = TextEditingController(), _desc = TextEditingController();
  final _lat = TextEditingController(), _lng = TextEditingController();
  String? _barangay;
  Uint8List? _image;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _address, _desc, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _coord(String? v, double min, double max) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null) return 'Numbers only';
    return (n < min || n > max) ? 'Out of range' : null;
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 75);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (mounted) setState(() => _image = bytes);
  }

  Future<void> _pickLocation() async {
    final p = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLat: double.tryParse(_lat.text.trim()), initialLng: double.tryParse(_lng.text.trim())),
      ),
    );
    if (p == null) return;
    setState(() {
      _lat.text = p.latitude.toStringAsFixed(7);
      _lng.text = p.longitude.toStringAsFixed(7);
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _svc.createStore({
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'barangay': _barangay,
        'description': _desc.text.trim(),
        'latitude': double.parse(_lat.text.trim()),
        'longitude': double.parse(_lng.text.trim()),
        if (_image != null) 'image': base64Encode(_image!),
      });
      if (!mounted) return;
      toast(context, 'Store added. Owners can now claim it.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const coordType = TextInputType.numberWithOptions(decimal: true, signed: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Add store')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error != null) ErrorBanner(_error!),
            const SectionTitle('Store information'),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Store name *'), validator: (v) => Validators.required(v, 'store name')),
            const SizedBox(height: 12),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Complete address *'), validator: (v) => Validators.required(v, 'address')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _barangay,
              items: [for (final b in mamburaoBarangays) DropdownMenuItem(value: b, child: Text(b))],
              onChanged: (v) => setState(() => _barangay = v),
              decoration: const InputDecoration(labelText: 'Barangay *'),
              validator: (v) => v == null ? 'Select a barangay' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)')),
            const SizedBox(height: 16),
            const SectionTitle('Store image (optional)'),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                child: _image == null
                    ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primary),
                        SizedBox(height: 6),
                        Text('Tap to upload a storefront photo', style: TextStyle(color: AppColors.muted)),
                      ])
                    : ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_image!, width: double.infinity, fit: BoxFit.cover)),
              ),
            ),
            if (_image != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(onPressed: () => setState(() => _image = null), icon: const Icon(Icons.close, size: 16), label: const Text('Remove image')),
              ),
            const SizedBox(height: 12),
            SectionTitle('Store location', trailing: TextButton.icon(onPressed: _pickLocation, icon: const Icon(Icons.map_outlined, size: 18), label: const Text('Pick on map'))),
            Row(children: [
              Expanded(child: TextFormField(controller: _lat, keyboardType: coordType, decoration: const InputDecoration(labelText: 'Latitude *'), validator: (v) => _coord(v, -90, 90))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _lng, keyboardType: coordType, decoration: const InputDecoration(labelText: 'Longitude *'), validator: (v) => _coord(v, -180, 180))),
            ]),
            const SizedBox(height: 6),
            const Text('Use "Pick on map" or type the coordinates (in Google Maps, right-click the store and copy them).', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Add store'),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}
