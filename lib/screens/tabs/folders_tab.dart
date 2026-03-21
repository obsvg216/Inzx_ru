import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/design_system/design_system.dart';
import '../../providers/providers.dart';
import '../../services/local_music_scanner.dart';

class MusicFoldersTab extends ConsumerStatefulWidget {
  const MusicFoldersTab({super.key});

  @override
  ConsumerState<MusicFoldersTab> createState() => _MusicFoldersTabState();
}

class _MusicFoldersTabState extends ConsumerState<MusicFoldersTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final folders = ref.watch(musicFoldersProvider);

    final albumColors = ref.watch(albumColorsProvider);
    final hasAlbumColors = !albumColors.isDefault;
    final accentColor = hasAlbumColors
        ? albumColors.accent
        : colorScheme.primary;

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(isDark, colorScheme, accentColor),

          // Content
          Expanded(
            child: folders.isEmpty
                ? _buildEmptyState(isDark, colorScheme, accentColor)
                : _buildFoldersList(folders, isDark, colorScheme, accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Папки',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : InzxColors.textPrimary,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _showFolderSettings(),
                icon: Icon(
                  Icons.settings_rounded,
                  color: isDark ? Colors.white70 : InzxColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => _addFolder(),
                icon: Icon(
                  Icons.folder_add_rounded,
                  color: isDark ? Colors.white70 : InzxColors.textPrimary,
                ),
              ),
            ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: isDark
                    ? Colors.white38
                    : accentColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Папки ещё не добавлены',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : InzxColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Добавьте папки с музыкой для сканирования',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : InzxColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _addFolder(),
              icon: const Icon(Icons.folder_add_rounded),
              label: const Text('Добавить папку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: InzxColors.contrastTextOn(accentColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersList(
    List<String> folders,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return _buildFolderTile(folder, isDark, colorScheme, accentColor);
      },
    );
  }

  Widget _buildFolderTile(
    String folder,
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.folder_rounded,
            color: accentColor,
            size: 28,
          ),
        ),
        title: Text(
          folder,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : InzxColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Нажмите для сканирования',
          style: TextStyle(
            color: isDark ? Colors.white54 : InzxColors.textSecondary,
          ),
        ),
        trailing: IconButton(
          onPressed: () => _removeFolder(folder),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: isDark ? Colors.white54 : InzxColors.textSecondary,
          ),
        ),
        onTap: () => _scanFolder(folder),
      ),
    );
  }

  Widget _buildLocalMusicSection(
    bool isDark,
    ColorScheme colorScheme,
    Color accentColor,
  ) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Локальная музыка',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : InzxColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Просканируйте устройство для поиска локальных файлов и воспроизведения офлайн',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : InzxColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _scanAllMusic(),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Сканировать музыку'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: InzxColors.contrastTextOn(accentColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addFolder(),
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Добавить папку'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Поддерживаемые форматы: MP3, FLAC, WAV, M4A, OGG',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : InzxColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки папок'),
        content: const Text('Папки ещё не добавлены'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFolder() async {
    // Check permissions
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      final result = await Permission.storage.request();
      if (!result.isGranted) {
        _showPermissionDialog();
        return;
      }
    }

    // Pick folder
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      _showFolderAddedDialog(path);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется разрешение'),
        content: Text(
          'Требуется разрешение на доступ к хранилищу для сканирования музыки.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  void _showFolderAddedDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Папка добавлена'),
        content: Text('Просканировать её на наличие музыки сейчас?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Позже'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _scanFolder(path);
            },
            child: const Text('Сканировать сейчас'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanFolder(String path) async {
    final scanner = ref.read(localMusicScannerProvider);
    final result = await scanner.scanFolder(path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Найдено ${result.length} треков в 1 папке'),
        ),
      );
    }
  }

  Future<void> _scanAllMusic() async {
    // Scan all music logic
  }

  void _removeFolder(String folder) {
    // Remove folder logic
  }
}
