import 'package:digital_life_care_app/providers/chat_provider.dart';
import 'package:digital_life_care_app/screens/chat/chat_room_screen.dart';
import 'package:digital_life_care_app/widgets/hw_top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HWChatScreen extends StatelessWidget {
  const HWChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
        title: const Text('Chat with Students'),
        actions: const [HWTopActions()],
      ),
      body: chatProvider.chatRooms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new chat to help students',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: chatProvider.chatRooms.length,
              itemBuilder: (context, index) {
                final room = chatProvider.chatRooms[index];
                return _ChatRoomCard(room: room);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final roomId = await context.read<ChatProvider>().startNewChat();
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(roomId: roomId),
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  final ChatRoom room;

  const _ChatRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(room.lastUpdated);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: room.hasUnread ? 3 : 1,
      child: ListTile(
        onTap: () {
          context.read<ChatProvider>().markAsRead(room.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(roomId: room.id),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.chat, color: Colors.white),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                room.title,
                style: TextStyle(
                  fontWeight: room.hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (room.hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          room.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: room.hasUnread ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: Text(
          timeAgo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
