import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/call_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/date_header.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/voice_message_bubble.dart';

class AgentCustomerMessagesScreen extends StatefulWidget {
  final String agentEmail;
  final String customerEmail;
  final String? agentName;
  final String? customerName;

  const AgentCustomerMessagesScreen({
    super.key,
    required this.agentEmail,
    required this.customerEmail,
    this.agentName,
    this.customerName,
  });

  @override
  State<AgentCustomerMessagesScreen> createState() =>
      _AgentCustomerMessagesScreenState();
}

class _AgentCustomerMessagesScreenState
    extends State<AgentCustomerMessagesScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  List<ChatMessageModel> messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true; // Track if the user is at the bottom of the list

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _scrollController.addListener(_checkIfAtBottom);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkIfAtBottom() {
    if (_scrollController.position.atEdge) {
      bool isBottom = _scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent;
      if (isBottom != _isAtBottom) {
        setState(() {
          _isAtBottom = isBottom;
        });
      }
    } else {
      if (_isAtBottom) {
        setState(() {
          _isAtBottom = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final fetchedMessages = await _chatRepository.fetchPreviousChats(
        widget.agentEmail,
        widget.customerEmail,
      );

      setState(() {
        messages = fetchedMessages.map((messageJson) {
          return ChatMessageModel(
            message: messageJson.message ?? '',
            timestamp: DateTime.parse(
                messageJson.timestamp ?? DateTime.now().toIso8601String()),
            sender: messageJson.senderId!,
            type: messageJson.type,
            mediaUrl: messageJson.mediaUrl,
            form: messageJson.form != null && messageJson.form!.isNotEmpty
                ? Map<String, dynamic>.from(messageJson.form![0])
                : null,
            callDuration: messageJson.callDuration,
            callStatus: messageJson.callStatus,
            callId: messageJson.callId,
            messageId: messageJson.messageId, // Ensure messageId is mapped
            isDeleted: messageJson.isDeleted!,
          );
        }).toList();
        _isLoading = false;
      });

      // Scroll to bottom after messages are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint("Error fetching messages: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Initicon(text: widget.customerName ?? ""),
            const SizedBox(width: 5),
            Text(
              widget.customerName ?? "Customer",
              style: AppTextStyles.black12_700,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                        ? const NoChatConversation()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(10),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isAgent = msg.sender == widget.agentEmail;
                              String? dateHeader;

                              if (index == 0 ||
                                  !ChatUtils().isSameDay(
                                      messages[index - 1].timestamp,
                                      msg.timestamp)) {
                                dateHeader =
                                    ChatUtils().formatDateHeader(msg.timestamp);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (dateHeader != null)
                                    DateHeader(date: dateHeader),
                                  if (msg.type == 'media')
                                    ImageMessageBubble(
                                      imageUrl: msg.mediaUrl!,
                                      isMe: isAgent,
                                      timestamp: ChatUtils().formatTimestamp(
                                          msg.timestamp.toIso8601String()),
                                    )
                                  else if (msg.type == 'form')
                                    FormMessageBubble(
                                      formData: msg.form!,
                                      isMe: isAgent,
                                      timestamp: ChatUtils().formatTimestamp(
                                          msg.timestamp.toIso8601String()),
                                      userRole: 'agent',
                                      onRateUpdated: (Map<String, dynamic>
                                          updatedFormData) {},
                                      onStatusUpdated:
                                          (String status, String id) {},
                                      onFormUpdateStart: () {},
                                      onFormUpdateEnd: () {},
                                      onAskForRateUpdate:
                                          (Map<String, dynamic> formData) {},
                                    )
                                  else if (msg.type == 'document')
                                    DocumentMessageBubble(
                                      documentUrl: msg.mediaUrl!,
                                      isMe: isAgent,
                                      timestamp: ChatUtils().formatTimestamp(
                                          msg.timestamp.toIso8601String()),
                                    )
                                  else if (msg.type == 'voice')
                                    VoiceMessageBubble(
                                      voiceUrl: msg.mediaUrl!,
                                      isMe: isAgent,
                                      timestamp: ChatUtils().formatTimestamp(
                                          msg.timestamp.toIso8601String()),
                                    )
                                  else if (msg.type == 'call')
                                    CallMessageBubble(
                                      isMe: isAgent,
                                      timestamp: ChatUtils().formatTimestamp(
                                          msg.timestamp.toIso8601String()),
                                      callStatus: msg.callStatus ?? "",
                                      callDuration: msg.callDuration ?? '',
                                    )
                                  else
                                    MessageBubble(
                                      message: msg,
                                      isMe: isAgent,
                                      onLongPress: () {
                                        //
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
              ),
            ],
          ),
          if (!_isAtBottom)
            Positioned(
              bottom: 20, // Adjust the position as needed
              right: 20, // Adjust the position as needed
              child: FloatingActionButton(
                onPressed: _scrollToBottom,
                mini: true,
                child: const Icon(Icons.arrow_downward_rounded),
              ),
            ),
        ],
      ),
    );
  }
}
