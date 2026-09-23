import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/globals.dart';
import '../../utils/sendPushNotificationToUser.dart';

// --- MODELS ---

enum MessageType { text, image }

enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: (data['type'] == 'image') ? MessageType.image : MessageType.text,
      status: _parseStatus(data['status']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type == MessageType.image ? 'image' : 'text',
      'status': 'sent',
    };
  }

  static MessageStatus _parseStatus(String? status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }
}

class ChatUser {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;

  const ChatUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
  });
}

// --- MESSAGE SCREEN WITH FIRESTORE INTEGRATION ---

class MessageScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final ChatUser recipient;

  const MessageScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.recipient,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  static const Color primaryColor = Color(0xFFE66C75);
  static const Color darkBackground = Color(0xFF111318);
  static const Color cardBackground = Color(0xFF1A1D24);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ValueNotifier<bool> _showSendButtonNotifier = ValueNotifier<bool>(false);

  Timer? _typingTimer;
  bool _isTyping = false;
  String? _fcmToken;
  String? _avatar = "";

  late final CollectionReference _messagesRef;
  late final DocumentReference _chatDocRef;
  late final Stream<QuerySnapshot> _messagesStream;
  late final Stream<DocumentSnapshot> _chatDocStream;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);

    _chatDocRef =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    _messagesRef = _chatDocRef.collection('messages');

    _messagesStream = _messagesRef.orderBy('timestamp', descending: false).limitToLast(100).snapshots();
    _chatDocStream = _chatDocRef.snapshots();

    _fetchRecipientToken();
  }

  Future<void> _fetchRecipientToken() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('new-users')
          .doc(widget.recipient.id)
          .get();
      if (doc.exists) {
        setState(() {
          _fcmToken = doc['fcmToken'];
          _avatar = doc['profilePicture'];
        });
      }
    } catch (e) {
      debugPrint("Config Error: $e");
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _showSendButtonNotifier.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final textLength = _messageController.text.trim().length;
    _showSendButtonNotifier.value = textLength > 0;

    // Debounce typing status updates to Firestore
    if (textLength > 0) {
      if (!_isTyping) {
        _isTyping = true;
        _updateTypingStatus(true);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _isTyping = false;
        _updateTypingStatus(false);
      });
    } else {
      _typingTimer?.cancel();
      if (_isTyping) {
        _isTyping = false;
        _updateTypingStatus(false);
      }
    }
  }

  void _updateTypingStatus(bool isTyping) {
    _chatDocRef.set({
      'typingStatus': {
        widget.currentUserId: isTyping,
      }
    }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    _isTyping = false;
    _updateTypingStatus(false);

    _messageController.clear();
    _showSendButtonNotifier.value = false;

    try {
      final newMsgDoc = _messagesRef.doc();
      final newMessage = ChatMessage(
        id: newMsgDoc.id,
        senderId: widget.currentUserId,
        text: text,
        timestamp: DateTime.now(),
      );

      await newMsgDoc.set(newMessage.toFirestore());

      await _chatDocRef.set({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': widget.currentUserId,
        'typingStatus': {
          widget.currentUserId: false,
        }
      }, SetOptions(merge: true));

      _scrollToBottom();

      await sendPushNotificationToUser(
        recipientFcmToken: _fcmToken ?? "",
        title: "New Message from $globalFirstName",
        body: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages',
                          style: TextStyle(color: Colors.red.shade300),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      );
                    }

                    final messages = docs
                        .map((doc) => ChatMessage.fromFirestore(doc))
                        .toList();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return StreamBuilder<DocumentSnapshot>(
                      stream: _chatDocStream,
                      builder: (context, chatDocSnapshot) {
                        bool isRecipientTyping = false;
                        if (chatDocSnapshot.hasData &&
                            chatDocSnapshot.data!.exists) {
                          final data = chatDocSnapshot.data!.data()
                          as Map<String, dynamic>?;
                          final typingData =
                          data?['typingStatus'] as Map<String, dynamic>?;
                          isRecipientTyping =
                              typingData?[widget.recipient.id] ?? false;
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount:
                          messages.length + (isRecipientTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length && isRecipientTyping) {
                              return _buildTypingIndicator();
                            }

                            final message = messages[index];
                            final isMe =
                                message.senderId == widget.currentUserId;
                            final showHeader = index == 0 ||
                                _shouldShowDateHeader(
                                  messages[index - 1].timestamp,
                                  message.timestamp,
                                );

                            return Column(
                              children: [
                                if (showHeader)
                                  _buildDateHeader(message.timestamp),
                                _ChatBubble(
                                  message: message,
                                  isMe: isMe,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: darkBackground,
      elevation: 0,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor.withOpacity(0.2),
                backgroundImage: _avatar != ""
                    ? MemoryImage(base64Decode(_avatar ?? ""))
                    : null,
                child: (_avatar == ""
                    ? Text(
                  _getInitial(widget.recipient.name),
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null),
              ),
              if (widget.recipient.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: darkBackground, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipient.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.recipient.isOnline ? 'Active' : 'Active',
                  style: TextStyle(
                    color: widget.recipient.isOnline
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBackground,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            onPressed: () => _showAttachmentOptions(context),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: darkBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<bool>(
            valueListenable: _showSendButtonNotifier,
            builder: (context, showSendButton, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: showSendButton
                    ? Container(
                  key: const ValueKey('send_btn'),
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                )
                    : Container(
                  key: const ValueKey('mic_btn'),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.mic_rounded,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: primaryColor.withValues(alpha: 0.2),
            backgroundImage: widget.recipient.avatarUrl.isNotEmpty
                ? NetworkImage(widget.recipient.avatarUrl)
                : null,
            child: widget.recipient.avatarUrl.isEmpty
                ? Text(
              widget.recipient.name.isNotEmpty
                  ? widget.recipient.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                    (i) => _PulseDot(delayMs: i * 200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateHeader(DateTime prev, DateTime current) {
    return current.difference(prev).inMinutes > 30;
  }

  Widget _buildDateHeader(DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            _formatDateHeader(timestamp),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.day == now.day &&
        timestamp.month == now.month &&
        timestamp.year == now.year) {
      return 'TODAY';
    }
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _AttachmentOption(
              icon: Icons.image_rounded,
              color: primaryColor,
              label: 'Gallery',
              onTap: () => Navigator.pop(context),
            ),
            _AttachmentOption(
              icon: Icons.camera_alt_rounded,
              color: Colors.pinkAccent,
              label: 'Camera',
              onTap: () => Navigator.pop(context),
            ),
            _AttachmentOption(
              icon: Icons.insert_drive_file_rounded,
              color: Colors.blueAccent,
              label: 'Document',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CHAT BUBBLE WIDGET ---

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  static const Color primaryColor = Color(0xFFE66C75);
  static const Color cardBackground = Color(0xFF1A1D24);

  const _ChatBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? primaryColor : cardBackground;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          border: isMe
              ? null
              : Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: Colors.white70),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Colors.lightBlueAccent);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// --- TYPING ANIMATION DOT ---

class _PulseDot extends StatefulWidget {
  final int delayMs;
  const _PulseDot({required this.delayMs});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// --- ATTACHMENT OPTION WIDGET ---

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String _getInitial(String name) {
  final parts = name.trim().split(' ');
  if (parts.length > 1) {
    return parts[1][0].toUpperCase();
  } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
    return parts[0][0].toUpperCase();
  }
  return 'L';
}