import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/geo/artemis_map_tiles.dart';
import '../../core/theme/app_colors.dart';

/// Odalar haritası ile aynı stil: tek konu işareti.
class TopicLocationMapScreen extends StatefulWidget {
  const TopicLocationMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.topicTitle,
  });

  final double latitude;
  final double longitude;
  final String topicTitle;

  @override
  State<TopicLocationMapScreen> createState() => _TopicLocationMapScreenState();
}

class _TopicLocationMapScreenState extends State<TopicLocationMapScreen> {
  static const _mapBaseColor = Color(0xFFF2F2F2);
  static const _minMapZoom = 3.0;
  static const _maxMapZoom = 18.0;

  late final MapController _mapController;
  late final LatLng _point;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _point = LatLng(widget.latitude, widget.longitude);
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickTilePipeline());
  }

  /// Odalar haritasındaki gibi: ilk karede karolar bazen çizilmez; hafif kamera oynatması tetikler.
  void _kickTilePipeline() {
    void nudge() {
      if (!mounted) return;
      try {
        final c = _mapController.camera;
        _mapController.move(c.center, c.zoom + 1e-8);
      } catch (_) {}
    }

    nudge();
    Future<void>.delayed(const Duration(milliseconds: 120), nudge);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _zoomByStep(double delta) {
    try {
      final c = _mapController.camera;
      final z = (c.zoom + delta).clamp(_minMapZoom, _maxMapZoom);
      _mapController.move(c.center, z);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mapBaseColor,
      appBar: AppBar(
        title: Text(
          widget.topicTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: _mapBaseColor,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  backgroundColor: _mapBaseColor,
                  initialCenter: _point,
                  initialZoom: 14,
                  minZoom: _minMapZoom,
                  maxZoom: _maxMapZoom,
                ),
                children: [
                  ArtemisMapTiles.layer(),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _point,
                        width: 44,
                        height: 44,
                        alignment: Alignment.bottomCenter,
                        child: const Icon(
                          Icons.place_rounded,
                          size: 44,
                          color: AppColors.purple600,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ArtemisMapTiles.attribution(),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Yakınlaştır',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _zoomByStep(1),
                    icon: const Icon(Icons.add_rounded, color: AppColors.purple700),
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),
                  IconButton(
                    tooltip: 'Uzaklaştır',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _zoomByStep(-1),
                    icon: const Icon(Icons.remove_rounded, color: AppColors.purple700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
