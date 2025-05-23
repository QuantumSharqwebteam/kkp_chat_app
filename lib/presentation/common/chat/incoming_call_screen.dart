import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String remoteUserId;
  final String channelName;
  final String notificationId;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.remoteUserId,
    required this.channelName,
    required this.notificationId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playRingtone();
  }

  @override
  void dispose() {
    _stopRingtone();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playRingtone() async {
    try {
      // Replace 'ringtones/ringtone.mp3' with the path to your ringtone file
      await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
      isPlaying = true;
    } catch (e) {
      debugPrint("Error playing ringtone: $e");
    }
  }

  Future<void> _stopRingtone() async {
    await _audioPlayer.stop();
    isPlaying = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Call'),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Incoming call from:',
              style: AppTextStyles.black16_500,
            ),
            Text(
              widget.callerName,
              style: AppTextStyles.black18_600,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle call rejection
                    _stopRingtone();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Remove the incoming call screen from the navigation stack
                    _stopRingtone();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AgoraAudioCallScreen(
                          isCaller: false,
                          channelName: widget.channelName,
                          uid: Utils()
                              .generateIntUidFromEmail("agent@gmail.com"),
                          remoteUserId: widget.remoteUserId,
                          remoteUserName: widget.callerName,
                          messageId: widget.notificationId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Answer',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
