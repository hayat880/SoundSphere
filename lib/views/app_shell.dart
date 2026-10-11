import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../main_handlers.dart';
import 'explore/explore_screen.dart';
import 'focus/focus_screen.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'search/search_screen.dart';
import 'widgets/mini_player.dart';

/// Bottom navigation: Home, Search, Library, Focus.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  StreamSubscription<String>? _messageSub;

  @override
  void initState() {
    super.initState();
    // Break alerts come from the NotificationHandler (an event handler).
    _messageSub = context.read<AppHandlers>().notification.messages.listen((m) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenFocus: () => setState(() => _index = 4)),
          const ExploreScreen(),
          const SearchScreen(),
          const LibraryScreen(),
          Theme(data: AppTheme.dark, child: const FocusScreen()),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.forest,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.forest,
              selectedItemColor: AppColors.terracotta,
              unselectedItemColor: AppColors.sage,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Explore'),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), activeIcon: Icon(Icons.library_music), label: 'Library'),
                BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), activeIcon: Icon(Icons.timer), label: 'Focus'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
