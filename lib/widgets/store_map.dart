import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';

/// Hawak ang naka-save na lokasyon ng tindahan (galing sa database) para sa mapa ng owner.
/// Ang lokasyon ay itinatakda ng admin, kaya dito ay hindi ito inililipat ng owner.
class PinController extends ChangeNotifier {
  double refLat;
  double refLng;
  int _moveTick = 0;

  PinController(this.refLat, this.refLng);

  double get lat => refLat;
  double get lng => refLng;
  int get moveTick => _moveTick;

  /// Ibalik ang mapa sa lokasyon ng tindahan.
  void recenter() {
    _moveTick++;
    notifyListeners();
  }

  /// Kapag nagbago ang naka-save na lokasyon ng tindahan.
  void resetRef(double la, double ln) {
    refLat = la;
    refLng = ln;
    _moveTick++;
    notifyListeners();
  }
}

/// Totoong mapa (OpenStreetMap) na nakasentro sa mismong lokasyon ng tindahan ng owner.
class StoreMap extends StatefulWidget {
  final PinController pin;
  const StoreMap({super.key, required this.pin});

  @override
  State<StoreMap> createState() => _StoreMapState();
}

class _StoreMapState extends State<StoreMap> {
  final _controller = MapController();
  bool _ready = false;
  int _lastTick = 0;

  @override
  void initState() {
    super.initState();
    _lastTick = widget.pin.moveTick;
    widget.pin.addListener(_onPin);
  }

  @override
  void dispose() {
    widget.pin.removeListener(_onPin);
    _controller.dispose();
    super.dispose();
  }

  void _onPin() {
    if (!mounted) return;
    setState(() {}); // ilipat ang pin marker
    if (widget.pin.moveTick != _lastTick) {
      _lastTick = widget.pin.moveTick;
      _goToStore();
    }
  }

  void _goToStore() {
    if (!_ready) return;
    _controller.move(LatLng(widget.pin.refLat, widget.pin.refLng), 16);
  }

  @override
  Widget build(BuildContext context) {
    final store = LatLng(widget.pin.refLat, widget.pin.refLng);
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: store,
        initialZoom: 16,
        minZoom: 5,
        maxZoom: 19,
        onMapReady: () {
          _ready = true;
          _goToStore();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.agrifind.agri_app',
        ),
        CircleLayer(circles: [
          CircleMarker(
            point: store,
            radius: 70,
            useRadiusInMeter: true,
            color: AppColors.primary.withOpacity(0.16),
            borderColor: AppColors.primary.withOpacity(0.45),
            borderStrokeWidth: 1.5,
          ),
        ]),
        MarkerLayer(markers: [
          Marker(
            point: store,
            width: 56,
            height: 56,
            alignment: Alignment.topCenter,
            child: const Icon(
              Icons.location_on,
              size: 56,
              color: AppColors.primary,
              shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
            ),
          ),
        ]),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
