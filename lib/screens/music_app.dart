import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system/design_system.dart';
import 'tabs/home_tab.dart';
import 'tabs/songs_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/folders_tab.dart';
import 'widgets/now_playing_screen.dart';
import '../providers/providers.dart';

class MusicApp extends ConsumerStatefulWidget {
  const MusicApp({super.key});

  @override
  ConsumerState<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends ConsumerState<MusicApp> {
  int _currentIndex = 0;

  static const _navItems = [
    (Icons.home_outlined, Icons.home_rounded, 'Главная'),
    (Icons.music_note_outlined, Icons.music_note_rounded, 'Треки'),
    (Icons.library_music_outlined, Icons.library_music_rounded, 'Библиотека'),
    (Icons.folder_outlined, Icons.folder_rounded, 'Папки'),
  ];

  final List<Widget> _tabs = const [
    MusicHomeTab(),
    MusicSongsTab(),
    MusicLibraryTab(),
    MusicFoldersTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final playbackState = ref.watch(playbackStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _tabs[_currentIndex],

          // Mini player
          if (playbackState.whenOrNull((s) => s.currentTrack) != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => NowPlayingScreen.show(context),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _buildMiniPlayer(isDark, colorScheme),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isDark, colorScheme),
    );
  }

  Widget _buildMiniPlayer(bool isDark, ColorScheme colorScheme) {
    final playbackState = ref.watch(playbackStateProvider);
    final currentTrack = playbackState.whenOrNull((s) => s.currentTrack);
    final isPlaying = playbackState.whenOrNull((s) => s.isPlaying) ?? false;

    if (currentTrack == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 48,
              child: currentTrack.thumbnailUrl != null
                  ? Image.network(
                      currentTrack.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultArtwork(colorScheme),
                    )
                  : _defaultArtwork(colorScheme),
            ),
          ),
          const SizedBox(width: 12),
          // Track info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTrack.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : InzxColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentTrack.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : InzxColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Play/pause button
          IconButton(
            onPressed: () {
              final playerService = ref.read(audioPlayerServiceProvider);
              if (isPlaying) {
                playerService.pause();
              } else {
                playerService.play();
              }
            },
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 32,
              color: isDark ? Colors.white : InzxColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultArtwork(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.2),
      child: Icon(Icons.music_note_rounded, color: colorScheme.primary),
    );
  }

  Widget _buildBottomNavigationBar(bool isDark, ColorScheme colorScheme) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      backgroundColor: isDark
          ? Colors.black.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
      destinations: _navItems.map((item) {
        final (iconOutlined, iconRounded, label) = item;
        return NavigationDestination(
          icon: Icon(iconOutlined, size: 24),
          selectedIcon: Icon(iconRounded, size: 24),
          label: label,
        );
      }).toList(),
    );
  }
}
