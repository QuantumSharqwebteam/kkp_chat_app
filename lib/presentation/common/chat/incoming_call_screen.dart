import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Call'),
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
            Text(callerName, style: AppTextStyles.black16_700),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle call rejection
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
                    // Navigate to Agora audio call screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AgoraAudioCallScreen(
                          isCaller: false,
                          channelName: channelName,
                          uid: Utils()
                              .generateIntUidFromEmail("agent@gmail.com"),
                          remoteUserId: remoteUserId,
                          remoteUserName: callerName,
                          messageId: notificationId,
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
