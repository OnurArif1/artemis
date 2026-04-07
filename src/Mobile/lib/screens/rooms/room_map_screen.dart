import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/geo/room_map_clustering.dart';
import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/entity_map.dart';
import '../../core/util/jwt_email.dart';
import '../../core/util/paged_result.dart';
import '../../core/util/room_create_policy.dart';
import '../../core/util/subscription_display.dart';
import '../../providers/home_tab_controller.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../widgets/artemis_snackbar.dart';
import '../topics/topic_detail_screen.dart';
import 'create_room_screen.dart';
import 'room_detail_screen.dart';
import 'room_list_screen.dart';

const _turkeyCenter = LatLng(39, 35.5);
const _userRadiusKm = 40.0;
const _detailZoom = 12.0;
const _zoomClusterThreshold = 10.0;

const _mapBaseColor = Color(0xFFF2F2F2);

const double _minMapZoom = 3;
const double _maxMapZoom = 18;

List<LatLng> _cityCameraFrameCoords(List<LatLng> centers) {
  if (centers.length <= 1) return centers;
  const maxKmFromTr = 2400.0;
  final near = centers
      .where(
        (c) =>
            calculateDistanceKm(
              _turkeyCenter.latitude,
              _turkeyCenter.longitude,
              c.latitude,
              c.longitude,
            ) <=
            maxKmFromTr,
      )
      .toList();
  if (near.isNotEmpty && near.length < centers.length) {
    return near;
  }
  return centers;
}

enum _MapViewMode { city, nearby, detail }

class RoomMapScreen extends StatefulWidget {
  const RoomMapScreen({super.key});

  @override
  State<RoomMapScreen> createState() => _RoomMapScreenState();
}

class _RoomMapScreenState extends State<RoomMapScreen> {
  final MapController _mapController = MapController();
  late final HomeTabController _homeTab;

  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _topics = [];
  bool _loading = true;
  String? _error;

  double? _filterLat;
  double? _filterLng;
  double? _userLat;
  double? _userLng;

  _MapViewMode _mode = _MapViewMode.city;
  CombinedRegion? _detailRegion;
  bool _detailRoomsOnly = true;

  int _liveCount = 0;
  int _topicCount = 0;
  int? _pendingFocusRoomId;

  int? _mySubscriptionType;
  bool _tierLoading = true;

