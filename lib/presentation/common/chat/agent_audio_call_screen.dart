import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/services/audio_call_service.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart'; // adjust as per your path

class AgentAudioCallScreen extends StatefulWidget {
  final String customerEmail;
  final String agentEmail;
  final String agentName;

  const AgentAudioCallScreen({
    super.key,
    required this.customerEmail,
    required this.agentEmail,
    required this.agentName,
  });

  @override
  State<AgentAudioCallScreen> createState() => _AgentAudioCallScreenState();
}

class _AgentAudioCallScreenState extends State<AgentAudioCallScreen> {
  final AudioCallService _audioCallService = AudioCallService();
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndCall();
  }

  Future<void> _checkPermissionsAndCall() async {
    PermissionStatus micStatus = await Permission.microphone.request();

    if (micStatus.isGranted) {
      _audioCallService.initiateCall(
        widget.customerEmail,
        widget.agentEmail,
        widget.agentName,
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
    _audioCallService.terminateCall(widget.customerEmail);
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
        title: Text('Calling ${widget.customerEmail}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Calling...',
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
