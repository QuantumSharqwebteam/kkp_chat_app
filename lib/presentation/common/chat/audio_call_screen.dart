import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kkp_chat_app/core/services/voice_call_service.dart';

class AudioCallScreen extends StatefulWidget {
  final String selfId;
  final String? targetId;
  final bool isCaller;
  final String? callerName;

  const AudioCallScreen({
    super.key,
    required this.selfId,
    this.targetId,
    required this.isCaller,
    this.callerName,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late VoiceCallService _voiceCallService;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callConnected = false;

  Timer? _callTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();

    _voiceCallService = VoiceCallService(
      selfId: widget.selfId,
      targetId: widget.targetId,
      isCaller: widget.isCaller,
      callerName: widget.callerName,
    )
      ..onCallConnected = _onCallConnected
      ..onCallEnded = _onCallEnded
      ..onError = _onError;

    _voiceCallService.init();
  }

  void _onCallConnected() {
    setState(() => _callConnected = true);
    _startCallTimer();
  }

  void _onCallEnded(bool isPeerHangup) {
    _callTimer?.cancel();
  }

  void _onError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    _onCallEnded(false);
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  String _formatElapsedTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _voiceCallService.toggleMute(_isMuted);
  }

  void _toggleSpeaker() async {
    final newState = !_isSpeakerOn;
    await _voiceCallService.toggleSpeaker(newState);
    setState(() => _isSpeakerOn = newState);
  }

  void _hangUp() {
    _voiceCallService.endCall();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _voiceCallService.endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.callerName ?? 'Calling...';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _callConnected
                  ? _formatElapsedTime(_elapsedSeconds)
                  : 'Connecting...',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCallButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  onPressed: _toggleMute,
                ),
                const SizedBox(width: 30),
                _buildCallButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onPressed: _hangUp,
                ),
                const SizedBox(width: 30),
                _buildCallButton(
                  icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
                  color: Colors.white,
                  onPressed: _toggleSpeaker,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey[800],
      child: IconButton(
        icon: Icon(icon, color: color),
        iconSize: 30,
        onPressed: onPressed,
      ),
    );
  }
}
