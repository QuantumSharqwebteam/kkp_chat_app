import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String remoteUserId;
  final String channelName;
  final String notificationId;
  final String callId;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.remoteUserId,
    required this.channelName,
    required this.notificationId,
    required this.callId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final ChatRepository chatRepository = ChatRepository();
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
      await _audioPlayer
          .setReleaseMode(ReleaseMode.loop); // Set to loop the ringtone
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

  Future<void> _updateCallData(String callStatus,
      {String? callDuration}) async {
    try {
      await chatRepository.updateCallData(
        widget.callId,
        callStatus,
        callDuration: callDuration,
      );
      debugPrint(
          "✅ ✅ Call data updated successfully: $callStatus, Duration: $callDuration");
    } catch (e) {
      debugPrint("❌ Error updating call data: $e");
      // Handle the error as needed, e.g., show a message to the user
    }
  }

  int generateUniqueId() {
    // Use a combination of a random number and a timestamp to generate a unique ID
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return (random.nextInt(1 << 30) + timestamp) & 0x7FFFFFFF;
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
                  onPressed: () async {
                    // Handle call rejection
                    _stopRingtone();
                    await _updateCallData("not answered");
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
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
                          uid: generateUniqueId(),
                          //Utils().generateIntUidFromEmail("agent@gmail.com"),
                          remoteUserId: widget.remoteUserId,
                          remoteUserName: widget.callerName,
                          messageId: widget.callId,
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
