import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/call_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/date_header.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/form_update_alert_dialog.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/shimmer_message_list.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/voice_message_bubble.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class CustomerChatScreen extends StatefulWidget {
  final String? customerName;
  final String? agentName;
  final String? customerEmail;
  final String? agentEmail;
  final GlobalKey<NavigatorState> navigatorKey;

  const CustomerChatScreen({
    super.key,
    this.customerName,
    this.agentName = "Agent",
    this.customerEmail,
    this.agentEmail,
    required this.navigatorKey,
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen>
    with WidgetsBindingObserver {
  final _chatController = TextEditingController();
  late final SocketService _socketService;
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final rateController = TextEditingController();
  final qualityController = TextEditingController();
  final quantityController = TextEditingController();
  final weaveController = TextEditingController();
  final compositionController = TextEditingController();
  final sNoController = TextEditingController();
  final ChatStorageService _chatStorageService = ChatStorageService();
  final ChatRepository _chatRepository = ChatRepository();
  bool isFormUpdating = false;
  bool _isLoading = true;
  final _productRepository = ProductRepository();

  List<ChatMessageModel> messages = [];
  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  String? userRole;
  final bool _isFetching = false;
  bool _isLoadingMore = false;
  bool _isAtBottom = true; // Track if the user is at the bottom of the list
  final Set<String> _loadedMessageIds = {};
  Timer? _dateHeaderTimer;
  bool _showDateHeader = false;

  final ValueNotifier<String?> _currentTopDate = ValueNotifier(null);

  final Map<Key, GlobalKey> _messageKeys = {};

  Future<void> _loadPreviousMessages() async {
    setState(() {
      _isLoading = true; // Set loading to true when starting to load messages
    });

    final boxName = widget.customerEmail!;
    bool boxExists = await Hive.boxExists(boxName);

    // Fetch the latest 20 messages from the API
    final List<MessageModel> fetchedMessages =
        await _chatRepository.fetchCustomerMessages(
      customerEmail: widget.customerEmail!,
      limit: 20,
    );

    // if (fetchedMessages.isEmpty) {
    //   setState(() {
    //     _isLoading = false; // Stop loading if no messages are fetched
    //   });
    //   return;
    // }

    // Convert MessageModel to ChatMessageModel
    final chatMessages = fetchedMessages.map((messageJson) {
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
        messageId: messageJson.messageId,
        isDeleted: messageJson.isDeleted ?? false,
      );
    }).toList();

    if (boxExists) {
      // Load messages from Hive
      final loadedMessages =
          await _chatStorageService.getCustomerMessages(boxName);
      final newLoadedMessages = _removeDuplicates(loadedMessages);

      // Compare the fetched messages with the ones in the Hive database
      final uniqueFetchedMessages = _removeDuplicates(chatMessages);
      final messagesToAdd = uniqueFetchedMessages.where((fetchedMessage) {
        return !newLoadedMessages.any((loadedMessage) {
          // For call-type messages, compare using callId, callDuration, callStatus
          if (fetchedMessage.type == 'call' && loadedMessage.type == 'call') {
            return loadedMessage.callId == fetchedMessage.callId;
          }

          // For all other message types, compare using messageId
          return loadedMessage.messageId == fetchedMessage.messageId;
        });
      }).toList();

      // Add the messages that are not in the Hive database to the list of messages
      newLoadedMessages.addAll(messagesToAdd);

      setState(() {
        messages = newLoadedMessages;
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false; // Set loading to false after messages are loaded
      });
    } else {
      // Save the fetched messages to the Hive database
      await _chatStorageService.saveMessages(chatMessages, boxName);

      setState(() {
        messages = chatMessages;
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false; // Set loading to false after messages are loaded
      });
    }

    // Scroll to bottom after loading messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _fetchMessagesFromAPI(String boxName) async {
    try {
      String? before;
      if (messages.isNotEmpty) {
        before = messages.first.timestamp.toIso8601String();
      }

      final List<MessageModel> fetchedMessages =
          await _chatRepository.fetchCustomerMessages(
        customerEmail: widget.customerEmail!,
        limit: 20,
        before: before,
      );

      if (fetchedMessages.isEmpty) {
        // No more messages to load
        return;
      }

      // Convert MessageModel to ChatMessageModel
      final chatMessages = fetchedMessages.map((messageJson) {
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
          messageId: messageJson.messageId,
          isDeleted: messageJson.isDeleted ?? false,
        );
      }).toList();

      final newChatMessages = _removeDuplicates(chatMessages);
      if (newChatMessages.isNotEmpty) {
        // Save all messages at once
        await _chatStorageService.saveMessages(newChatMessages, boxName);
        setState(() {
          messages.insertAll(0, newChatMessages);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
      }
    } catch (e) {
      // Handle errors properly
      debugPrint("Error fetching messages from API: $e");
      // You can show a snackbar or alert dialog to inform the user about the error
    }
  }

  List<ChatMessageModel> _removeDuplicates(List<ChatMessageModel> messages) {
    return messages.where((message) {
      if (_loadedMessageIds.contains(message.messageId)) {
        return false;
      } else {
        _loadedMessageIds.add(message.messageId!);
        return true;
      }
    }).toList();
  }

  void _showFloatingDateHeader() {
    setState(() {
      _showDateHeader = true;
    });

    // Cancel existing timer if user is still scrolling
    _dateHeaderTimer?.cancel();

    // Start new timer to hide after 1 second
    _dateHeaderTimer = Timer(Duration(seconds: 1), () {
      setState(() {
        _showDateHeader = false;
      });
    });
  }

  void _hideFloatingDateHeader() {
    // Optionally hide immediately when scrolling down
    setState(() {
      _showDateHeader = false;
    });

    // Cancel the timer to avoid it interfering
    _dateHeaderTimer?.cancel();
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      _showFloatingDateHeader();
    }

    // Hide header when scrolling down (optional, but could improve UX)
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      _hideFloatingDateHeader();
    }

    // Check if at the top edge, then load more messages
    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels == 0) {
      _loadMoreMessages();
    }

    // Find index of first visible message and update date
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final firstVisibleIndex = _getFirstVisibleIndex();
      if (firstVisibleIndex != null && firstVisibleIndex < messages.length) {
        final message = messages[firstVisibleIndex];
        final newDate = ChatUtils().formatDateHeader(message.timestamp);
        if (_currentTopDate.value != newDate) {
          _currentTopDate.value = newDate;
        }
      }
    }
  }

  int? _getFirstVisibleIndex() {
    for (int i = 0; i < messages.length; i++) {
      final key = ValueKey('chat-msg-$i');
      final context = _messageKeys[key]?.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final pos = box.localToGlobal(Offset.zero);
          if (pos.dy >= 0) {
            return i;
          }
        }
      }
    }
    return null;
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

  Future<void> _loadMoreMessages() async {
    if (_isFetching || _isLoadingMore) return;
    _isLoadingMore = true;
    setState(() {});

    final boxName = widget.customerEmail!;
    await _fetchMessagesFromAPI(boxName);

    _isLoadingMore = false;
    setState(() {});
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  Future<void> _fetchUserRole() async {
    final role = await LocalDbHelper.getUserType();
    setState(() {
      userRole = role;
    });
  }

  @override
  void initState() {
    _fetchUserRole();
    super.initState();
    _socketService = SocketService(widget.navigatorKey);
    WidgetsBinding.instance.addObserver(this);
    _socketService.setChatPageState(
      isOpen: true,
      customerId: widget.customerEmail, // This is targetId in incoming message
    );
    _socketService.onReceiveMessage(_handleIncomingMessage);
    _socketService.onMessageDeleted(_handleMessageDeleted);
    _loadPreviousMessages();
    _initializeRecorder();
    _scrollController.addListener(_handleScroll);
    _scrollController.addListener(_checkIfAtBottom);

    _resetMessageCount();
  }

  Future<void> _resetMessageCount() async {
    final boxNameWithCount = '${widget.customerEmail}count';
    final box = await Hive.openBox<int>(boxNameWithCount);
    await box.put('count', 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.dispose();
    qualityController.dispose();
    quantityController.dispose();
    sNoController.dispose();
    compositionController.dispose();
    _recorder.closeRecorder();
    _timer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.removeListener(_checkIfAtBottom);
    _socketService.toggleChatPageOpen(false);
    _dateHeaderTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _socketService.setChatPageState(isOpen: false);
    } else if (state == AppLifecycleState.resumed) {
      _socketService.setChatPageState(
        isOpen: true,
        customerId:
            widget.customerEmail, // This is targetId in incoming message
      );
    }
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;

    if (newValue) {
      // Keyboard is opened
      _scrollToBottom();
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    debugPrint("Received Message: ${data.toString()}");

    DateTime timestamp;
    try {
      timestamp = DateTime.parse(data["timestamp"]);
    } catch (_) {
      timestamp = DateTime.now(); // fallback in case of bad format
    }

    final message = ChatMessageModel(
      message: data["message"],
      timestamp: timestamp,
      sender: data["senderId"],
      type: data["type"] ?? "text",
      mediaUrl: data["mediaUrl"],
      form: data["form"],
      messageId: data['messageId'],
    );

    if (!_loadedMessageIds.contains(message.messageId)) {
      setState(() {
        messages.add(message);
        // messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _scrollToBottom();
      });

      _chatStorageService.saveMessage(message, widget.customerEmail!);
      _loadedMessageIds.add(message.messageId!);
    }
  }

  void _handleMessageDeleted(String messageId) {
    setState(() {
      final index =
          messages.indexWhere((message) => message.messageId == messageId);
      if (index != -1) {
        messages[index].isDeleted = true;
        messages[index].message = "This message is deleted";
      }
    });

    // Save the updated message state to local storage

    final boxName = widget.customerEmail!;
    _chatStorageService.saveMessage(
        messages.firstWhere((message) => message.messageId == messageId),
        boxName);
  }

  void _sendMessage({
    required String messageText,
    String? type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? form,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null && form == null) return;

    final currentTime = DateTime.now();
    final messageId = ChatUtils().generateMessageId();
    final message = ChatMessageModel(
      message: messageText,
      timestamp: currentTime,
      sender: widget.customerEmail!,
      type: type!,
      mediaUrl: mediaUrl,
      form: form,
      messageId: messageId,
      isDeleted: false,
    );

    if (!_loadedMessageIds.contains(messageId)) {
      setState(() {
        messages.add(message);
        // messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _scrollToBottom();
      });

      final String? name = LocalDbHelper.getProfile()?.name;

      _socketService.sendMessage(
        message: messageText,
        senderEmail: widget.customerEmail!,
        senderName: name!,
        type: type,
        mediaUrl: mediaUrl,
        form: form,
        timestamp: currentTime.toIso8601String(), // ✅ Send timestamp
        messageId: messageId,
      );

      _chatStorageService.saveMessage(message, widget.customerEmail!);
      _loadedMessageIds.add(messageId);
    }
    _chatController.clear();
  }

  void _showDeleteDialog(BuildContext context, String messageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Message"),
          content: const Text("Are you sure you want to delete this message?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage(messageId);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteMessage(String messageId) {
    _socketService.deleteMessage(messageId);

    // Update the local message state to reflect deletion
    setState(() {
      final index =
          messages.indexWhere((message) => message.messageId == messageId);
      if (index != -1) {
        messages[index].isDeleted = true;
        messages[index].message = "This message is deleted";
      }
    });

    // Save the updated message state to local storage

    final boxName = widget.customerEmail!;
    _chatStorageService.saveMessage(
        messages.firstWhere((message) => message.messageId == messageId),
        boxName);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    await _recorder.startRecorder(toFile: 'voice_message.aac');
    setState(() {
      _isRecording = true;
      _recordedSeconds = 0; // Reset recorded seconds
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordedSeconds++;
        });
      });
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecorder();
    _timer?.cancel(); // Stop the timer
    if (path != null) {
      final File voiceFile = File(path);
      final voiceUrl =
          await _s3uploadService.uploadFile(voiceFile, isVoiceMessage: true);
      if (voiceUrl != null) {
        _sendMessage(messageText: "voice", type: 'voice', mediaUrl: voiceUrl);
      }
    }
    setState(() {
      _isRecording = false;
    });
  }

  void _addTemporaryMessage(String messageText) {
    final currentTime = DateTime.now();
    final temporaryMessage = ChatMessageModel(
      message: messageText,
      timestamp: currentTime,
      sender: "",
    );

    setState(() {
      messages.add(temporaryMessage);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    _scrollToBottom();
  }

  void _sendProductMessage(Product product) {
    // Convert the product object to a JSON string
    final productJson = jsonEncode(product.toJson());

    _sendMessage(
      messageText: productJson,
      type: 'product',
    );
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Add a temporary message
      _addTemporaryMessage("Sending image...");

      final File imageFile = File(pickedFile.path);
      final imageUrl = await _s3uploadService.uploadFile(imageFile);
      if (imageUrl != null) {
        // Remove the temporary message
        setState(() {
          messages
              .removeWhere((message) => message.message == "Sending image...");
        });

        // Send the actual message
        _sendMessage(messageText: "image", type: 'media', mediaUrl: imageUrl);
      }
    }
  }

  Future<void> _pickAndSendImageByCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // Add a temporary message
      _addTemporaryMessage("Sending image...");

      final File imageFile = File(pickedFile.path);
      final imageUrl = await _s3uploadService.uploadFile(imageFile);
      if (imageUrl != null) {
        // Remove the temporary message
        setState(() {
          messages
              .removeWhere((message) => message.message == "Sending image...");
        });

        // Send the actual message
        _sendMessage(messageText: "image", type: 'media', mediaUrl: imageUrl);
      }
    }
  }

  Future<void> _pickAndSendDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result != null) {
      // Add a temporary message
      _addTemporaryMessage(
        "Sending document...",
      );

      final PlatformFile file = result.files.first;
      final File documentFile = File(file.path!);
      final documentUrl = await _s3uploadService.uploadDocument(documentFile);
      if (documentUrl != null) {
        // Remove the temporary message
        setState(() {
          messages.removeWhere(
              (message) => message.message == "Sending document...");
        });

        // Send the actual message
        _sendMessage(
            messageText: "document", type: 'document', mediaUrl: documentUrl);
      }
    }
  }

  void _showProductsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FutureBuilder<List<Product>>(
          future: _productRepository.getProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error loading products"));
            } else {
              final products = snapshot.data;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  itemCount: products?.length,
                  itemBuilder: (context, index) {
                    final product = products![index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              spreadRadius: 0,
                              color: Colors.black.withValues(alpha: 0.15),
                              offset: const Offset(0, 1),
                            )
                          ]),
                      child: ListTile(
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  product.imageUrl,
                                  height: 60,
                                  width: 65,
                                  fit: BoxFit.cover,
                                )),
                            const SizedBox(width: 4),
                            Text(
                              product.productName,
                              style: AppTextStyles.black12_700,
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.ios_share_rounded,
                          color: AppColors.blue0056FB,
                        ),
                        onTap: () {
                          _sendProductMessage(product);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              );
            }
          },
        );
      },
    );
  }

  void _showFormOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            height: Utils().height(context) * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Please fill in the form details",
                    style: AppTextStyles.black16_600),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(labelText: "Quality"),
                  controller: qualityController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quality';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Quantity"),
                  controller: quantityController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Weave"),
                  controller: weaveController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weave';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Composition"),
                  controller: compositionController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter composition';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final formData = {
                        "quality": qualityController.text,
                        "quantity": quantityController.text,
                        "weave": weaveController.text,
                        "composition": compositionController.text,
                        "rate": 0,
                      };
                      _sendMessage(
                          messageText: "product", type: 'form', form: formData);
                      Navigator.pop(context);
                    }
                  },
                  textColor: Colors.white,
                  fontSize: 14,
                  backgroundColor: AppColors.blue,
                  text: "Submit",
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openFormDialogToUpdateRate(Map<String, dynamic> formData) {
    final rateController = TextEditingController();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return FormUpdateAlertDialog(
          formId: formData["_id"],
          quality: formData['quality'],
          quantity: formData['quantity'],
          weave: formData['weave'],
          composition: formData['composition'],
          rateController: rateController,
          onCancel: () {
            Navigator.of(context).pop();
          },
          onSubmit: () {
            final newRate = rateController.text;
            if (newRate.isNotEmpty) {
              _updateFormRate(context, formData, newRate);
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _updateFormRate(BuildContext context,
      Map<String, dynamic> formData, String newRate) async {
    setState(() {
      isFormUpdating = true;
    });
    final id = formData['_id']?.toString();
    if (id == null) {
      debugPrint(
          "No form id is found to update: $id in the ${formData.toString()}");
      return;
    }

    try {
      await _chatRepository.updateInquiryFormRate(id, newRate);
      debugPrint("Rate updated successfully");
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Rate is updated: $newRate")));
      }

      final updatedFormData = Map<String, dynamic>.from(formData);
      updatedFormData['rate'] = newRate;
      _sendMessage(
          messageText:
              "Rate updated as $newRate for form with Id : ${formData["_id"]}");
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating rate of the form: $e');
      }
    } finally {
      setState(() {
        isFormUpdating = false;
      });
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateFormat('hh:mm a').format(DateTime.now());
    }

    try {
      final dateTime = timestamp is DateTime
          ? timestamp
          : DateTime.parse(timestamp.toString());
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return DateFormat('hh:mm a').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Row(
            children: [
              Initicon(text: "Agent"),
              const SizedBox(width: 5),
              Text(
                widget.agentName ?? "Agent",
                style: AppTextStyles.black14_400,
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                // final channelName = sha256
                //     .convert(utf8.encode(widget.customerEmail!))
                //     .toString();
                final uid =
                    Utils().generateIntUidFromEmail(widget.customerEmail!);
                debugPrint("Generated UID for agent (caller): $uid");
                final timestamp = DateTime.now();

                final callId = Uuid().v4();
                final rawChannel = '${widget.customerEmail}_$callId';
                final channelName = sha256
                    .convert(utf8.encode(rawChannel))
                    .toString(); // different channel name for every call
                _socketService.sendAgoraCall(
                  channelName: channelName,
                  callerId: widget.customerEmail!,
                  callerName: widget.customerName!,
                  callId: callId,
                  timestamp: timestamp.toIso8601String(),
                );

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AgoraAudioCallScreen(
                      isCaller: true,
                      channelName: channelName,
                      uid: uid,
                      remoteUserName: widget.agentName!,
                      callId: callId,
                      timestamp: timestamp,
                      navigatorKey: navigatorKey,
                    ),
                  ),
                );

                // ✅ Check if the call was terminated without connecting
                if (result != null &&
                    result is Map &&
                    result['terminated'] == true) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Call was rejected or terminated.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                if (result != null) {
                  // print(
                  //     "✅ call data saved in the local as: ${result.toString()}");
                  await _chatStorageService.saveMessage(
                      result, widget.customerEmail!);
                  setState(() {
                    messages.add(result);
                    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                  });
                  _scrollToBottom();
                }
              },
              icon: const Icon(Icons.call_outlined, color: Colors.black),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_isLoadingMore)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                Expanded(
                  child: _isLoading
                      ? ShimmerMessageList()
                      : messages.isEmpty
                          ? NoChatConversation()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(10),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isCustomer =
                                    msg.sender == widget.customerEmail;
                                final valueKey = ValueKey('chat-msg-$index');
                                final globalKey = GlobalKey();
                                _messageKeys[valueKey] = globalKey;
                                String? dateHeader;

                                if (index == 0 ||
                                    !ChatUtils().isSameDay(
                                        messages[index - 1].timestamp,
                                        msg.timestamp)) {
                                  dateHeader = ChatUtils()
                                      .formatDateHeader(msg.timestamp);
                                }

                                return Container(
                                  key: globalKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (dateHeader != null)
                                        DateHeader(date: dateHeader),
                                      if (msg.type == 'media')
                                        ImageMessageBubble(
                                          imageUrl: msg.mediaUrl!,
                                          isMe: msg.sender ==
                                              widget.customerEmail,
                                          timestamp:
                                              formatTimestamp(msg.timestamp),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isCustomer
                                              ? () => _showDeleteDialog(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        )
                                      else if (msg.type == 'form')
                                        FormMessageBubble(
                                          formData: msg.form!,
                                          isMe: msg.sender == widget.agentEmail,
                                          timestamp: formatTimestamp(
                                              msg.timestamp.toIso8601String()),
                                          userRole: userRole!,
                                        )
                                      else if (msg.type == 'document')
                                        DocumentMessageBubble(
                                          documentUrl: msg.mediaUrl!,
                                          isMe: msg.sender ==
                                              widget.customerEmail,
                                          timestamp:
                                              formatTimestamp(msg.timestamp),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isCustomer
                                              ? () => _showDeleteDialog(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        )
                                      else if (msg.type == 'voice')
                                        VoiceMessageBubble(
                                          voiceUrl: msg.mediaUrl!,
                                          isMe: msg.sender ==
                                              widget.customerEmail,
                                          timestamp:
                                              formatTimestamp(msg.timestamp),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isCustomer
                                              ? () => _showDeleteDialog(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        )
                                      else if (msg.type == 'call')
                                        CallMessageBubble(
                                          isMe: msg.sender == widget.agentEmail,
                                          timestamp: formatTimestamp(
                                              msg.timestamp.toIso8601String()),
                                          callStatus: msg.callStatus ?? "",
                                          callDuration: msg.callDuration ?? '',
                                        )
                                      else if (msg.message == 'Fill details')
                                        FillFormButton(
                                          buttonText: "Fill product details",
                                          onSubmit: _showFormOverlay,
                                        )
                                      else if (msg.message ==
                                          "Update form rate")
                                        FillFormButton(
                                          buttonText: "Update Form",
                                          onSubmit: () {
                                            openFormDialogToUpdateRate(
                                                msg.form!);
                                          },
                                        )
                                      else
                                        MessageBubble(
                                          message: msg,
                                          isMe: msg.sender ==
                                              widget.customerEmail,
                                          onLongPress: isCustomer
                                              ? () => _showDeleteDialog(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
                ChatInputField(
                  controller: _chatController,
                  onSend: () => _sendMessage(messageText: _chatController.text),
                  onSendImage: _pickAndSendImage,
                  onSendImageByCamera: _pickAndSendImageByCamera,
                  onSendForm: _showFormOverlay,
                  onSendDocument: _pickAndSendDocument,
                  onShareProduct: () => _showProductsBottomSheet(context),
                  onSendVoice: _isRecording ? _stopRecording : _startRecording,
                  isRecording: _isRecording,
                  recordedSeconds: _recordedSeconds,
                ),
              ],
            ),
            if (isFormUpdating) FullScreenLoader(),
            if (!_isAtBottom)
              Positioned(
                bottom: 80, // Adjust the position as needed
                right: 16, // Adjust the position as needed
                child: FloatingActionButton(
                  onPressed: _scrollToBottom,
                  mini: true,
                  backgroundColor: AppColors.blue0056FB.withAlpha(50),
                  child: Icon(Icons.arrow_downward_rounded),
                ),
              ),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<String?>(
                valueListenable: _currentTopDate,
                builder: (context, date, _) {
                  if (date == null || !_showDateHeader) {
                    return SizedBox.shrink();
                  }
                  return Center(
                    child: DateHeader(date: date),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
