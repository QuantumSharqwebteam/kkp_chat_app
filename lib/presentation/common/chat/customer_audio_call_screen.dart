import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/services/audio_call_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomerAudioCallScreen extends StatefulWidget {
  final String agentEmail;
  final String customerEmail;
  final String customerName;
  final Map<String, dynamic> signalData;

  const CustomerAudioCallScreen({
    super.key,
    required this.agentEmail,
    required this.customerEmail,
    required this.customerName,
    required this.signalData,
  });

  @override
  State<CustomerAudioCallScreen> createState() =>
      _CustomerAudioCallScreenState();
}

class _CustomerAudioCallScreenState extends State<CustomerAudioCallScreen> {
  final AudioCallService _audioCallService = AudioCallService();
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndAnswer();
  }

  Future<void> _checkPermissionsAndAnswer() async {
    PermissionStatus micStatus = await Permission.microphone.request();

    if (micStatus.isGranted) {
      _audioCallService.answerCall(
        widget.agentEmail,
        widget.signalData,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission is required.')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _endCall() {
    _audioCallService.terminateCall(widget.agentEmail);
    Navigator.pop(context);
  }

  void _toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await Helper.setSpeakerphoneOn(_isSpeakerOn);
    setState(() {});
  }

  @override
  void dispose() {
    _audioCallService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call with ${widget.agentEmail}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'In Call...',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.call_end),
              label: Text('End Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: _endCall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.hearing),
              label: Text(_isSpeakerOn ? 'Speaker On' : 'Speaker Off'),
              onPressed: _toggleSpeaker,
            ),
          ],
        ),
      ),
    );
  }
}
