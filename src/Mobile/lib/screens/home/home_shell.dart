import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons/app_content_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/home_tab_controller.dart';
import '../../widgets/app_ambient_background.dart';
import '../chat/my_chats_screen.dart';
import '../profile/profile_screen.dart';
import '../rooms/room_map_screen.dart';
import '../topics/topic_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: 'Sohbetler',
    ),
    NavigationDestination(
      icon: Icon(AppContentIcons.roomOutlined),
      selectedIcon: Icon(AppContentIcons.room),
      label: 'Odalar',
    ),
    NavigationDestination(
      icon: Icon(AppContentIcons.topicOutlined),
      selectedIcon: Icon(AppContentIcons.topic),
      label: 'Konular',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<HomeTabController>();
    final idx = tab.currentIndex;

    final pages = <Widget>[
      const MyChatsScreen(),
      const RoomMapScreen(),
      const TopicListScreen(),
      const ProfileScreen(),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 720;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 960,
              selectedIndex: idx,
              onDestinationSelected: (i) =>
                  context.read<HomeTabController>().setIndex(i),
              backgroundColor: AppColors.surfaceCard,
              indicatorColor: idx == HomeTabController.topicsTabIndex
                  ? AppColors.topicMint
                  : AppColors.purple100,
              selectedIconTheme: IconThemeData(
                color: idx == HomeTabController.topicsTabIndex
                    ? AppColors.topicTeal
                    : AppColors.purple600,
              ),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF6B6B76)),
              selectedLabelTextStyle: TextStyle(
                color: idx == HomeTabController.topicsTabIndex
                    ? AppColors.topicTeal
                    : AppColors.purple700,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: const TextStyle(color: Color(0xFF6B6B76)),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: Text('Sohbetler'),
                ),
                NavigationRailDestination(
                  icon: Icon(AppContentIcons.roomOutlined),
                  selectedIcon: Icon(AppContentIcons.room),
                  label: Text('Odalar'),
                ),
                NavigationRailDestination(
                  icon: Icon(AppContentIcons.topicOutlined),
                  selectedIcon: Icon(AppContentIcons.topic),
                  label: Text('Konular'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Profil'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const AppAmbientBackground(),
                  IndexedStack(
                    index: idx,
                    children: pages,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppAmbientBackground(),
          IndexedStack(
            index: idx,
            children: pages,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: idx == HomeTabController.topicsTabIndex
            ? NavigationBarThemeData(
                indicatorColor: AppColors.topicMint,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? AppColors.topicTeal
                        : const Color(0xFF6B6B76),
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: selected
                        ? AppColors.topicTeal
                        : const Color(0xFF6B6B76),
                    size: 24,
                  );
                }),
              )
            : Theme.of(context).navigationBarTheme,
        child: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) =>
              context.read<HomeTabController>().setIndex(i),
          destinations: _destinations,
        ),
      ),
    );
  }
}
