import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config.dart';
import '../../core/theme.dart';

/// Tap the map to place the pin, then confirm. Returns a [LatLng] (or null if cancelled).
/// Uses OpenStreetMap (same map engine as the rest of the app, so no API key is needed).
class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _picked ?? LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
    return Scaffold(
      appBar: AppBar(title: const Text('Pick store location')),
      body: Stack(children: [
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16,
              onTap: (tapPosition, point) => setState(() => _picked = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.agrifind.agri_app',
              ),
              if (_picked != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _picked!,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on, color: AppColors.error, size: 44),
                  ),
                ]),
              const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
            ],
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10)]),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _picked == null
                      ? 'Tap the map to drop a pin on the store.'
                      : 'Lat ${_picked!.latitude.toStringAsFixed(7)}, Lng ${_picked!.longitude.toStringAsFixed(7)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _picked == null ? null : () => Navigator.pop(context, _picked),
                  child: const Text('Use this location'),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