  @override
  void initState() {
    super.initState();
    _homeTab = context.read<HomeTabController>();
    _homeTab.addListener(_onHomeTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMap(showRationaleDialog: true);
      _loadMySubscriptionTier();
    });
  }

  Future<void> _loadMySubscriptionTier() async {
    final app = context.read<AppServices>();
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);
    final t = await resolveMySubscriptionTypeForRoomCreate(app, token, email);
    if (!mounted) return;
    setState(() {
      _mySubscriptionType = t;
      _tierLoading = false;
    });
  }

  Future<void> _onCreateRoomPressed() async {
    if (_tierLoading) return;
    if (!canCreateRoom(_mySubscriptionType)) {
      await showRoomCreateNotAllowedDialog(context);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CreateRoomScreen(),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  void dispose() {
    _homeTab.removeListener(_onHomeTabChanged);
    _mapController.dispose();
    super.dispose();
  }

  void _onHomeTabChanged() {
    if (!mounted || _homeTab.currentIndex != HomeTabController.roomsTabIndex) {
      return;
    }
    final id = _homeTab.consumeRoomFocusRequest();
    if (id == null) return;
    setState(() => _pendingFocusRoomId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryApplyPendingRoomFocus();
    });
  }

  bool _tryApplyPendingRoomFocus() {
    final id = _pendingFocusRoomId;
    if (id == null) return false;
    Map<String, dynamic>? room;
    for (final r in _rooms) {
      if (entityId(r) == id) {
        room = r;
        break;
      }
    }
    if (room == null) {
      if (!_loading) {
        showAppSnackBar(
          context,
          'Oda şu an harita listesinde yok; yenilemeyi deneyin.',
          error: true,
        );
        setState(() => _pendingFocusRoomId = null);
      }
      return false;
    }
    setState(() => _pendingFocusRoomId = null);
    final ll = itemLatLng(room);
    if (ll != null) {
      _mapController.move(ll, 14);
      _scheduleTilePipelineKick();
    }
    final r = room;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RoomDetailScreen(room: r),
        ),
      );
    });
    return true;
  }

  Future<void> _loadMap({required bool showRationaleDialog}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (showRationaleDialog) {
      var perm = await Geolocator.checkPermission();
      if (!mounted) return;
      if (perm == LocationPermission.denied) {
        final agreed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Konum izni'),
            content: const Text(
              'Yakınınızdaki odaları haritada doğru göstermek için anlık konumunuza ihtiyaç duyuyoruz. '
              'Devam dediğinizde sistem güvenlik penceresi açılacak; orada izin verebilirsiniz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Şimdilik hayır'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Devam'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (agreed != true) {
          setState(() {
            _filterLat = null;
            _filterLng = null;
            _userLat = null;
            _userLng = null;
          });
          await _fetchAndApply(false);
          return;
        }
      }
    }

    final pos = await LocationService.acquireForMap();

    if (!mounted) return;

    if (LocationService.consumeSkippedEmulatorDefaultNotification()) {
      showAppSnackBar(
        context,
        'Geliştirici emülatörünün varsayılan konumu (Kaliforniya) kullanılmıyor. '
        'Gerçek telefonda deneyin veya emülatörde konumu İstanbul olarak ayarlayın.',
      );
    }
    if (LocationService.consumeLocationServiceDisabledNotification()) {
      showAppSnackBar(
        context,
        'Cihazda konum kapalı. Ayarlardan konumu açıp «Konumum» veya yenile ile tekrar deneyin.',
        error: true,
      );
    }

    if (pos == null) {
      final p = await Geolocator.checkPermission();
      if (!mounted) return;
      if (p == LocationPermission.deniedForever) {
        showAppSnackBar(
          context,
          'Konum izni kalıcı kapalı. Ayarlar → Uygulama → Konum üzerinden izin verin.',
          error: true,
        );
      } else if (showRationaleDialog) {
        showAppSnackBar(
          context,
          'Konum alınamadı; genel harita gösteriliyor. İzin verip yenileyebilirsiniz.',
        );
      }
    }

    setState(() {
      if (pos != null) {
        _filterLat = pos.lat;
        _filterLng = pos.lng;
        _userLat = pos.lat;
        _userLng = pos.lng;
      } else {
        _filterLat = null;
        _filterLng = null;
        _userLat = null;
        _userLng = null;
      }
    });

    await _fetchAndApply(pos != null);
  }

  Future<void> _fetchAndApply(bool hadLocation) async {
    final token = context.read<AuthService>().token;
    final email = emailFromAccessToken(token);

    final roomFilter = <String, dynamic>{
      'pageIndex': 1,
      'pageSize': 1000,
      if (_filterLat != null && _filterLng != null) ...{
        'userLatitude': _filterLat,
        'userLongitude': _filterLng,
      },
      if (email != null) 'userEmail': email,
    };

    try {
      final svc = context.read<AppServices>();
      final results = await Future.wait([
        svc.rooms.getList(roomFilter),
        svc.topics.getList({'pageIndex': 1, 'pageSize': 1000}),
      ]);

      if (!mounted) return;

      final rooms = asMapList(results[0]);
      final topics = asMapList(results[1]);

      setState(() {
        _rooms = rooms;
        _topics = topics;
        _loading = false;
        if (hadLocation && _userLat != null && _userLng != null) {
          _mode = _MapViewMode.nearby;
        } else {
          _mode = _MapViewMode.city;
        }
        _detailRegion = null;
        _updateCountsForMode();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_tryApplyPendingRoomFocus()) {
          _fitCameraForMode();
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message ?? 'Harita verisi yüklenemedi';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Harita verisi yüklenemedi';
      });
    }
  }

  void _updateCountsForMode() {
    if (_mode == _MapViewMode.nearby &&
        _userLat != null &&
        _userLng != null) {
      final nr = filterWithinKm(_rooms, _userLat!, _userLng!, _userRadiusKm);
      final nt = filterWithinKm(_topics, _userLat!, _userLng!, _userRadiusKm);
      _liveCount = nr.length;
      _topicCount = nt.length;
    } else {
      _liveCount = _rooms.length;
      _topicCount = _topics.length;
    }
  }

  List<Map<String, dynamic>> get _displayRooms {
    if (_mode == _MapViewMode.nearby &&
        _userLat != null &&
        _userLng != null) {
      return filterWithinKm(_rooms, _userLat!, _userLng!, _userRadiusKm);
    }
    if (_mode == _MapViewMode.detail && _detailRegion != null) {
      return _detailRoomsOnly ? _detailRegion!.roomItems : [];
    }
    return _rooms;
  }

  List<Map<String, dynamic>> get _displayTopics {
    if (_mode == _MapViewMode.nearby &&
        _userLat != null &&
        _userLng != null) {
      return filterWithinKm(_topics, _userLat!, _userLng!, _userRadiusKm);
    }
    if (_mode == _MapViewMode.detail && _detailRegion != null) {
      return _detailRoomsOnly ? [] : _detailRegion!.topicItems;
    }
    return _topics;
  }

  void _fitCameraForMode() {
    try {
      if (_mode == _MapViewMode.nearby &&
          _userLat != null &&
          _userLng != null) {
        final pts = <LatLng>[
          LatLng(_userLat!, _userLng!),
          ..._displayRooms.map(itemLatLng).whereType<LatLng>(),
          ..._displayTopics.map(itemLatLng).whereType<LatLng>(),
        ];
        if (pts.length > 1) {
          _mapController.fitCamera(
            CameraFit.coordinates(
              coordinates: pts,
              padding: const EdgeInsets.all(64),
              maxZoom: 13,
            ),
          );
        } else {
          _mapController.move(LatLng(_userLat!, _userLng!), 12);
        }
        return;
      }

      if (_mode == _MapViewMode.detail && _detailRegion != null) {
        _mapController.move(_detailRegion!.center, _detailZoom);
        return;
      }

      final regions = buildCombinedRegions(_rooms, _topics);
      if (regions.isEmpty) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds:
                LatLngBounds(const LatLng(35.8, 25.9), const LatLng(42.2, 44.9)),
            padding: const EdgeInsets.all(24),
            maxZoom: 8,
          ),
        );
        return;
      }
      final coords = regions.map((r) => r.center).toList();
      final frame = _cityCameraFrameCoords(coords);
      if (frame.length == 1) {
        _mapController.move(frame.single, 9);
        return;
      }
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: frame,
          padding: const EdgeInsets.all(48),
          maxZoom: 10,
        ),
      );
    } finally {
      _scheduleTilePipelineKick();
    }
  }

  void _scheduleTilePipelineKick() {
    void nudge() {
      if (!mounted) return;
      try {
        final c = _mapController.camera;
        _mapController.move(c.center, c.zoom + 1e-8);
      } catch (_) {}
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nudge();
      Future<void>.delayed(const Duration(milliseconds: 120), nudge);
    });
  }

  void _zoomByStep(double delta) {
    try {
      final c = _mapController.camera;
      final z = (c.zoom + delta).clamp(_minMapZoom, _maxMapZoom);
      if ((z - c.zoom).abs() < 0.001) return;
      _mapController.move(c.center, z);
      _scheduleTilePipelineKick();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _refresh() async {
    await _loadMap(showRationaleDialog: false);
  }

  Future<void> _goToMyLocation() async {
    final pos = await LocationService.acquireForMap();
    if (!mounted) return;
    if (LocationService.consumeSkippedEmulatorDefaultNotification()) {
      showAppSnackBar(
        context,
        'Emülatör varsayılanı kullanılmadı. Emülatörde İstanbul koordinatı seçin veya gerçek cihaz kullanın.',
        error: true,
      );
    }
    if (LocationService.consumeLocationServiceDisabledNotification()) {
      showAppSnackBar(
        context,
        'Cihazda konum servisi kapalı.',
        error: true,
      );
    }
    if (pos == null) {
      final p = await Geolocator.checkPermission();
      if (mounted && p == LocationPermission.deniedForever) {
        showAppSnackBar(
          context,
          'Konum izni ayarlardan açılmalı.',
          error: true,
        );
      } else if (mounted) {
        showAppSnackBar(
          context,
          'Konum alınamadı. İzin ve GPS’i kontrol edin.',
          error: true,
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _userLat = pos.lat;
      _userLng = pos.lng;
      _filterLat = pos.lat;
      _filterLng = pos.lng;
      _mode = _MapViewMode.nearby;
      _detailRegion = null;
      _updateCountsForMode();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitCameraForMode();
    });
    await _fetchAndApply(true);
  }

  void _onPositionChanged(MapCamera camera, bool _) {
    if (camera.zoom >= _zoomClusterThreshold) return;
    if (_mode == _MapViewMode.city) return;
    setState(() {
      _mode = _MapViewMode.city;
      _detailRegion = null;
      _updateCountsForMode();
    });
  }

  String? _roomAccessMessage(Map<String, dynamic> room) {
    if (room['subscriptionAccessDenied'] == true ||
        room['SubscriptionAccessDenied'] == true) {
      return 'Bu odaya paketinizin katılma yetkisi yok.';
    }
    final canAccess = room['canAccess'];
    final roomRange = room['roomRange'] ?? room['RoomRange'];
    if (roomRange != null && canAccess == false) {
      final d = room['distance'] ?? room['Distance'];
      final ds = d is num ? d.toStringAsFixed(2) : '$d';
      return 'Oda menzilinin dışındasınız. Mesafe: $ds km.';
    }
    return null;
  }

  void _onRoomTap(Map<String, dynamic> room) {
    final msg = _roomAccessMessage(room);
    if (msg != null) {
      showAppSnackBar(context, msg, error: true);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoomDetailScreen(room: room),
      ),
    );
  }

  void _onTopicTap(Map<String, dynamic> topic) {
    final id = entityId(topic);
    if (id == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TopicDetailScreen(topicId: id),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    if (_mode == _MapViewMode.city) {
      return _buildCityMarkers();
    }
    return _buildDetailedMarkers();
  }

  List<CircleMarker<Object>> _buildCircles() {
    if (_mode != _MapViewMode.nearby ||
        _userLat == null ||
        _userLng == null) {
      return [];
    }
    return [
      CircleMarker<Object>(
        point: LatLng(_userLat!, _userLng!),
        radius: _userRadiusKm * 1000,
        useRadiusInMeter: true,
        color: const Color(0xFF9333EA).withValues(alpha: 0.12),
        borderColor: const Color(0xFF9333EA),
        borderStrokeWidth: 2,
      ),
    ];
  }

  List<Marker> _buildCityMarkers() {
    final regions = buildCombinedRegions(_rooms, _topics);
    final out = <Marker>[];
    for (final r in regions) {
      final hasBoth = r.roomCount > 0 && r.topicCount > 0;
      final w = hasBoth ? 64.0 : 36.0;
      final tip =
          '${r.roomCount} oda · ${r.topicCount} konu — dokun: haritayı yakınlaştır';
      out.add(
        Marker(
          point: r.center,
          width: w,
          height: 36,
          alignment: Alignment.center,
          child: Tooltip(
            message: tip,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (r.roomCount > 0)
                  Material(
                    color: AppColors.purple600,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        setState(() {
                          _mode = _MapViewMode.detail;
                          _detailRegion = r;
                          _detailRoomsOnly = true;
                          _updateCountsForMode();
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _fitCameraForMode();
                        });
                      },
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: Text(
                            '${r.roomCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (hasBoth) const SizedBox(width: 4),
                if (r.topicCount > 0)
                  Material(
                    color: AppColors.purple300,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        setState(() {
                          _mode = _MapViewMode.detail;
                          _detailRegion = r;
                          _detailRoomsOnly = false;
                          _updateCountsForMode();
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _fitCameraForMode();
                        });
                      },
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: Text(
                            '${r.topicCount}',
                            style: const TextStyle(
                              color: AppColors.purple900,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return out;
  }

  Widget _mapIconMarker({
    required String title,
    String? tooltipExtra,
    required String semanticsLabel,
    required Color backgroundColor,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final tip = tooltipExtra != null && tooltipExtra.isNotEmpty
        ? '$title\n$tooltipExtra'
        : title;
    return Tooltip(
      message: tip,
      preferBelow: false,
      verticalOffset: 10,
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 4),
      child: Semantics(
        label: semanticsLabel,
        button: true,
        hint: 'Kısa dokun: aç. Uzun bas: isim göster.',
        child: Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: Colors.black38,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            onLongPress: () {
              final m = ScaffoldMessenger.maybeOf(context);
              if (m == null) return;
              m.clearSnackBars();
              m.showSnackBar(
                SnackBar(
                  content: Text(tip),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapRoomMarkerByTier({
    required String title,
    required int? subscriptionType,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    final fill = mapRoomMarkerFill(subscriptionType);
    final badge = mapRoomMarkerBadgeLetter(subscriptionType);
    final tierLine = subscriptionType == null
        ? 'Oda · ${subscriptionTierLabelTr(null)}'
        : 'Oda · ${subscriptionTierLabelTr(subscriptionType)}';
    final tip = '$title\n$tierLine';
    return Tooltip(
      message: tip,
      preferBelow: false,
      verticalOffset: 10,
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 4),
      child: Semantics(
        label: '$semanticsLabel · $tierLine',
        button: true,
        hint: 'Kısa dokun: aç. Uzun bas: ayrıntı.',
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            onLongPress: () {
              final m = ScaffoldMessenger.maybeOf(context);
              if (m == null) return;
              m.clearSnackBars();
              m.showSnackBar(
                SnackBar(
                  content: Text(tip),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fill,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.meeting_room_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _buildDetailedMarkers() {
    final out = <Marker>[];
    for (final room in _displayRooms) {
      final ll = itemLatLng(room);
      if (ll == null) continue;
      final title =
          '${room['title'] ?? room['Title'] ?? 'Oda'}';
      final st = parseSubscriptionType(Map<String, dynamic>.from(room));
      out.add(
        Marker(
          point: ll,
          width: 44,
          height: 44,
          alignment: Alignment.bottomCenter,
          child: _mapRoomMarkerByTier(
            title: title,
            subscriptionType: st,
            semanticsLabel: 'Oda: $title',
            onTap: () => _onRoomTap(room),
          ),
        ),
      );
    }
    for (final topic in _displayTopics) {
      final ll = itemLatLng(topic);
      if (ll == null) continue;
      final title =
          '${topic['title'] ?? topic['Title'] ?? 'Konu'}';
      out.add(
        Marker(
          point: ll,
          width: 36,
          height: 36,
          alignment: Alignment.bottomCenter,
          child: _mapIconMarker(
            title: title,
            tooltipExtra: 'Konu',
            semanticsLabel: 'Konu: $title',
            backgroundColor: AppColors.purple300,
            iconColor: AppColors.purple900,
            icon: Icons.tag_rounded,
            onTap: () => _onTopicTap(topic),
          ),
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final rail = MediaQuery.sizeOf(context).width >= 720;
    final subtitle = _loading
        ? 'Yükleniyor…'
        : '$_liveCount oda · $_topicCount konu';

    return Scaffold(
      backgroundColor: _mapBaseColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              rail ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Odalar'),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
            ),
          ],
        ),
        automaticallyImplyLeading: !rail,
        actions: [
          IconButton(
            tooltip: 'Liste',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const RoomListScreen(),
                ),
              );
            },
            icon: const Icon(Icons.list_rounded),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Konumum',
            onPressed: _loading ? null : _goToMyLocation,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: _tierLoading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey.shade400,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            )
          : FloatingActionButton(
              onPressed: _onCreateRoomPressed,
              backgroundColor: canCreateRoom(_mySubscriptionType)
                  ? AppColors.purple600
                  : Colors.grey.shade500,
              child: const Icon(Icons.add_rounded),
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null && _rooms.isEmpty && _topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadMap(showRationaleDialog: true),
                child: const Text('Yeniden dene'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: _mapBaseColor,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                backgroundColor: _mapBaseColor,
                initialCenter: _turkeyCenter,
                initialZoom: 6,
                minZoom: _minMapZoom,
                maxZoom: _maxMapZoom,
                onPositionChanged: _onPositionChanged,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'artemis_mobile',
                  maxNativeZoom: 19,
                ),
                if (_buildCircles().isNotEmpty)
                  CircleLayer<Object>(circles: _buildCircles()),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),
        ),
        if (_loading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 3),
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
    );
  }
}
