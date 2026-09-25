import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/call_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/date_header.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/product_message_bubble.dart';
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
  bool _isAtBottom = true;

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

  List<Map<String, dynamic>>? _normalizeFormData(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      final entries = raw
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
      return entries.isNotEmpty ? entries : null;
    }
    if (raw is Map) {
      return [Map<String, dynamic>.from(raw)];
    }
    return null;
  }

  ChatMessageModel _chatMessageFromModel(MessageModel messageJson) {
    final normalizedForms = _normalizeFormData(messageJson.form);
    final primaryForm =
        normalizedForms?.isNotEmpty == true ? normalizedForms!.first : null;
    return ChatMessageModel(
      message: messageJson.message ?? '',
      timestamp: DateTime.parse(
          messageJson.timestamp ?? DateTime.now().toIso8601String()),
      sender: messageJson.senderId!,
      type: messageJson.type,
      mediaUrl: messageJson.mediaUrl,
      form: primaryForm,
      forms: normalizedForms,
      callDuration: messageJson.callDuration,
      callStatus: messageJson.callStatus,
      callId: messageJson.callId,
      messageId: messageJson.messageId,
      isDeleted: messageJson.isDeleted!,
      read: messageJson.read,
    );
  }

  // check if sender is NOT the customer, so messages from ANY agent
  // (agent head, assigned agent, or any other agent) show on the right side
  bool _isFromAgentSide(String? sender) {
    return sender != null && sender != widget.customerEmail;
  }

  // ← FIX: fetch from BOTH APIs and merge so assigned agent sees
  //         agent head's previous chats + their own chats with the customer
  Future<void> _fetchMessages() async {
    try {
      // Fetch ALL messages for this customer (includes all agents' messages)
      final allChats = await _chatRepository.fetchCustomerMessages(
        customerEmail: widget.customerEmail,
        limit: 500,
      );

      // Convert and sort by timestamp
      final chatMessages = allChats.map(_chatMessageFromModel).toList();
      chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        messages = chatMessages;
        _isLoading = false;
      });

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
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Initicon(text: widget.customerName ?? ""),
            const SizedBox(width: 5),
            Text(
              widget.customerName ?? locale.customer,
              style: AppTextStyles.black12_700,
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: Platform.isAndroid,
        child: Stack(
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
                                final isAgent = _isFromAgentSide(msg.sender);
                                String? dateHeader;

                                if (index == 0 ||
                                    !ChatUtils().isSameDay(
                                        messages[index - 1].timestamp,
                                        msg.timestamp)) {
                                  dateHeader = ChatUtils()
                                      .formatDateHeader(msg.timestamp);
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (dateHeader != null)
                                      DateHeader(date: dateHeader),
                                    if (msg.type == 'media')
                                      ImageMessageBubble(
                                        imageUrl: msg.mediaUrl!,
                                        read: msg.read,
                                        isMe: isAgent,
                                        timestamp: ChatUtils().formatTimestamp(
                                            msg.timestamp.toIso8601String()),
                                        isDeleted: msg.isDeleted,
                                      )
                                    else if (msg.type == 'form')
                                      FormMessageBubble(
                                        forms: msg.formEntries,
                                        read: msg.read,
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
                                      )
                                    else if (msg.type == 'document')
                                      DocumentMessageBubble(
                                        documentUrl: msg.mediaUrl!,
                                        read: msg.read,
                                        isMe: isAgent,
                                        timestamp: ChatUtils().formatTimestamp(
                                            msg.timestamp.toIso8601String()),
                                        isDeleted: msg.isDeleted,
                                      )
                                    else if (msg.type == 'voice')
                                      VoiceMessageBubble(
                                        voiceUrl: msg.mediaUrl!,
                                        read: msg.read,
                                        isMe: isAgent,
                                        timestamp: ChatUtils().formatTimestamp(
                                            msg.timestamp.toIso8601String()),
                                        isDeleted: msg.isDeleted,
                                      )
                                    else if (msg.type == 'call')
                                      CallMessageBubble(
                                        isMe: isAgent,
                                        timestamp: ChatUtils().formatTimestamp(
                                            msg.timestamp.toIso8601String()),
                                        callStatus: msg.callStatus ?? "",
                                        callDuration: msg.callDuration ?? '',
                                      )
                                    else if (msg.message == 'Fill details')
                                      FillFormButton(
                                        buttonText: locale.fillProductDetails,
                                        onSubmit: () {
                                          // Agent not allowed to fill the form
                                        },
                                      )
                                    else if (msg.message == "Update form rate")
                                      FillFormButton(
                                        buttonText: locale.updateForm,
                                        onSubmit: () {
                                          // Only show the widget for history, not to do anything on the agent side
                                        },
                                      )
                                    else if (msg.type == 'product')
                                      (msg.message != null &&
                                              msg.message!.isNotEmpty)
                                          ? ProductMessageBubble(
                                              productJson: msg.message!,
                                              isMe: isAgent,
                                              read: msg.read,
                                              timestamp:
                                                  ChatUtils().formatTimestamp(
                                                msg.timestamp.toIso8601String(),
                                              ),
                                              isDeleted: msg.isDeleted,
                                              onLongPress: () {},
                                              onTap: () {},
                                            )
                                          : DeletedMessageBubble(
                                              isMe: isAgent,
                                              timestamp:
                                                  ChatUtils().formatTimestamp(
                                                msg.timestamp.toIso8601String(),
                                              ),
                                            )
                                    else
                                      MessageBubble(
                                        message: msg,
                                        isMe: isAgent,
                                        read: msg.read,
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
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: _scrollToBottom,
                  mini: true,
                  child: const Icon(Icons.arrow_downward_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
