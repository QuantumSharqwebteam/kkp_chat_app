import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/services/audio_call_service.dart';

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

  @override
  void initState() {
    super.initState();
    _audioCallService.initiateCall(
      widget.customerEmail,
      widget.agentEmail,
      widget.agentName,
    );
  }

  @override
  void dispose() {
    _audioCallService.dispose();
    super.dispose();
  }

  void _endCall() {
    _audioCallService.terminateCall(widget.customerEmail);
    Navigator.pop(context);
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _endCall,
              child: Text('End Call'),
            ),
          ],
        ),
      ),
    );
  }
}
