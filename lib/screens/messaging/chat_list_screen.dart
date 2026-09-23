import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'message_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String currentUserId;

  static const Color primaryColor = Color(0xFFE66C75);
  static const Color darkBackground = Color(0xFF111318);
  static const Color cardBackground = Color(0xFF1A1D24);

  const ChatListScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where(
          'participants',
          arrayContains: currentUserId,
        )
            .orderBy(
          'lastMessageTime',
          descending: true,
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('CHAT LIST ERROR: ${snapshot.error}');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load conversations.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          final chatDocs = snapshot.data?.docs ?? [];

          if (chatDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chatDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              try {
                final doc = chatDocs[index];

                final rawData = doc.data();

                if (rawData is! Map<String, dynamic>) {
                  debugPrint(
                    'Invalid chat data for document ${doc.id}',
                  );

                  return const SizedBox.shrink();
                }

                final data = rawData;

                // -----------------------------
                // PARTICIPANTS
                // -----------------------------

                final rawParticipants = data['participants'];

                if (rawParticipants is! List) {
                  debugPrint(
                    'Chat ${doc.id}: participants is missing or invalid',
                  );

                  return const SizedBox.shrink();
                }

                final participants = rawParticipants
                    .map((e) => e.toString())
                    .toList();

                String recipientId = '';

                for (final id in participants) {
                  if (id != currentUserId) {
                    recipientId = id;
                    break;
                  }
                }

                if (recipientId.isEmpty) {
                  debugPrint(
                    'Chat ${doc.id}: recipient ID could not be determined',
                  );

                  return const SizedBox.shrink();
                }

                // -----------------------------
                // PARTICIPANT DATA
                // -----------------------------

                final rawParticipantsData = data['participantsData'];

                Map<String, dynamic> participantsData = {};

                if (rawParticipantsData is Map) {
                  participantsData = Map<String, dynamic>.from(
                    rawParticipantsData,
                  );
                }

                // -----------------------------
                // RECIPIENT INFO
                // -----------------------------

                Map<String, dynamic> recipientInfo = {};

                final rawRecipientInfo =
                participantsData[recipientId];

                if (rawRecipientInfo is Map) {
                  recipientInfo = Map<String, dynamic>.from(
                    rawRecipientInfo,
                  );
                }

                final recipientName =
                (recipientInfo['name'] ?? 'Legal Advisor').toString();

                final avatarUrl =
                (recipientInfo['avatarUrl'] ?? '').toString();

                final isOnline =
                    recipientInfo['isOnline'] == true;

                final lastMessage =
                (data['lastMessage'] ?? '').toString();

                DateTime? lastTime;

                final rawLastTime = data['lastMessageTime'];

                if (rawLastTime is Timestamp) {
                  lastTime = rawLastTime.toDate();
                }

                final recipient = ChatUser(
                  id: recipientId,
                  name: recipientName,
                  avatarUrl: avatarUrl,
                  isOnline: isOnline,
                );

                return _buildChatTile(
                  context: context,
                  chatId: doc.id,
                  recipient: recipient,
                  lastMessage: lastMessage,
                  lastTime: lastTime,
                );
              } catch (e, stackTrace) {
                debugPrint(
                  'ERROR BUILDING CHAT ITEM [$index]: $e',
                );

                debugPrintStack(
                  stackTrace: stackTrace,
                );

                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required String chatId,
    required ChatUser recipient,
    required String lastMessage,
    required DateTime? lastTime,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessageScreen(
                  chatId: chatId,
                  currentUserId: currentUserId,
                  recipient: recipient,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryColor.withValues(alpha: 0.2),
                      backgroundImage: recipient.avatarUrl.isNotEmpty
                          ? NetworkImage(recipient.avatarUrl)
                          : null,
                      child: recipient.avatarUrl.isEmpty
                          ? Text(
                        recipient.name.isNotEmpty
                            ? recipient.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    if (recipient.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBackground, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              recipient.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastTime != null)
                            Text(
                              _formatTime(lastTime),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage.isNotEmpty ? lastMessage : 'Tap to start conversation',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day && time.month == now.month && time.year == now.year) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${time.day}/${time.month}';
  }
}