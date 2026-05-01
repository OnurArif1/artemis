import 'package:flutter/foundation.dart';

class HomeTabController extends ChangeNotifier {
  HomeTabController({int initialIndex = 0}) : _index = initialIndex;

  static const int chatsTabIndex = 0;
  static const int roomsTabIndex = 1;
  static const int topicsTabIndex = 2;

  int _index;
  int? _roomIdToFocus;

  int get currentIndex => _index;

  void setIndex(int i) {
    if (_index == i) {
      if (i == chatsTabIndex) notifyListeners();
      return;
    }
    _index = i;
    notifyListeners();
  }

  void openRoomsTabWithRoom(int roomId) {
    _roomIdToFocus = roomId;
    _index = roomsTabIndex;
    notifyListeners();
  }

  int? consumeRoomFocusRequest() {
    final v = _roomIdToFocus;
    _roomIdToFocus = null;
    return v;
  }
}
