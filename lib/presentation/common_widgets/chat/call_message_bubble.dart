import 'package:flutter/material.dart';

class CallMessageBubble extends StatelessWidget {
  final bool isMe;
  final String timestamp;
  final String callStatus;
  final String callDuration;

  const CallMessageBubble({
    super.key,
    required this.isMe,
    required this.timestamp,
    required this.callStatus,
    required this.callDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    callStatus == 'answered'
                        ? Icons.call_end
                        : Icons.call_missed,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    callStatus == 'answered' ? 'Call ended' : 'Call missed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (callStatus == 'answered') ...[
                SizedBox(height: 4),
                Text(
                  callDuration,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
              SizedBox(height: 4),
              Text(
                timestamp,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
