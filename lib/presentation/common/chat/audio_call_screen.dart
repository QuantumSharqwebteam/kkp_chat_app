import 'package:flutter/material.dart';

class AudioCallScreen extends StatefulWidget {
  final String receiverName;
  final String receiverImage;
  final Function onCallEnd;

  const AudioCallScreen({
    super.key,
    required this.receiverName,
    required this.receiverImage,
    required this.onCallEnd,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  bool isMuted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(widget.receiverImage),
            ),
            SizedBox(height: 20),
            Text(
              widget.receiverName,
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    isMuted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      isMuted = !isMuted;
                    });
                  },
                ),
                SizedBox(width: 50),
                IconButton(
                  icon: Icon(
                    Icons.call_end,
                    color: Colors.red,
                    size: 40,
                  ),
                  onPressed: () {
                    widget.onCallEnd();
                    Navigator.pop(context);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
