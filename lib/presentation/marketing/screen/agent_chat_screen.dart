import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/s3_upload_service.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/repositories/chat_reopsitory.dart';
import 'package:kkp_chat_app/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkp_chat_app/presentation/common/chat/transfer_agent_screen.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/message_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/no_chat_conversation.dart';

class AgentChatScreen extends StatefulWidget {
  final String? customerName;
  final String? customerImage;
  final String? agentName;
  final String? agentImage;
  final String? customerEmail;
  final String? agentEmail;

  const AgentChatScreen({
    super.key,
    this.customerName = "Customer 2",
    this.customerImage = ImageConstants.userImage,
    this.agentName = "Agent N/A",
    this.agentImage = "assets/images/user4.png",
    this.customerEmail = "prabhujivats@gmail.com",
    this.agentEmail = "agent@gmail.com",
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  final _chatController = TextEditingController();
  final ChatRepository _chatRepository = ChatRepository();
  final SocketService _socketService = SocketService();
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();
  final qualityController = TextEditingController();
  final quantityController = TextEditingController();
  final weaveController = TextEditingController();
  final compositionController = TextEditingController();
  final rateController = TextEditingController();

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socketService.toggleChatPageOpen(true);
    _socketService.onReceiveMessage(_handleIncomingMessage);
    _socketService.onIncomingCall((callData) {
      debugPrint('📞 Incoming call data: $callData');

      final channelName = callData['channelName'];
      //final token = callData['token'];

      final callerName = callData['callerName'];
      final callerId = callData['callerId'];
      final uid = Utils().generateIntUidFromEmail(widget.agentEmail!);

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$callerName is calling...',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      label: const Text("Reject"),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(context); // close bottom sheet
                        // Optionally emit reject event over socket
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text("Answer"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () {
                        Navigator.pop(context); // close bottom sheet

                        // Navigate to the audio call screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AgoraAudioCallScreen(
                              isCaller: false,
                              //   token: token,
                              channelName: channelName,
                              uid: uid,
                              remoteUserId: callerId,
                              remoteUserName: callerName,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
    _loadPreviousMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.dispose();
    qualityController.dispose();
    quantityController.dispose();
    rateController.dispose();
    compositionController.dispose();
    weaveController.dispose();
    _socketService.toggleChatPageOpen(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _socketService.toggleChatPageOpen(false);
    } else if (state == AppLifecycleState.resumed) {
      _socketService.toggleChatPageOpen(true);
    }
  }

  Future<void> _loadPreviousMessages() async {
    try {
      final fetchedMessages = await _chatRepository.fetchPreviousChats(
        widget.agentEmail!,
        widget.customerEmail!,
      );
      if (mounted) {
        setState(() {
          messages = fetchedMessages.map((m) {
            final formList =
                m.form; // This is List<dynamic> or List<Map<String, dynamic>>
            Map<String, dynamic>? formData;

            if (m.type == 'form' && formList != null && formList.isNotEmpty) {
              final firstForm = formList[0]; // formList is List<dynamic>
              formData = {
                "quality": firstForm['quality'],
                "quantity": firstForm['quantity'],
                "weave": firstForm['weave'],
                "composition": firstForm['composition'],
                "rate": firstForm['rate'],
              };
            }

            return {
              "text": m.message ?? '',
              "timestamp": m.timestamp ?? '',
              "isMe": m.isMe,
              "type": m.type ?? 'text',
              "mediaUrl": m.mediaUrl,
              "form": formData, // Will be null if not form type or empty
            };
          }).toList();
          _isLoading = false;
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint("❌ Error loading chat: $e");
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final currentTime = DateTime.now().toIso8601String();
    setState(() {
      messages.add({
        "text": data["message"],
        "timeStamp": currentTime,
        "isMe": data["senderId"] == widget.agentEmail,
        "type": data["type"] ?? "text",
        "mediaUrl": data["mediaUrl"],
        "form": data["form"],
      });
      _scrollToBottom();
    });
  }

  void _sendMessage({
    required String messageText,
    String? type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? form,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null && form == null) return;

    final currentTime = DateTime.now().toIso8601String();

    setState(() {
      messages.add({
        "text": messageText,
        "timestamp": currentTime,
        "isMe": true,
        "type": type,
        "mediaUrl": mediaUrl,
        "form": form,
      });
      _scrollToBottom();
    });

    _socketService.sendMessage(
      targetEmail: widget.customerEmail!,
      message: messageText,
      senderEmail: widget.agentEmail!,
      senderName: widget.agentName!,
      type: type!,
      mediaUrl: mediaUrl,
      form: form,
    );

    _chatController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);

      // TEMP message
      final String tempId = DateTime.now().millisecondsSinceEpoch.toString();

      setState(() {
        messages.add({
          "id": tempId,
          "text": "image",
          "timestamp": DateTime.now().toIso8601String(),
          "isMe": true,
          "type": "media",
          "mediaUrl": imageFile.path,
          "uploading": true,
          "sent": false,
        });
        _scrollToBottom();
      });

      // Upload in background
      final imageUrl = await _s3uploadService.uploadFile(imageFile);

      if (imageUrl != null) {
        final int index = messages.indexWhere((msg) => msg['id'] == tempId);
        if (index != -1) {
          setState(() {
            messages[index]['mediaUrl'] = imageUrl;
            messages[index]['uploading'] = false;
            messages[index]['sent'] = true;
          });
        }

        // Now send the message only over socket — don't add to messages list again!
        _socketService.sendMessage(
          targetEmail: widget.customerEmail!,
          message: "image",
          senderEmail: widget.agentEmail!,
          senderName: widget.agentName!,
          type: "media",
          mediaUrl: imageUrl,
        );
      } else {
        // Optionally show error toast or retry option
      }
    }
  }

  void sendFormButton() {
    _sendMessage(messageText: "Fill details");
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      final currentTime = DateTime.now();
      return DateFormat('hh:mm a').format(currentTime);
    }
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      final currentTime = DateTime.now();
      return DateFormat('hh:mm a').format(currentTime);
    }
  }

  int generateIntUidFromEmail(String email) {
    return email.hashCode & 0x7FFFFFFF;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 10,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.white10,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(widget.agentImage!)),
            const SizedBox(width: 5),
            Text(
              widget.agentName!,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return TransferAgentScreen(
                      customerEmailId: widget.customerEmail!,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.swap_horizontal_circle_outlined,
                color: Colors.black),
          ),
          IconButton(
            onPressed: () async {
              //final channelName =  'agent_${widget.agentEmail}_customer_${widget.customerEmail}';
              final channelName = "agentCall123";
              final uid = generateIntUidFromEmail(widget.agentEmail!);
              debugPrint("Generated UID for agent (caller): $uid");

              // //Fetch token from backend using generated UID
              // final token =
              //     await _chatRepository.fetchAgoraToken(channelName, uid);
              // debugPrint("Fetched Agora token: $token");
              // if (token == null) {
              //   debugPrint("❗ Failed to get token");
              //   return;
              // }

              // Send call data over socket to notify customer
              _socketService.sendAgoraCall(
                targetId: widget.customerEmail!,
                channelName: channelName,
                //token: token,
                callerId: widget.agentEmail!,
                callerName: widget.agentName!,
              );

              // Navigate agent to call screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgoraAudioCallScreen(
                    isCaller: true,
                    //   token: token,
                    channelName: channelName,
                    uid: uid,
                    remoteUserId: widget.customerEmail!,
                    remoteUserName: widget.customerName!,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.call_outlined, color: Colors.black),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? NoChatConversation()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          if (msg['type'] == 'media') {
                            return ImageMessageBubble(
                              imageUrl: msg['mediaUrl'],
                              isMe: msg['isMe'],
                              timestamp: formatTimestamp(msg['timestamp']),
                              uploading: msg['uploading'] ?? false,
                              sent: msg['sent'] ?? false,
                              onImageLoaded: _scrollToBottom,
                            );
                          } else if (msg['type'] == 'form') {
                            return FormMessageBubble(
                              formData: msg['form'],
                              isMe: msg['isMe'],
                              timestamp: formatTimestamp(msg['timestamp']),
                            );
                          } else if (msg['text'] == 'Fill details') {
                            return FillFormButton(
                              onSubmit: () {
                                // Agent not allowed to fill the form
                              },
                            );
                          }
                          return MessageBubble(
                            text: msg['text'],
                            isMe: msg['isMe'],
                            timestamp: formatTimestamp(msg['timestamp']),
                            image: msg['isMe']
                                ? widget.agentImage!
                                : widget.customerImage!,
                          );
                        },
                      ),
          ),
          ChatInputField(
            controller: _chatController,
            onSend: () => _sendMessage(messageText: _chatController.text),
            onSendImage: _pickAndSendImage,
            onSendForm: sendFormButton,
          ),
        ],
      ),
    );
  }
}
