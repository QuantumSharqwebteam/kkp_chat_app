import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String voiceUrl;
  final bool isMe;
  final String timestamp;
  final VoidCallback? onLongPress;
  final bool isDeleted;
  final bool? read;

  const VoiceMessageBubble({
    super.key,
    required this.voiceUrl,
    required this.isMe,
    required this.timestamp,
    this.onLongPress,
    this.isDeleted = false,
    this.read = false,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  static const int _barCount = 20;
  static const int _durationCacheLimit = 200;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // ValueNotifiers instead of setState: the waveform ticks at 10Hz and the
  // position stream at ~60Hz. Driving those through setState repainted the
  // whole bubble — timestamp, read tick and all 20 bars — on every tick.
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> _duration = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final ValueNotifier<int> _waveTick = ValueNotifier(0);

  /// Set when the audio source cannot be loaded or played (expired/404 S3 URL,
  /// unsupported container). Renders a muted, tappable retry state instead of
  /// a play button that silently does nothing.
  final ValueNotifier<bool> _hasError = ValueNotifier(false);

  Timer? _waveformTimer;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Insertion-ordered, capped. Previously unbounded for the process lifetime.
  static final Map<String, Duration> _durationCache = {};

  static void _cacheDuration(String url, Duration d) {
    if (_durationCache.length >= _durationCacheLimit &&
        !_durationCache.containsKey(url)) {
      _durationCache.remove(_durationCache.keys.first);
    }
    _durationCache[url] = d;
  }

  @override
  void initState() {
    super.initState();

    final cached = _durationCache[widget.voiceUrl];
    if (cached != null) {
      _duration.value = cached;
    } else {
      // Load source only if not cached
      unawaited(_loadDuration());
    }

    // Every subscription is retained so dispose() can cancel it, and every one
    // carries an onError. In audioplayers the native error channel is funnelled
    // into the same event stream onDurationChanged / onPositionChanged /
    // onPlayerComplete derive from, so a stream error here without a handler
    // escapes to the root zone and takes the app down.
    _subscriptions.add(
      _audioPlayer.onPlayerStateChanged.listen(
        (state) {
          final playing = state == PlayerState.playing;
          _isPlaying.value = playing;
          _toggleWaveformAnimation(playing);
        },
        onError: _handlePlaybackError,
      ),
    );

    _subscriptions.add(
      _audioPlayer.onDurationChanged.listen(
        (d) {
          _duration.value = d;
          _cacheDuration(widget.voiceUrl, d);
        },
        onError: _handlePlaybackError,
      ),
    );

    _subscriptions.add(
      _audioPlayer.onPositionChanged.listen(
        (p) => _position.value = p,
        onError: _handlePlaybackError,
      ),
    );

    _subscriptions.add(
      _audioPlayer.onPlayerComplete.listen(
        (event) {
          _position.value = Duration.zero;
          _isPlaying.value = false;
          _toggleWaveformAnimation(false);
        },
        onError: _handlePlaybackError,
      ),
    );
  }

  void _handlePlaybackError(Object error, [StackTrace? stackTrace]) {
    debugPrint('🔇 [VoiceMessageBubble] ${widget.voiceUrl} failed: $error');
    if (!mounted) return;
    _waveformTimer?.cancel();
    _isPlaying.value = false;
    _hasError.value = true;
  }

  Future<void> _loadDuration() async {
    try {
      await _audioPlayer.setSource(UrlSource(widget.voiceUrl));
      final d = await _audioPlayer.getDuration();
      if (d != null && mounted) {
        _duration.value = d;
        _cacheDuration(widget.voiceUrl, d);
      }
    } catch (e) {
      // Duration is cosmetic — do not surface an error state here. The play
      // path reports failure if the source is genuinely unusable.
      debugPrint('🔇 [VoiceMessageBubble] duration load failed: $e');
    }
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _audioPlayer.dispose();
    _isPlaying.dispose();
    _duration.dispose();
    _position.dispose();
    _waveTick.dispose();
    _hasError.dispose();
    super.dispose();
  }

  /// Never throws. Wired to a VoidCallback onTap, so a rejected Future here
  /// would have no handler at all.
  Future<void> _togglePlay() async {
    try {
      if (_isPlaying.value) {
        await _audioPlayer.pause();
      } else {
        _hasError.value = false;
        await _audioPlayer.play(UrlSource(widget.voiceUrl));
      }
    } catch (e, stackTrace) {
      _handlePlaybackError(e, stackTrace);
    }
  }

  void _toggleWaveformAnimation(bool start) {
    _waveformTimer?.cancel();
    if (start) {
      _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        _waveTick.value++;
      });
    } else {
      _waveTick.value = 0;
    }
  }

  static double _barHeight(int index, int tick) =>
      12 + 8 * sin((index + tick * 2) * pi / _barCount);

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return widget.isDeleted
        ? DeletedMessageBubble(isMe: widget.isMe, timestamp: widget.timestamp)
        : GestureDetector(
            onLongPress: widget.onLongPress,
            child: Align(
              alignment:
                  widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Play/Pause button
                    GestureDetector(
                      onTap: () => unawaited(_togglePlay()),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _hasError,
                        builder: (context, hasError, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: _isPlaying,
                            builder: (context, playing, __) {
                              return CircleAvatar(
                                backgroundColor: hasError
                                    ? Colors.grey
                                    : AppColors.blue00ABE9,
                                radius: 20,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hasError
                                        ? Colors.grey
                                        : const Color(0xFF007BFF),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    hasError
                                        ? Icons.refresh
                                        : (playing
                                            ? Icons.pause
                                            : Icons.play_arrow),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Animated waveform and duration
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 28, // Fixed height to prevent vibrating
                          child: ValueListenableBuilder<int>(
                            valueListenable: _waveTick,
                            builder: (context, tick, _) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: List.generate(
                                  _barCount,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    width: 3,
                                    height: _barHeight(index, tick),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        ListenableBuilder(
                          listenable: Listenable.merge(
                              [_isPlaying, _position, _duration]),
                          builder: (context, _) {
                            final position = _position.value;
                            final duration = _duration.value;
                            return Text(
                              _isPlaying.value || position > Duration.zero
                                  ? '${_formatDuration(position)} / ${_formatDuration(duration)}'
                                  : _formatDuration(duration),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Timestamp
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.timestamp,
                            style: AppTextStyles.greyAAAAAA_10_400,
                          ),
                          if (widget.isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              (widget.read ?? false)
                                  ? Icons.done_all
                                  : Icons.done,
                              color: (widget.read ?? false)
                                  ? Colors.blue
                                  : Colors.grey,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
