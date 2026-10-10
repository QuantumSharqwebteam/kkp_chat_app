import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/main.dart';
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
  late final SocketService _socketService;
  List<ChatMessageModel> messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;

  // ── Call-log freshness ────────────────────────────────────────────────────
  // The server writes a call log as "missed" while it rings, and the caller
  // only overwrites it with "answered" + duration after hang-up. If this
  // screen opens right after a call, the fetch can beat that update, so we
  // re-check a few times while a recent call still looks unfinished.
  static const _recheckDelay = Duration(seconds: 3);
  static const _maxRechecks = 4;
  static const _recentCallWindow = Duration(minutes: 3);
  Timer? _recheckTimer;
  int _recheckCount = 0;

  @override
  void initState() {
    super.initState();
    _socketService = SocketService(navigatorKey);
    _socketService.onCallLogUpdated(_handleCallLogUpdated);
    _fetchMessages();
    _scrollController.addListener(_checkIfAtBottom);
  }

  @override
  void dispose() {
    _socketService.offCallLogUpdated(_handleCallLogUpdated);
    _recheckTimer?.cancel();
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
      timestamp:
          DateTime.tryParse(messageJson.timestamp ?? '') ?? DateTime.now(),
      sender: messageJson.senderId ?? '', // no more `!` crash
      callerId: messageJson.callerId, // keeps call direction on reload
      type: messageJson.type,
      mediaUrl: messageJson.mediaUrl,
      form: primaryForm,
      forms: normalizedForms,
      callDuration: messageJson.callDuration,
      callStatus: messageJson.callStatus,
      callId: messageJson.callId,
      messageId: messageJson.messageId,
      isDeleted: messageJson.isDeleted ?? false,
      read: messageJson.read,
    );
  }

  /// Anything NOT owned by the customer is drawn on the agent (right) side,
  /// so messages from ANY agent (agent head, assigned agent, …) go right.
  /// For call logs the owner is the caller, not whatever senderId says.
  bool _isFromAgentSide(ChatMessageModel msg) {
    final owner = msg.ownerId?.trim().toLowerCase();
    if (owner == null || owner.isEmpty) return false;
    return owner != widget.customerEmail.trim().toLowerCase();
  }

  // ── Call-log helpers ──────────────────────────────────────────────────────

  static int _callRank(String? status) {
    switch (status) {
      case 'answered':
        return 3;
      case 'not answered':
      case 'declined':
        return 2;
      case 'missed':
        return 1;
      default:
        return 0; // null / "ringing" / unknown placeholder
    }
  }

  static String? _callKey(ChatMessageModel m) {
    if (m.type != 'call') return null;
    final id = m.callId ?? m.messageId;
    return (id == null || id.isEmpty) ? null : id;
  }

  /// A recent call whose status may still be the server's ringing placeholder.
  bool _looksUnfinished(ChatMessageModel m) {
    if (m.type != 'call') return false;
    if (_callRank(m.callStatus) > 1) return false;
    return DateTime.now().difference(m.timestamp).abs() < _recentCallWindow;
  }

  /// Keep a better status we already know (from a socket update or an earlier
  /// fetch) if the server response is behind.
  List<ChatMessageModel> _mergeWithKnown(List<ChatMessageModel> fetched) {
    final known = <String, ChatMessageModel>{};
    for (final m in messages) {
      final k = _callKey(m);
      if (k != null) known[k] = m;
    }
    for (final m in fetched) {
      final k = _callKey(m);
      if (k == null) continue;
      final old = known[k];
      if (old != null && _callRank(old.callStatus) > _callRank(m.callStatus)) {
        m.callStatus = old.callStatus;
        m.callDuration = old.callDuration;
      }
    }
    return fetched;
  }

  void _handleCallLogUpdated(Map<String, dynamic> data) {
    if (!mounted) return;
    final callId = data['callId']?.toString();
    final logId = data['_id']?.toString();
    final status = data['callStatus']?.toString();
    if (status == null) return;

    bool changed = false;
    for (final m in messages) {
      if (m.type != 'call') continue;
      final match = (callId != null && m.callId == callId) ||
          (logId != null && m.messageId == logId);
      if (!match) continue;
      if (_callRank(m.callStatus) > _callRank(status)) continue;
      m.callStatus = status;
      final d = data['callDuration']?.toString();
      if (d != null && d.isNotEmpty) m.callDuration = d;
      changed = true;
    }

    if (changed) {
      setState(() {});
    } else {
      // Log not in the list yet (e.g. fetched before it existed) → refetch.
      _fetchMessages(silent: true);
    }
  }

  void _scheduleRecheckIfNeeded() {
    _recheckTimer?.cancel();
    if (_recheckCount >= _maxRechecks) return;
    if (!messages.any(_looksUnfinished)) return;

    _recheckCount++;
    debugPrint('📞 [History] recent call still unfinished — '
        'recheck $_recheckCount/$_maxRechecks in ${_recheckDelay.inSeconds}s');
    _recheckTimer = Timer(_recheckDelay, () {
      if (mounted) _fetchMessages(silent: true);
    });
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    try {
      // Fetch ALL messages for this customer (includes all agents' messages)
      final allChats = await _chatRepository.fetchCustomerMessages(
        customerEmail: widget.customerEmail,
        limit: 500,
      );

      final chatMessages =
          _mergeWithKnown(allChats.map(_chatMessageFromModel).toList());
      chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (!mounted) return;
      final wasAtBottom = _isAtBottom;
      setState(() {
        messages = chatMessages;
        _isLoading = false;
      });

      if (!silent || wasAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      _scheduleRecheckIfNeeded();
    } catch (e) {
      debugPrint("Error fetching messages: $e");
      if (!mounted) return;
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
                                final isAgent = _isFromAgentSide(msg);
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
                                        // Key on status so the bubble rebuilds
                                        // when "missed" becomes "answered".
                                        key: ValueKey(
                                            '${_callKey(msg) ?? index}_${msg.callStatus}_${msg.callDuration}'),
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
                                          // History only on the agent side
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
                                        onLongPress: () {},
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
