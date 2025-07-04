import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/presentation/common/chat/call_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/media_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';
import 'package:provider/provider.dart';

class AgoraAudioCallScreen extends StatefulWidget {
  const AgoraAudioCallScreen({super.key});

  @override
  State<AgoraAudioCallScreen> createState() => _AgoraAudioCallScreenState();
}

class _AgoraAudioCallScreenState extends State<AgoraAudioCallScreen> {
  late CallProvider _callProvider;

  @override
  void initState() {
    super.initState();
    _callProvider = Provider.of<CallProvider>(context, listen: false);
  }

  void _toggleMute() {
    _callProvider.toggleMute();
    setState(() {});
  }

  void _toggleSpeaker() {
    _callProvider.toggleSpeaker();
    setState(() {});
  }

  void _endCall() {
    // Only create callDetailsMessage if not already set
    if (_callProvider.callDetailsMessage == null) {
      final status =
          _callProvider.remoteUid != null ? "answered" : "not answered";
      final duration = _callProvider.createCallDetailsMessage(
        status,
        _callProvider.callDurationFormatted,
      );
      _callProvider.setCallDetailsMessage(duration);
    }

    _callProvider.endCall();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final call = _callProvider;

    final scaffold = Scaffold(
      backgroundColor: AppColors.backgroundDCEBFF,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              call.remoteUserName ?? "",
              style: AppTextStyles.black24_700,
            ),
            const SizedBox(height: 20),
            StreamBuilder<int>(
              stream: call.callDurationStream,
              builder: (context, snapshot) {
                final durationText = call.remoteUid != null
                    ? "In call... ${call.callDurationFormatted}"
                    : "Ringing...";
                return Text(
                  durationText,
                  style: AppTextStyles.grey5C5C5C_18_700,
                );
              },
            ),
            const SizedBox(height: 70),
            const CustomImage(
              imagePath: ImageConstants.profileAvatar,
              height: 200,
              width: 200,
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.grey5C5C5C,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MediaButton(
                    backgroundColor:
                        call.isSpeakerOn ? Colors.white : AppColors.black2E2E2E,
                    iconColor: call.isSpeakerOn ? Colors.black : Colors.white,
                    onTap: _toggleSpeaker,
                    iconData:
                        call.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                  ),
                  MediaButton(
                    backgroundColor:
                        call.isMuted ? Colors.white : AppColors.black2E2E2E,
                    iconColor: call.isMuted ? Colors.black : Colors.white,
                    onTap: _toggleMute,
                    iconData: call.isMuted ? Icons.mic_off : Icons.mic,
                  ),
                  MediaButton(
                    backgroundColor: AppColors.inActiveRed,
                    iconColor: Colors.white,
                    onTap: _endCall,
                    iconData: Icons.call_end,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          debugPrint("🌀 Pop intercepted by PopScope → minimizing call screen");
          _callProvider.minimizeCallScreen();
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          debugPrint("↩️ Back press intercepted → minimizing call screen");
          _callProvider.minimizeCallScreen();
          return false;
        },
        child: scaffold,
      ),
    );
  }
}
