import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:digital_life_care_app/providers/chat_provider.dart';
import 'package:digital_life_care_app/screens/health_worker/hw_chat_detail_screen.dart';

class HWChatListScreen extends StatelessWidget {
  const HWChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Requests'),
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: chatProvider.streamHealthWorkerChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => (context as Element).markNeedsBuild(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          // Separate pending and active chats
          final pendingChats = chatRooms.where((r) => r.status == 'pending').toList();
          final activeChats = chatRooms.where((r) => r.status == 'active').toList();

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'No chat requests',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see student requests here',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (pendingChats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Pending Requests (${pendingChats.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ...pendingChats.map((room) => _HWChatCard(
                      room: room,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HWChatDetailScreen(roomId: room.id),
                          ),
                        );
                      },
                    )),
                const SizedBox(height: 16),
              ],
              if (activeChats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.chat, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Active Chats (${activeChats.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ...activeChats.map((room) => _HWChatCard(
                      room: room,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HWChatDetailScreen(roomId: room.id),
                          ),
                        );
                      },
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HWChatCard extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;

  const _HWChatCard({
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = room.status == 'pending';
    final timeAgo = _formatTimeAgo(room.lastMessageAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isPending ? Colors.orange[100] : Colors.green[100],
                child: Icon(
                  isPending ? Icons.help_outline : Icons.chat,
                  color: isPending ? Colors.orange : Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.subject ?? 'Health Inquiry',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.lastMessage,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPending
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPending
                                  ? Colors.orange.withOpacity(0.3)
                                  : Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            isPending ? 'New Request' : 'Active',
                            style: TextStyle(
                              fontSize: 11,
                              color: isPending ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (room.hwUnread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${room.hwUnread}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // String _formatTimeAgo(DateTime dateTime) {
  //   final now = DateTime.now();
  //   final difference = now.difference(dateTime);

  //   if (difference.inMinutes < 1) {
  //     return 'Just now';
  //   } else if (difference.inHours < 1) {
  //     return '${difference.inMinutes}m ago';
  //   } else if (difference.inHours < 24) {
  //     return '${difference.inHours}h ago';
  //   } else if (difference.inDays
