import 'package:flutter/foundation.dart';

/// Alt sekmeler + haritada belirli odaya odaklanma (Web `goToRoom` / `roomId` sorgusu).
class HomeTabController extends ChangeNotifier {
  HomeTabController({int initialIndex = 0}) : _index = initialIndex;

  /// [HomeShell] ile aynı sıra.
  static const int chatsTabIndex = 0;
  static const int roomsTabIndex = 1;

  int _index;
  int? _roomIdToFocus;

  int get currentIndex => _index;

  void setIndex(int i) {
    if (_index == i) {
      // Aynı sekmeye tekrar dokunulduğunda (ör. Sohbetler) yenileme dinleyebilsin.
      if (i == chatsTabIndex) notifyListeners();
      return;
    }
    _index = i;
    notifyListeners();
  }

  /// [HomeShell] sekme sırası: 0=Sohbetler, 1=Odalar, …
  void openRoomsTabWithRoom(int roomId) {
    _roomIdToFocus = roomId;
    _index = roomsTabIndex;
    notifyListeners();
  }

  /// [RoomMapScreen] tek seferlik tüketir.
  int? consumeRoomFocusRequest() {
    final v = _roomIdToFocus;
    _roomIdToFocus = null;
    return v;
  }
}
