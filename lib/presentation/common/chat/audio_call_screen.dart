import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kkp_chat_app/core/services/audio_call_service.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioCallScreen extends StatefulWidget {
  final String? targetId;
  final String? senderId;
  final String? senderName;
  final Map<String, dynamic>? signalData;

  const AudioCallScreen({
    super.key,
    this.targetId,
    this.senderId,
    this.senderName,
    this.signalData,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final AudioCallService _audioCallService = AudioCallService();
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    if (widget.signalData != null) {
      _answerCall();
    } else {
      _initiateCall();
    }
  }

  Future<void> _initiateCall() async {
    PermissionStatus micStatus = await Permission.microphone.request();

    if (micStatus.isGranted) {
      _audioCallService.initiateCall(
        widget.targetId!,
        widget.senderId!,
        widget.senderName!,
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

  Future<void> _answerCall() async {
    PermissionStatus micStatus = await Permission.microphone.request();

    if (micStatus.isGranted) {
      _audioCallService.answerCall(
        widget.senderId!,
        widget.signalData!,
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
    if (widget.signalData != null) {
      _audioCallService.terminateCall(widget.senderId!);
    } else {
      _audioCallService.terminateCall(widget.targetId!);
    }
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
        title: Text('Call with ${widget.targetId ?? widget.senderId}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.signalData != null ? 'In Call...' : 'Calling...',
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
