import 'package:flutter/material.dart';

class Message {
  final String id;
  final String text;
  final String sender; // 'student' or 'healthworker'
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isRead = false,
  });
}

class ChatRoom {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastUpdated;
  final bool hasUnread;

  ChatRoom({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastUpdated,
    this.hasUnread = false,
  });
}

class ChatProvider extends ChangeNotifier {
  final List<ChatRoom> _chatRooms = [
    ChatRoom(
      id: '1',
      title: 'Health Inquiry #1',
      lastMessage: 'Thank you for your question...',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      hasUnread: true,
    ),
    ChatRoom(
      id: '2',
      title: 'Health Inquiry #2',
      lastMessage: 'I understand your concern...',
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      hasUnread: false,
    ),
  ];

  final Map<String, List<Message>> _messages = {
    '1': [
      Message(
        id: 'm1',
        text: 'I have a question about STD prevention',
        sender: 'student',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Message(
        id: 'm2',
        text: 'Hello! I\'m here to help. What would you like to know?',
        sender: 'healthworker',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
      ),
      Message(
        id: 'm3',
        text: 'What are the most effective prevention methods?',
        sender: 'student',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
      ),
    ],
    '2': [
      Message(
        id: 'm4',
        text: 'Can you explain the testing process?',
        sender: 'student',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  };

  bool _isTyping = false;

  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isTyping => _isTyping;

  List<Message> getMessages(String roomId) {
    return _messages[roomId] ?? [];
  }

  Future<String> startNewChat() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newRoom = ChatRoom(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Health Inquiry #${_chatRooms.length + 1}',
      lastMessage: 'Chat started',
      lastUpdated: DateTime.now(),
      hasUnread: false,
    );
    _chatRooms.insert(0, newRoom);
    _messages[newRoom.id] = [];
    notifyListeners();
    return newRoom.id;
  }

  Future<void> sendMessage(String roomId, String text) async {
    final message = Message(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: 'student',
      timestamp: DateTime.now(),
    );

    _messages[roomId] = [...(_messages[roomId] ?? []), message];

    // Update room last message
    final roomIndex = _chatRooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      _chatRooms[roomIndex] = ChatRoom(
        id: roomId,
        title: _chatRooms[roomIndex].title,
        lastMessage: text,
        lastUpdated: DateTime.now(),
        hasUnread: false,
      );
    }

    notifyListeners();

    // Simulate health worker typing
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    // Simulate health worker response
    final response = Message(
      id: 'mr${DateTime.now().millisecondsSinceEpoch}',
      text: 'Thank you for your question. Let me provide you with some information...',
      sender: 'healthworker',
      timestamp: DateTime.now(),
    );

    _messages[roomId] = [...(_messages[roomId] ?? []), response];
    _isTyping = false;
    notifyListeners();
  }

  void markAsRead(String roomId) {
    final roomIndex = _chatRooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      _chatRooms[roomIndex] = ChatRoom(
        id: _chatRooms[roomIndex].id,
        title: _chatRooms[roomIndex].title,
        lastMessage: _chatRooms[roomIndex].lastMessage,
        lastUpdated: _chatRooms[roomIndex].lastUpdated,
        hasUnread: false,
      );
      notifyListeners();
    }
  }
}