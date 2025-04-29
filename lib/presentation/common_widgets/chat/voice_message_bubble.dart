import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String voiceUrl;
  final bool isMe;
  final String timestamp;

  const VoiceMessageBubble({
    super.key,
    required this.voiceUrl,
    required this.isMe,
    required this.timestamp,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration duration = Duration.zero;
  Duration _position = Duration.zero;

  Timer? _waveformTimer;
  final List<double> _barHeights = List.generate(20, (index) => 10.0);

  @override
  void initState() {
    super.initState();
    // Initialize with smooth wave shape (like a sine pattern)
    for (int i = 0; i < _barHeights.length; i++) {
      _barHeights[i] = 12 + 8 * sin(i * pi / _barHeights.length);
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        final playing = state == PlayerState.playing;
        setState(() => _isPlaying = playing);
        _toggleWaveformAnimation(playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
        _toggleWaveformAnimation(false);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveformTimer?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.voiceUrl));
    }
  }

// 2. Update _toggleWaveformAnimation to simulate curving
  void _toggleWaveformAnimation(bool start) {
    _waveformTimer?.cancel();
    if (start) {
      int tick = 0;
      _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() {
          for (int i = 0; i < _barHeights.length; i++) {
            _barHeights[i] =
                12 + 8 * sin((i + tick * 2) * pi / _barHeights.length);
          }
          tick++;
        });
      });
    } else {
      // When stopped, return to calm wave
      setState(() {
        for (int i = 0; i < _barHeights.length; i++) {
          _barHeights[i] = 12 + 8 * sin(i * pi / _barHeights.length);
        }
      });
    }
  }

  String _formatDuration(Duration d) {
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '0:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              onTap: _togglePlay,
              child: CircleAvatar(
                backgroundColor: AppColors.blue00ABE9,
                radius: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF007BFF),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Animated waveform and duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. In build method, fix height of waveform row:
                SizedBox(
                  height: 28, // Fixed height to prevent vibrating
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(
                      _barHeights.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 3,
                        height: _barHeights[index],
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Timestamp
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                widget.timestamp,
                style: AppTextStyles.greyAAAAAA_10_400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
