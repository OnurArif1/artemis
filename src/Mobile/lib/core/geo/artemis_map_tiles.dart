import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class ArtemisMapTiles {
  ArtemisMapTiles._();

  static TileLayer layer() {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'artemis_mobile',
      maxNativeZoom: 19,
      fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
  }

  static Widget attribution({Alignment alignment = Alignment.bottomRight}) {
    return SimpleAttributionWidget(
      alignment: alignment,
      backgroundColor: Colors.white.withValues(alpha: 0.88),
      source: const Text('CARTO · © OpenStreetMap contributors'),
    );
  }
}
