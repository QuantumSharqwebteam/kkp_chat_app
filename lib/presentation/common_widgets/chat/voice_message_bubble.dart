import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

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

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Add an AnimationController if you're using animations
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // If you're using animations, initialize the AnimationController
    _animationController = AnimationController(
      vsync: this, // The ticker provider
      duration: const Duration(seconds: 1), // Set animation duration
    );

    // Start animation or any other setup here (if needed)

    // Audio player setup
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _duration = d;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the audio player and animation controller
    _audioPlayer.dispose();
    _animationController.dispose(); // Dispose of the animation controller here
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.voiceUrl));
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Card(
          color: widget.isMe
              ? AppColors.senderMessageBubbleColor
              : AppColors.recieverMessageBubble,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: widget.isMe ? Colors.white : Colors.black,
                        size: 30,
                      ),
                      onPressed: _togglePlay,
                    ),
                    Expanded(
                      child: Slider(
                        value: _position.inSeconds.toDouble(),
                        min: 0,
                        max: _duration.inSeconds.toDouble(),
                        onChanged: (value) async {
                          final newPosition = Duration(seconds: value.toInt());
                          await _audioPlayer.seek(newPosition);
                        },
                        activeColor:
                            widget.isMe ? Colors.white : Colors.blueAccent,
                        inactiveColor:
                            widget.isMe ? Colors.white30 : Colors.grey,
                      ),
                    ),
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isMe ? Colors.white : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Voice Message",
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isMe ? Colors.white : Colors.black,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    widget.timestamp,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isMe ? Colors.white : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
