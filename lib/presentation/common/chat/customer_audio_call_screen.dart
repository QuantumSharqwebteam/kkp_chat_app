import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/services/audio_call_service.dart';

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

  @override
  void initState() {
    super.initState();
    _audioCallService.answerCall(
      widget.agentEmail,
      widget.signalData,
    );
  }

  @override
  void dispose() {
    _audioCallService.dispose();
    super.dispose();
  }

  void _endCall() {
    _audioCallService.terminateCall(widget.agentEmail);
    Navigator.pop(context);
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
