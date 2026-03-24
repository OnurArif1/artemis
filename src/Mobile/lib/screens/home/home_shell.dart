import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../categories/category_list_screen.dart';
import '../profile/profile_screen.dart';
import '../rooms/room_list_screen.dart';
import '../topics/topic_list_screen.dart';

/// Alt gezinme (telefon) veya yan şerit (tablet / geniş ekran).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.topic_outlined),
      selectedIcon: Icon(Icons.topic_rounded),
      label: 'Konular',
    ),
    NavigationDestination(
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category_rounded),
      label: 'Kategoriler',
    ),
    NavigationDestination(
      icon: Icon(Icons.meeting_room_outlined),
      selectedIcon: Icon(Icons.meeting_room_rounded),
      label: 'Odalar',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const pages = <Widget>[
      TopicListScreen(),
      CategoryListScreen(),
      RoomListScreen(),
      ProfileScreen(),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 720;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 960,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: AppColors.surfaceCard,
              indicatorColor: AppColors.purple100,
              selectedIconTheme: const IconThemeData(color: AppColors.purple600),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF6B6B76)),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.purple700,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: const TextStyle(color: Color(0xFF6B6B76)),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.topic_outlined),
                  selectedIcon: Icon(Icons.topic_rounded),
                  label: Text('Konular'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.category_outlined),
                  selectedIcon: Icon(Icons.category_rounded),
                  label: Text('Kategoriler'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.meeting_room_outlined),
                  selectedIcon: Icon(Icons.meeting_room_rounded),
                  label: Text('Odalar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Profil'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
