import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/design_system/design_system.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/local_music_scanner.dart';
import '../../services/download_service.dart';
import '../widgets/track_options_sheet.dart';
import '../widgets/now_playing_screen.dart';

/// Provider that combines all songs from multiple sources
final allSongsProvider = Provider((ref) {
  final recentlyPlayed = ref.watch(recentlyPlayedProvider);
  final likedSongs = ref.watch(likedSongsProvider);
  final localTracks = ref.watch(localTracksProvider);

  // Downloaded tracks from Hive
  final downloadedTracks =
      ref.watch(downloadedTracksProvider).valueOrNull ?? [];

  // YT Music liked songs if logged in
  final ytLikedSongs = ref.watch(ytMusicLikedSongsProvider).valueOrNull ?? [];

  // Combine all sources, removing duplicates by ID
  final allTracks = <Track>{};

  // Priority: downloaded > local > yt liked > local liked > recently played
  for (final track in recentlyPlayed) {
    allTracks[track.id] = track;
  }
  for (final track in likedSongs) {
    allTracks[track.id] = track;
  }
  for (final track in ytLikedSongs) {
    allTracks[track.id] = track;
  }
  for (final track in localTracks) {
    allTracks[track.id] = track;
  }
  // Downloaded tracks have highest priority (they have local files)
  for (final track in downloadedTracks) {
    allTracks[track.id] = track;
  }

  return allTracks.values.toList();
});

/// Songs tab with filter chips and song list
class MusicSongsTab extends ConsumerStatefulWidget {
  const MusicSongsTab({super.key});

  @override
  ConsumerState createState() => _MusicSongsTabState();
}

class _MusicSongsTabState extends ConsumerState<MusicSongsTab> {
  String _selectedFilter = 'Все';
  String _sortBy = 'Недавно добавленные';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isSearching = false;

  final _filters = ['Все', 'Понравившиеся', 'Локальные', 'Скачанные'];
  final _sortOptions = ['Недавно добавленные', 'Название', 'Исполнитель', 'Длительность'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Track> _getFilteredTracks(List<Track> allTracks) {
    var tracks = List<Track>.from(allTracks);

    // Apply filter
    switch (_selectedFilter) {
      case 'Понравившиеся':
        final likedIds = ref.read(likedSongsProvider).map((t) => t.id).toSet();
        final ytLikedIds =
            (ref.read(ytMusicLikedSongsProvider).valueOrNull ?? [])
                .map((t) => t.id)
                .toSet();
        tracks = tracks
            .where((t) => likedIds.contains(t.id) || ytLikedIds.contains(t.id))
            .toList();
        break;
      case 'Локальные':
        final localIds = ref.read(localTracksProvider).map((t) => t.id).toSet();
        tracks = tracks.where((t) => localIds.contains(t.id)).toList();
        break;
      case 'Скачанные':
        // Only show tracks that have a local file path (downloaded)
        tracks = tracks.where((t) => t.localFilePath != null).toList();
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      tracks = tracks
          .where(
            (t) =>
                t.title.toLowerCase().contains(query) ||
                t.artist.toLowerCase().contains(query) ||
                (t.album?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    // Apply sort
    switch (_sortBy) {
      case 'Название':
        tracks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Исполнитель':
        tracks.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case 'Длительность':
        tracks.sort(
          (a, b) =>
              a.duration.inMilliseconds.compareTo(b.duration.inMilliseconds),
        );
        break;
      case 'Недавно добавленные':
      default:
        // Keep original order (most recent first)
        break;
    }

    return tracks;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final allTracks = ref.watch(allSongsProvider);
    final filteredTracks = _getFilteredTracks(allTracks);

    // Get dynamic colors from album art
    final albumColors = ref.watch(albumColorsProvider);
    final hasAlbumColors = !albumColors.isDefault;
    final accentColor = hasAlbumColors
        ? albumColors.accent
        : colorScheme.primary;

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(isDark, colorScheme),

          // Filter chips
          _buildFilterChips(isDark, colorScheme, accentColor),

          // Sort row and count
          _buildSortRow(
            isDark,
            colorScheme,
            filteredTracks.length,
            accentColor,
          ),

          // Song list
          Expanded(
            child: filteredTracks.isEmpty
                ? _buildEmptyState(isDark, colorScheme, accentColor)
                : _buildSongList(
                    filteredTracks,
                    isDark,
                    colorScheme,
                    accentColor,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_isSearching)
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? Colors.white54 : InzxColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Поиск треков...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : InzxColors.textSecondary,
                          ),
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : InzxColors.textPrimary,
                          fontSize: 15,
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              'Треки',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : InzxColors.textPrimary,
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: isDark ? Colors.white70 : InzxColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
              selectedColor: accentColor.withValues(alpha: 0.2),
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white70 : InzxColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? accentColor : Colors.transparent,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortRow(
    bool isDark,
    ColorScheme colorScheme,
    int count,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Треков: $count',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : InzxColors.textSecondary,
                ),
              ),
            ],
          ),
          PopupMenuButton(
            onSelected: (value) => setState(() => _sortBy = value),
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => _sortOptions.map((option) {
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (_sortBy == option)
                      Icon(Icons.check_rounded, size: 18, color: accentColor)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(option),
                  ],
                ),
              );
            }).toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 18,
                  color: isDark ? Colors.white54 : InzxColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _sortBy,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : InzxColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: isDark ? Colors.white54 : InzxColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    String message;
    String subMessage;

