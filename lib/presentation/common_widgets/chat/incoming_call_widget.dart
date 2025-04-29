import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class IncomingCallWidget extends StatefulWidget {
  final String callerName;
  final VoidCallback onAnswer;
  final VoidCallback onReject;
  final AudioPlayer audioPlayer;

  const IncomingCallWidget({
    super.key,
    required this.callerName,
    required this.onAnswer,
    required this.onReject,
    required this.audioPlayer,
  });

  @override
  State<IncomingCallWidget> createState() => _IncomingCallWidgetState();
}

class _IncomingCallWidgetState extends State<IncomingCallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _playRingtone();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
            begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
  }

  Future<void> _playRingtone() async {
    try {
      debugPrint('Attempting to play ringtone...');
      await widget.audioPlayer.setReleaseMode(ReleaseMode.loop);
      await widget.audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
      debugPrint('Ringtone started.');
    } catch (e) {
      debugPrint('Failed to play ringtone: $e');
    }
  }

  @override
  void dispose() {
    widget.audioPlayer.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.callerName} is calling...',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      label: const Text("Reject"),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: widget.onReject,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text("Answer"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: widget.onAnswer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
