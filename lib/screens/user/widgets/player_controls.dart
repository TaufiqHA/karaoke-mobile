import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/song_model.dart';

/// Bar kontrol pemutaran studio karaoke (3 Kolom Simetris & Rapi).
/// Kolom Kiri: Info lagu aktif & ikon musik
/// Kolom Tengah: Tombol navigasi playback simetris & seekbar waktu presisi
/// Kolom Kanan: Pengatur volume horizontal & toggle fullscreen
class PlayerControls extends StatefulWidget {
  final SongModel? song;
  final bool isPlaying;
  final bool hasSong;
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onTogglePlayPause;
  final VoidCallback? onStop;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final double volume; // 0.0 - 1.0
  final bool isMuted;
  final ValueChanged<double>? onVolumeChanged;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleFullscreen;
  final bool isFullscreen;
  final VoidCallback? onCastTapped;
  final bool isCasting;

  const PlayerControls({
    super.key,
    this.song,
    required this.isPlaying,
    required this.hasSong,
    required this.currentPosition,
    required this.totalDuration,
    this.onSeek,
    this.onTogglePlayPause,
    this.onStop,
    this.onNext,
    this.onPrevious,
    this.volume = 0.8,
    this.isMuted = false,
    this.onVolumeChanged,
    this.onToggleMute,
    this.onToggleFullscreen,
    this.isFullscreen = false,
    this.onCastTapped,
    this.isCasting = false,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _isDragging = false;
  double _dragPosition = 0.0;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final double maxSeconds = widget.totalDuration.inSeconds > 0
        ? widget.totalDuration.inSeconds.toDouble()
        : 1.0;
    final double currentSeconds = widget.currentPosition.inSeconds
        .clamp(0, maxSeconds.toInt())
        .toDouble();
    final double sliderValue = _isDragging
        ? _dragPosition.clamp(0.0, maxSeconds)
        : (widget.hasSong ? currentSeconds : 0.0).clamp(0.0, maxSeconds);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 16,
            vertical: isNarrow ? 6 : 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: isNarrow
              ? _buildMobileLayout(context, sliderValue, maxSeconds)
              : _buildDesktopLayout(context, sliderValue, maxSeconds),
        );
      },
    );
  }

  /// Layout Desktop: 3 Kolom Seimbang (Kiri: Info Lagu, Tengah: Playback + Seekbar, Kanan: Volume + Fullscreen)
  Widget _buildDesktopLayout(
    BuildContext context,
    double sliderValue,
    double maxSeconds,
  ) {
    final song = widget.song;
    final hasSong = widget.hasSong;
    final isPlaying = widget.isPlaying;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Kolom Kiri (flex 3): Info Lagu Aktif
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primaryElectric.withValues(alpha: 0.2),
                  border: Border.all(
                    color: isPlaying
                        ? AppColors.accentCyan.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Icon(
                    isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                    color: isPlaying ? AppColors.accentCyan : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song?.songtitle ?? 'Player',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (song != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        song.songsinger,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accentSky,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // 2. Kolom Tengah (flex 5): Playback Buttons & Seekbar
        Expanded(
          flex: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Playback Navigation Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: hasSong ? widget.onStop : null,
                    tooltip: 'Berhenti',
                    icon: const Icon(Icons.stop_rounded),
                    color: hasSong && isPlaying ? AppColors.error : AppColors.textMuted,
                    iconSize: 26,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 14),

                  // Main Play / Pause Button
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: hasSong ? widget.onTogglePlayPause : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasSong ? AppColors.buttonGradient : null,
                        color: hasSong ? null : Colors.white.withValues(alpha: 0.08),
                        boxShadow: hasSong && isPlaying
                            ? [
                                BoxShadow(
                                  color: AppColors.accentCyan.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: hasSong ? Colors.white : AppColors.textMuted,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Seekbar Row with Timers
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      _formatDuration(
                        _isDragging
                            ? Duration(seconds: _dragPosition.toInt())
                            : widget.currentPosition,
                      ),
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentLight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 9),
                        activeTrackColor: hasSong ? AppColors.accentCyan : AppColors.textMuted,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                        thumbColor: hasSong ? Colors.white : AppColors.textMuted,
                        overlayColor: AppColors.accentCyan.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: sliderValue,
                        min: 0.0,
                        max: hasSong ? maxSeconds : 1.0,
                        onChangeStart: hasSong
                            ? (val) {
                                setState(() {
                                  _isDragging = true;
                                  _dragPosition = val;
                                });
                              }
                            : null,
                        onChanged: hasSong
                            ? (val) {
                                setState(() {
                                  _dragPosition = val;
                                });
                              }
                            : null,
                        onChangeEnd: hasSong
                            ? (val) {
                                setState(() {
                                  _isDragging = false;
                                });
                                widget.onSeek?.call(Duration(seconds: val.toInt()));
                              }
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      _formatDuration(widget.totalDuration),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // 3. Kolom Kanan (flex 3): Volume & Fullscreen Button
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: widget.onToggleMute,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
                tooltip: widget.isMuted ? 'Batal Bisukan' : 'Bisukan',
                icon: Icon(
                  widget.isMuted || widget.volume == 0.0
                      ? Icons.volume_off_rounded
                      : (widget.volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                  color: widget.isMuted ? AppColors.error : AppColors.accentSky,
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 65,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                    activeTrackColor: widget.isMuted ? AppColors.textMuted : AppColors.accentCyan,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: widget.isMuted ? 0.0 : widget.volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      widget.onVolumeChanged?.call(val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${(widget.isMuted ? 0 : (widget.volume * 100).toInt())}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              if (widget.onCastTapped != null) ...[
                const SizedBox(width: 2),
                IconButton(
                  onPressed: widget.onCastTapped,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  visualDensity: VisualDensity.compact,
                  tooltip: widget.isCasting ? 'Putus Cast' : 'Cast ke TV',
                  icon: Icon(
                    widget.isCasting ? Icons.cast_connected_rounded : Icons.cast_rounded,
                    color: widget.isCasting ? AppColors.accentCyan : AppColors.accentSky,
                    size: 18,
                  ),
                ),
              ],
              if (widget.onToggleFullscreen != null) ...[
                const SizedBox(width: 2),
                IconButton(
                  onPressed: widget.onToggleFullscreen,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  visualDensity: VisualDensity.compact,
                  tooltip: widget.isFullscreen ? 'Perkecil Layar' : 'Layar Penuh',
                  icon: Icon(
                    widget.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                    color: AppColors.accentSky,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Layout Mobile: Vertikal Teratur & Sangat Kompak
  Widget _buildMobileLayout(
    BuildContext context,
    double sliderValue,
    double maxSeconds,
  ) {
    final song = widget.song;
    final hasSong = widget.hasSong;
    final isPlaying = widget.isPlaying;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Info Lagu & Volume Row (1 Baris Ringkas)
        Row(
          children: [
            Expanded(
              child: Text(
                song != null
                    ? '${song.songtitle} • ${song.songsinger}'
                    : 'Player',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onToggleMute,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(
                widget.isMuted || widget.volume == 0.0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: widget.isMuted ? AppColors.error : AppColors.accentSky,
              ),
            ),
            SizedBox(
              width: 55,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 6),
                  activeTrackColor: AppColors.accentCyan,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: widget.isMuted ? 0.0 : widget.volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (val) => widget.onVolumeChanged?.call(val),
                ),
              ),
            ),
          ],
        ),

        // 2. Seekbar
        Row(
          children: [
            Text(
              _formatDuration(
                _isDragging
                    ? Duration(seconds: _dragPosition.toInt())
                    : widget.currentPosition,
              ),
              style: const TextStyle(fontSize: 10, color: AppColors.accentLight),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 6),
                  activeTrackColor: AppColors.accentCyan,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: sliderValue,
                  min: 0.0,
                  max: hasSong ? maxSeconds : 1.0,
                  onChangeStart: hasSong
                      ? (val) {
                          setState(() {
                            _isDragging = true;
                            _dragPosition = val;
                          });
                        }
                      : null,
                  onChanged: hasSong
                      ? (val) {
                          setState(() {
                            _dragPosition = val;
                          });
                        }
                      : null,
                  onChangeEnd: hasSong
                      ? (val) {
                          setState(() {
                            _isDragging = false;
                          });
                          widget.onSeek?.call(Duration(seconds: val.toInt()));
                        }
                      : null,
                ),
              ),
            ),
            Text(
              _formatDuration(widget.totalDuration),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),

        // 3. Playback Navigation Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: hasSong ? widget.onStop : null,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.stop_rounded),
              color: hasSong && isPlaying ? AppColors.error : AppColors.textMuted,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: hasSong ? widget.onTogglePlayPause : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasSong ? AppColors.buttonGradient : null,
                  color: hasSong ? null : Colors.white.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            if (widget.onCastTapped != null)
              IconButton(
                onPressed: widget.onCastTapped,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  widget.isCasting ? Icons.cast_connected_rounded : Icons.cast_rounded,
                  color: widget.isCasting ? AppColors.accentCyan : AppColors.accentSky,
                  size: 20,
                ),
              ),
            if (widget.onToggleFullscreen != null)
              IconButton(
                onPressed: widget.onToggleFullscreen,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  widget.isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  color: AppColors.accentSky,
                  size: 20,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
