import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:digital_life_care_app/providers/chat_provider.dart';
import 'package:digital_life_care_app/providers/user_provider.dart';

class HWChatDetailScreen extends StatefulWidget {
  final String roomId;

  const HWChatDetailScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<HWChatDetailScreen> createState() => _HWChatDetailScreenState();
}

class _HWChatDetailScreenState extends State<HWChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isAccepting = false;
  ChatRoom? _currentRoom;

  @override
  void initState() {
    super.initState();
    _loadRoom();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRoom() async {
    final chatProvider = context.read<ChatProvider>();
    final room = await chatProvider.getChatRoom(widget.roomId);
    if (mounted) {
      setState(() => _currentRoom = room);
    }
  }

  Future<void> _markAsRead() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.markAsRead(
      roomId: widget.roomId,
      userRole: 'health_worker',
    );
  }

  Future<void> _acceptChat() async {
    if (_isAccepting) return;

    setState(() => _isAccepting = true);

    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.acceptChat(widget.roomId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat accepted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.sendMessage(
        roomId: widget.roomId,
        text: text,
        senderRole: 'health_worker',
      );

      _messageController.clear();
      
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _closeChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Chat'),
        content: const Text('Are you sure you want to close this chat? Students won\'t be able to send more messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Close Chat'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.closeChat(widget.roomId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat closed')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<ChatRoom?>(
          future: chatProvider.getChatRoom(widget.roomId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final room = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.subject ?? 'Student Inquiry',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    _getStatusText(room.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              );
            }
            return const Text('Chat');
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'close') {
                _closeChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(Icons.close, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Close Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Accept chat banner for pending chats
          FutureBuilder<ChatRoom?>(
            future: chatProvider.getChatRoom(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.status == 'pending') {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange[100],
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New chat request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Accept this chat to start helping the student',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isAccepting ? null : _acceptChat,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: _isAccepting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Accept'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Messages list
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: chatProvider.streamMessages(widget.roomId),
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
                        Text('Error loading messages: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isHealthWorker = message.senderRole == 'health_worker';
                    
                    return _MessageBubble(
                      message: message,
                      isMe: isHealthWorker,
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isSending,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting to be accepted...';
      case 'active':
        return 'Active conversation';
      case 'closed':
        return 'Conversation closed';
      default:
        return status;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: const Icon(Icons.person, size: 16, color: Colors.green),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.local_hospital, size: 16, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }
}
