import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/youtube_helper.dart';
import '../../../models/song_model.dart';
import 'youtube_video_player.dart';

/// Panggung Karaoke Cinema Terbuka (Tanpa Card Box Sempit & Tanpa Visualizer).
class PlayerDisplay extends StatelessWidget {
  final SongModel? song;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final int queueCount;
  final VoidCallback? onToggleFullscreen;
  final bool isFullscreen;
  final YoutubePlayerController? youtubeController;
  final bool isTestMode;
  final VoidCallback? onPlayPauseTapped;
  final VoidCallback? onOpenSearchModal;

  const PlayerDisplay({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    this.queueCount = 0,
    this.onToggleFullscreen,
    this.isFullscreen = false,
    this.youtubeController,
    this.isTestMode = false,
    this.onPlayPauseTapped,
    this.onOpenSearchModal,
  });

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubeHelper.extractVideoId(song?.songurl);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Top Mini Bar (Hanya tampil jika ada antrean)
            if (queueCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryElectric.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentCyan.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.queue_music_rounded,
                        size: 14,
                        color: AppColors.accentSky,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$queueCount antrean',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentSky,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Main Stage Area (Luas & Terbuka: Langsung Video YouTube)
            if (song != null) ...[
              YoutubeVideoPlayerWidget(
                controller: youtubeController,
                videoId: videoId,
                songTitle: song!.songtitle,
                songSinger: song!.songsinger,
                isPlaying: isPlaying,
                onPlayTapped: onPlayPauseTapped,
                isTestMode: isTestMode,
              ),

              if (constraints.maxWidth >= 650) ...[
                const SizedBox(height: 10),

                // Song Info: Judul & Penyanyi (Desktop only)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song!.songtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song!.songsinger,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentSky,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Empty State Awal (Minimalis & Elegan)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryElectric.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AppColors.accentCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 32,
                        color: AppColors.accentLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Player',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (onOpenSearchModal != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: onOpenSearchModal,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Pilih Lagu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryElectric,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
