import 'package:flutter/foundation.dart';

/// Alt sekmeler + haritada belirli odaya odaklanma (Web `goToRoom` / `roomId` sorgusu).
class HomeTabController extends ChangeNotifier {
  HomeTabController({int initialIndex = 2}) : _index = initialIndex;

  int _index;
  int? _roomIdToFocus;

  int get currentIndex => _index;

  void setIndex(int i) {
    if (_index == i) return;
    _index = i;
    notifyListeners();
  }

  void openRoomsTabWithRoom(int roomId) {
    _roomIdToFocus = roomId;
    _index = 2;
    notifyListeners();
  }

  /// [RoomMapScreen] tek seferlik tüketir.
  int? consumeRoomFocusRequest() {
    final v = _roomIdToFocus;
    _roomIdToFocus = null;
    return v;
  }
}
