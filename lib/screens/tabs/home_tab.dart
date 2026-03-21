import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/design_system/design_system.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../widgets/now_playing_screen.dart';

class MusicHomeTab extends ConsumerStatefulWidget {
  const MusicHomeTab({super.key});

  @override
  ConsumerState<MusicHomeTab> createState() => _MusicHomeTabState();
}

class _MusicHomeTabState extends ConsumerState<MusicHomeTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final shelves = ref.watch(homeShelvesProvider);
    final userName = ref.watch(userProfileProvider).whenOrNull(
          (profile) => profile?.name ?? 'Пользователь',
        ) ??
        'Пользователь';

    final albumColors = ref.watch(albumColorsProvider);
    final hasAlbumColors = !albumColors.isDefault;
    final accentColor = hasAlbumColors
        ? albumColors.accent
        : colorScheme.primary;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(isDark, colorScheme, userName),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: _buildSearchBar(isDark, colorScheme, accentColor),
          ),

          // YouTube Music connect card
          SliverToBoxAdapter(
            child: _buildYTConnectCard(isDark, colorScheme, accentColor),
          ),

          // Section title
          SliverToBoxAdapter(
            child: _buildSectionTitle(
              isDark,
              colorScheme,
              'МУЗЫКА ДЛЯ СТАРТА',
            ),
          ),

          // Shelves
          if (shelves.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (shelves.hasError)
            SliverToBoxAdapter(
              child: _buildErrorState(isDark, colorScheme),
            )
          else
            ...shelves.whenOrNull((data) => data.map((shelf) {
                  return SliverToBoxAdapter(
                    child: _buildShelf(
                      shelf,
                      isDark,
                      colorScheme,
                      accentColor,
                    ),
                  );
                }).toList() ??
                []),

          // Quick mixes
          SliverToBoxAdapter(
            child: _buildSectionTitle(
              isDark,
              colorScheme,
              'Смешано для вас',
            ),
          ),
          SliverToBoxAdapter(
            child: _buildQuickMixes(isDark, colorScheme, accentColor),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    bool isDark,
    ColorScheme colorScheme,
    String userName,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'С возвращением,',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : InzxColors.textSecondary,
                ),
              ),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : InzxColors.textPrimary,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(
              Icons.person_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark ? Colors.white54 : InzxColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск треков, альбомов, исполнителей',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : InzxColors.textSecondary,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : InzxColors.textPrimary,
                  fontSize: 15,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
                onSubmitted: (value) => _performSearch(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYTConnectCard(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    final isLoggedIn = ref.watch(ytMusicAuthProvider).whenOrNull(
          (auth) => auth?.isLoggedIn ?? false,
        ) ??
        false;

    if (isLoggedIn) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.3),
              accentColor.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Подключить YouTube Music',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : InzxColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Синхронизируйте понравившиеся треки, плейлисты и другое',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : InzxColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _connectYTMusic(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: InzxColors.contrastTextOn(accentColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Подключить'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.youtube_searched_for_rounded,
              size: 48,
              color: accentColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : InzxColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildShelf(
    Shelf shelf,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shelf.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : InzxColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => _seeAll(shelf),
                child: const Text('Все'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shelf.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = shelf.items[index];
              return _buildShelfItem(item, isDark, colorScheme, accentColor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShelfItem(
    ShelfItem item,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: () => _openItem(item),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            _defaultArtwork(colorScheme, accentColor),
                        errorWidget: (_, __, ___) =>
                            _defaultArtwork(colorScheme, accentColor),
                      )
                    : _defaultArtwork(colorScheme, accentColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : InzxColors.textPrimary,
              ),
            ),
            if (item.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                item.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : InzxColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _defaultArtwork(ColorScheme colorScheme, Color accentColor) {
    return Container(
      color: accentColor.withValues(alpha: 0.2),
      child: Icon(Icons.music_note_rounded, color: accentColor, size: 32),
    );
  }

  Widget _buildQuickMixes(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    final mixes = [
      ('Мой микс 1', 'На основе ваших прослушиваний', Colors.indigo),
      ('Микс открытий', 'Новая музыка для вас', Colors.teal),
      ('Микс повторений', 'Ваши фавориты', Colors.orange),
      ('Новинки', 'Свежие треки', Colors.pink),
      ('Спокойный микс', 'Расслабляющая атмосфера', Colors.blue),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: mixes.map((mix) {
          final (title, subtitle, color) = mix;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.4),
                    color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : InzxColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white70
                                : InzxColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _playMix(title),
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                      color: isDark ? Colors.white : InzxColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark ? Colors.white54 : InzxColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Не удалось загрузить данные',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : InzxColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Проверьте подключение к интернету',
              style: TextStyle(
                color: isDark ? Colors.white54 : InzxColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(homeShelvesProvider),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    // Navigate to search screen
    // Navigator.push(context, MaterialPageRoute(...));
  }

  void _connectYTMusic() {
    // Connect to YouTube Music
    // ref.read(ytMusicAuthProvider).connect();
  }

  void _seeAll(Shelf shelf) {
    // Navigate to see all
  }

  void _openItem(ShelfItem item) {
    // Open item details
  }

  void _playMix(String title) {
    // Play mix
  }
}
