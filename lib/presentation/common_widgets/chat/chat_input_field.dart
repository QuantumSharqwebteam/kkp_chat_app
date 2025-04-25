import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSendImage;
  final VoidCallback onSendForm;
  final VoidCallback onSendDocument;
  final VoidCallback onSendVoice; // Add this line
  final bool isRecording;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendImage,
    required this.onSendForm,
    required this.onSendDocument,
    required this.onSendVoice,
    required this.isRecording,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final RecorderController _recorderController = RecorderController();
  bool _isRecording = false;
  Timer? _timer;
  int _recordedSeconds = 0;
  double _slidePosition = 0.0;

  @override
  void dispose() {
    _recorderController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      // Handle permission denial
      return;
    }

    setState(() {
      _isRecording = true;
      _slidePosition = 0.0;
      _recordedSeconds = 0;
    });

    _recorderController.reset();
    await _recorderController.record();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordedSeconds++;
      });
    });
  }

  Future<void> _stopRecording() async {
    await _recorderController.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _recordedSeconds = 0;
    });
    widget.onSendVoice(); // Handle the recorded audio file here
  }

  void _cancelRecording() {
    _recorderController.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _recordedSeconds = 0;
      _slidePosition = 0.0;
    });
    // Handle cancellation logic here
  }

  void _handleSlideUpdate(DragUpdateDetails details) {
    setState(() {
      _slidePosition += details.primaryDelta!;
      if (_slidePosition < -100) {
        _cancelRecording();
      }
    });
  }

  void _handleSlideEnd(DragEndDetails details) {
    if (_slidePosition < -50) {
      _cancelRecording();
    } else {
      setState(() {
        _slidePosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: _isRecording
          ? GestureDetector(
              onHorizontalDragUpdate: _handleSlideUpdate,
              onHorizontalDragEnd: _handleSlideEnd,
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios,
                        size: 16, color: Colors.red),
                    const SizedBox(width: 5),
                    AnimatedOpacity(
                      opacity: _slidePosition < -20 ? 1.0 : 0.6,
                      duration: Duration(milliseconds: 300),
                      child: const Text(
                        'Slide to cancel',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AudioWaveforms(
                        enableGesture: false,
                        size:
                            Size(MediaQuery.of(context).size.width * 0.5, 30.0),
                        recorderController: _recorderController,
                        waveStyle: const WaveStyle(
                          waveColor: Colors.blue,
                          extendWaveform: true,
                          showMiddleLine: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$_recordedSeconds s',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.mic, color: Colors.redAccent, size: 28),
                  ],
                ),
              ),
            )
          : Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attachment),
                  onPressed: () {
                    showAttachmentMenu(context, (selectedItem) {
                      if (selectedItem == "Photos") {
                        widget.onSendImage();
                      } else if (selectedItem == "Inquiry Form") {
                        widget.onSendForm();
                      } else if (selectedItem == "Camera") {
                        widget.onSendImage();
                      } else if (selectedItem == "Documents") {
                        widget.onSendDocument();
                      }
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.greyDBDDE1,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            decoration: const InputDecoration(
                              hintText: "Type here...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: widget.onSendImage,
                        ),
                        GestureDetector(
                          onLongPressStart: (_) {
                            _startRecording();
                          },
                          onLongPressEnd: (_) {
                            _stopRecording();
                          },
                          onHorizontalDragUpdate: _handleSlideUpdate,
                          onHorizontalDragEnd: _handleSlideEnd,
                          child: Icon(Icons.mic, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Send button
                InkWell(
                  onTap: widget.onSend,
                  child: CustomImage(
                    imagePath: ImageConstants.send,
                    height: 30,
                    width: 30,
                  ),
                )
              ],
            ),
    );
  }
}

// Move this list outside the class since it doesn’t depend on state
final List<Map<String, String>> attachmentItems = [
  {"image": ImageConstants.inquiry, "label": "Inquiry Form"},
  {"image": ImageConstants.rate, "label": "Rate"},
  {"image": ImageConstants.orderConfimm, "label": "Order Confirm"},
  {"image": ImageConstants.orderDecline, "label": "Order Decline"},
  {"image": ImageConstants.camera, "label": "Camera"},
  {"image": ImageConstants.photos, "label": "Photos"},
  {"image": ImageConstants.documents, "label": "Documents"},
  {"image": ImageConstants.video, "label": "Videos"},
];

final List<Map<String, String>> attachmentItemsforCustomer = [
  {"image": ImageConstants.camera, "label": "Camera"},
  {"image": ImageConstants.photos, "label": "Photos"},
  {"image": ImageConstants.documents, "label": "Documents"},
  {"image": ImageConstants.video, "label": "Videos"},
];

final String? currentUser = LocalDbHelper.getProfile()?.role;

void showAttachmentMenu(BuildContext context, Function(String) onItemSelected) {
  showModalBottomSheet(
    context: context,
    elevation: 10,
    backgroundColor: Colors.transparent, // Makes the corners visible
    isScrollControlled: true, // Ensures proper spacing
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
    ),
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
        ),
        margin: const EdgeInsets.only(bottom: 30, left: 10, right: 10),
        padding:
            const EdgeInsets.all(10.0), // Adds padding inside the bottom sheet
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 items per row
                crossAxisSpacing: 2,
                mainAxisSpacing: 0,
                childAspectRatio: 0.9, // Keeps square shape
              ),
              itemCount: currentUser == "User"
                  ? attachmentItemsforCustomer.length
                  : attachmentItems.length,
              itemBuilder: (context, index) {
                final item = currentUser == "User"
                    ? attachmentItemsforCustomer[index]
                    : attachmentItems[index];
                return GestureDetector(
                  onTap: () {
                    onItemSelected(item['label']!);
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          item['image']!,
                          height: 30,
                          width: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['label']!,
                        style: AppTextStyles.black10_500,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
