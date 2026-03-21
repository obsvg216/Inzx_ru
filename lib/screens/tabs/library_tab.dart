import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/design_system/design_system.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../widgets/now_playing_screen.dart';
import '../widgets/track_options_sheet.dart';

class MusicLibraryTab extends ConsumerStatefulWidget {
  const MusicLibraryTab({super.key});

  @override
  ConsumerState<MusicLibraryTab> createState() => _MusicLibraryTabState();
}

class _MusicLibraryTabState extends ConsumerState<MusicLibraryTab> {
  String _selectedCategory = 'Плейлисты';
  final _categories = ['Плейлисты', 'Альбомы', 'Исполнители', 'Скачанные'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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

          // Category tabs
          _buildCategoryTabs(isDark, colorScheme, accentColor),

          // Content
          Expanded(
            child: _buildContent(isDark, colorScheme, accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Библиотека',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : InzxColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => _showCreatePlaylistDialog(),
            icon: Icon(
              Icons.add_rounded,
              color: isDark ? Colors.white70 : InzxColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: accentColor.withValues(alpha: 0.2),
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white70 : InzxColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? accentColor : Colors.transparent,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    switch (_selectedCategory) {
      case 'Плейлисты':
        return _buildPlaylistsContent(isDark, colorScheme, accentColor);
      case 'Альбомы':
        return _buildAlbumsContent(isDark, colorScheme, accentColor);
      case 'Исполнители':
        return _buildArtistsContent(isDark, colorScheme, accentColor);
      case 'Скачанные':
        return _buildDownloadsContent(isDark, colorScheme, accentColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaylistsContent(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    final playlists = ref.watch(userPlaylistsProvider);
    final likedSongs = ref.watch(likedSongsProvider);
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);

    final autoPlaylists = [
      ('Понравившиеся треки', Icons.favorite_rounded, Colors.pink, likedSongs.length, 'liked'),
      ('Часто воспроизводимые', Icons.bar_chart_rounded, Colors.blue, recentlyPlayed.length, 'most_played'),
      ('Недавно воспроизведённые', Icons.history_rounded, Colors.orange, recentlyPlayed.length, 'recent'),
      ('Скачанные', Icons.download_rounded, Colors.green, 0, 'downloaded'),
    ];

    return playlists.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(isDark, 'Ошибка загрузки плейлистов'),
      data: (data) {
        if (data.isEmpty && autoPlaylists.every((p) => p.$4 == 0)) {
          return _buildEmptyState(
            isDark,
            colorScheme,
            accentColor,
            'Пока нет плейлистов',
            'Создайте плейлист для организации музыки',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Auto playlists section
            Text(
              'Авто-плейлисты',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : InzxColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...autoPlaylists.map((playlist) => _buildAutoPlaylistTile(
                  playlist.$1,
                  playlist.$2,
                  playlist.$3,
                  playlist.$4,
                  playlist.$5,
                  isDark,
                  colorScheme,
                )),
            const SizedBox(height: 24),
            // User playlists section
            Text(
              'Ваши плейлисты',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : InzxColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (data.isEmpty)
              _buildEmptyState(
                isDark,
                colorScheme,
                accentColor,
                'Нет плейлистов',
                'Нажмите + чтобы создать новый',
              )
            else
              ...data.map((playlist) => _buildPlaylistTile(
                    playlist,
                    isDark,
                    colorScheme,
                    accentColor,
                  )),
          ],
        );
      },
    );
  }

  Widget _buildAutoPlaylistTile(
    String title,
    IconData icon,
    Color color,
    int count,
    String id,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : InzxColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '$count треков',
        style: TextStyle(
          color: isDark ? Colors.white54 : InzxColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.white54 : InzxColors.textSecondary,
      ),
      onTap: () => _openPlaylist(id),
    );
  }

  Widget _buildPlaylistTile(
    Playlist playlist,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: playlist.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: playlist.imageUrl!,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: accentColor.withValues(alpha: 0.2),
                  child: Icon(Icons.playlist_play_rounded, color: accentColor),
                ),
        ),
      ),
      title: Text(
        playlist.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : InzxColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '${playlist.trackCount} треков',
        style: TextStyle(
          color: isDark ? Colors.white54 : InzxColors.textSecondary,
        ),
      ),
      trailing: IconButton(
        onPressed: () => _showPlaylistOptions(playlist),
        icon: Icon(
          Icons.more_vert_rounded,
          color: isDark ? Colors.white54 : InzxColors.textSecondary,
        ),
      ),
      onTap: () => _openPlaylist(playlist.id),
    );
  }

  Widget _buildAlbumsContent(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    final albums = ref.watch(savedAlbumsProvider);

    return albums.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(isDark, 'Ошибка загрузки альбомов'),
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState(
            isDark,
            colorScheme,
            accentColor,
            'Нет сохранённых альбомов из YouTube Music',
            'Сохраняйте альбомы для быстрого доступа',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final album = data[index];
            return _buildAlbumGridItem(album, isDark, colorScheme, accentColor);
          },
        );
      },
    );
  }

  Widget _buildAlbumGridItem(
    Album album,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: () => _openAlbum(album),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: album.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: album.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: accentColor.withValues(alpha: 0.2),
                      child: Icon(Icons.album_rounded,
                          color: accentColor, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : InzxColors.textPrimary,
            ),
          ),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : InzxColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsContent(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    final artists = ref.watch(subscribedArtistsProvider);

    return artists.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(isDark, 'Ошибка загрузки исполнителей'),
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState(
            isDark,
            colorScheme,
            accentColor,
            'Нет подписок на исполнителей',
            'Подписывайтесь на исполнителей для обновлений',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final artist = data[index];
            return _buildArtistGridItem(artist, isDark, colorScheme, accentColor);
          },
        );
      },
    );
  }

  Widget _buildArtistGridItem(
    Artist artist,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: () => _openArtist(artist),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: accentColor.withValues(alpha: 0.2),
            backgroundImage: artist.imageUrl != null
                ? CachedNetworkImageProvider(artist.imageUrl!)
                : null,
            child: artist.imageUrl == null
                ? Icon(Icons.person_rounded,
                    color: accentColor, size: 40)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            artist.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : InzxColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsContent(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    final downloadedTracks = ref.watch(downloadedTracksProvider);

    return downloadedTracks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(isDark, 'Ошибка загрузки скачанных треков'),
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState(
            isDark,
            colorScheme,
            accentColor,
            'Пока нет скачанных треков',
            'Скачанные треки появятся здесь',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final track = data[index];
            return _buildDownloadTile(track, isDark, colorScheme, accentColor);
          },
        );
      },
    );
  }

  Widget _buildDownloadTile(
    Track track,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: track.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: track.thumbnailUrl!,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: accentColor.withValues(alpha: 0.2),
                  child: Icon(Icons.music_note_rounded, color: accentColor),
                ),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : InzxColors.textPrimary,
        ),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDark ? Colors.white54 : InzxColors.textSecondary,
        ),
      ),
      trailing: IconButton(
        onPressed: () => _confirmDeleteDownload(track),
        icon: Icon(
          Icons.delete_outline_rounded,
          color: isDark ? Colors.white54 : InzxColors.textSecondary,
        ),
      ),
      onTap: () => _playTrack(track),
    );
  }

  Widget _buildEmptyState(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
    String message,
    String subMessage,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.folder_open_rounded,
                size: 48,
                color: isDark
                    ? Colors.white38
                    : accentColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : InzxColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : InzxColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark ? Colors.white54 : InzxColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : InzxColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать плейлист'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Название плейлиста',
            hintText: 'Введите название плейлиста',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _createPlaylist(String name) {
    // Create playlist logic
  }

  void _openPlaylist(String id) {
    // Open playlist
  }

  void _showPlaylistOptions(Playlist playlist) {
    // Show options sheet
  }

  void _openAlbum(Album album) {
    // Open album
  }

  void _openArtist(Artist artist) {
    // Open artist
  }

  void _playTrack(Track track) async {
    final playerService = ref.read(audioPlayerServiceProvider);
    await playerService.playQueue([track], startIndex: 0);
    if (mounted) NowPlayingScreen.show(context);
  }

  void _confirmDeleteDownload(Track track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить загрузку'),
        content: Text(
          'Это удалит файл с устройства. Вы сможете скачать его позже.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _deleteDownload(track);
              Navigator.pop(context);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _deleteDownload(Track track) {
    // Delete download logic
  }
}