    switch (_selectedFilter) {
      case 'Понравившиеся':
        message = 'Нет понравившихся треков';
        subMessage = 'Отмечайте треки лайками, чтобы они появились здесь';
        break;
      case 'Локальные':
        message = 'Нет локальных треков';
        subMessage = 'Просканируйте папки для поиска локальной музыки';
        break;
      case 'Скачанные':
        message = 'Нет скачанных треков';
        subMessage = 'Скачайте треки для прослушивания офлайн';
        break;
      default:
        if (_searchQuery.isNotEmpty) {
          message = 'Ничего не найдено';
          subMessage = 'Попробуйте другие ключевые слова';
        } else {
          message = 'Пока нет треков';
          subMessage = 'Включите музыку, чтобы сформировать библиотеку';
        }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.music_note_rounded,
              size: 48,
              color: isDark
                  ? Colors.white38
                  : accentColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : InzxColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: TextStyle(
              color: isDark ? Colors.white54 : InzxColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList(
    List<Track> tracks,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: tracks.length + 1, // +1 for play all header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildPlayAllHeader(
                tracks,
                isDark,
                colorScheme,
                accentColor,
              );
            }
            return _buildSongTile(
              tracks[index - 1],
              index - 1,
              tracks,
              isDark,
              colorScheme,
              accentColor,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayAllHeader(
    List<Track> tracks,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Play all button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _playAll(tracks),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Воспроизвести все'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: InzxColors.contrastTextOn(accentColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Shuffle button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shuffleAll(tracks),
              icon: const Icon(Icons.shuffle_rounded),
              label: const Text('Перемешать'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: accentColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(
    Track track,
    int index,
    List<Track> allTracks,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    final playbackState = ref.watch(playbackStateProvider);
    final isCurrentTrack =
        playbackState.whenOrNull(data: (s) => s.currentTrack?.id == track.id) ??
            false;
    final isPlaying =
        playbackState.whenOrNull(data: (s) => s.isPlaying) ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            children: [
              track.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      placeholder: (_, __) =>
                          _defaultArtwork(colorScheme, accentColor),
                      errorWidget: (_, __, ___) =>
                          _defaultArtwork(colorScheme, accentColor),
                    )
                  : _defaultArtwork(colorScheme, accentColor),
              if (isCurrentTrack)
                Container(
                  color: Colors.black45,
                  child: Center(
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.w500,
          fontSize: 15,
          color: isCurrentTrack
              ? accentColor
              : (isDark ? Colors.white : InzxColors.textPrimary),
        ),
      ),
      subtitle: Text(
        '${track.artist} • ${track.formattedDuration}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white54 : InzxColors.textSecondary,
        ),
      ),
      trailing: IconButton(
        onPressed: () => TrackOptionsSheet.show(context, track),
        icon: Icon(
          Icons.more_vert_rounded,
          color: isDark ? Colors.white54 : InzxColors.textSecondary,
        ),
      ),
      onTap: () async {
        final playerService = ref.read(audioPlayerServiceProvider);
        // Play from this position in the list
        await playerService.playQueue(allTracks, startIndex: index);
        if (mounted) NowPlayingScreen.show(context);
      },
    );
  }

  Widget _defaultArtwork(ColorScheme colorScheme, Color accentColor) {
    return Container(
      width: 52,
      height: 52,
      color: accentColor.withValues(alpha: 0.2),
      child: Icon(Icons.music_note_rounded, color: accentColor, size: 24),
    );
  }

  void _playAll(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    final playerService = ref.read(audioPlayerServiceProvider);
    await playerService.playQueue(tracks, startIndex: 0);
    if (mounted) NowPlayingScreen.show(context);
  }

  void _shuffleAll(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    final shuffled = List<Track>.from(tracks)..shuffle();
    final playerService = ref.read(audioPlayerServiceProvider);
    await playerService.playQueue(shuffled, startIndex: 0);
    if (mounted) NowPlayingScreen.show(context);
  }
}
