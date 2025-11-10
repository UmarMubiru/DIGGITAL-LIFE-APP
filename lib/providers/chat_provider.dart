import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Models
class ChatRoom {
  final String id;
  final String studentId;
  final String? hwId;
  final String? subject;
  final String status; // 'pending', 'active', 'closed'
  final String lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final int studentUnread;
  final int hwUnread;

  ChatRoom({
    required this.id,
    required this.studentId,
    this.hwId,
    this.subject,
    required this.status,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    required this.studentUnread,
    required this.hwUnread,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      hwId: data['hwId'],
      subject: data['subject'],
      status: data['status'] ?? 'pending',
      lastMessage: data['lastMessage'] ?? 'No messages yet',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studentUnread: data['studentUnread'] ?? 0,
      hwUnread: data['hwUnread'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'hwId': hwId,
      'subject': subject,
      'status': status,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'studentUnread': studentUnread,
      'hwUnread': hwUnread,
    };
  }
}

class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String senderRole; // 'student' or 'health_worker'
  final String text;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderRole: data['senderRole'] ?? 'student',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user ID
  String get _userId => _auth.currentUser?.uid ?? '';

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Create a new chat room (student initiates)
  Future<String> startNewChat({String? subject}) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final chatRoom = ChatRoom(
        id: '', // Will be set by Firestore
        studentId: _userId,
        hwId: null, // No health worker assigned yet
        subject: subject,
        status: 'pending',
        lastMessage: subject ?? 'New chat request',
        lastMessageAt: DateTime.now(),
        createdAt: DateTime.now(),
        studentUnread: 0,
        hwUnread: 0,
      );

      final docRef = await _firestore.collection('chatRooms').add(chatRoom.toFirestore());
      
      // Send initial message if subject provided
      if (subject != null && subject.isNotEmpty) {
        await sendMessage(
          roomId: docRef.id,
          text: subject,
          senderRole: 'student',
        );
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error starting new chat: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String roomId,
    required String text,
    required String senderRole,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    if (text.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    try {
      final message = Message(
        id: '', // Will be set by Firestore
        roomId: roomId,
        senderId: _userId,
        senderRole: senderRole,
        text: text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Add message to messages subcollection
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .add(message.toFirestore());

      // Update chat room with last message and increment unread count
      final updateData = {
        'lastMessage': text.trim(),
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
      };

      // Increment unread count for the recipient
      if (senderRole == 'student') {
        updateData['hwUnread'] = FieldValue.increment(1);
      } else {
        updateData['studentUnread'] = FieldValue.increment(1);
      }

      await _firestore.collection('chatRooms').doc(roomId).update(updateData);

      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Stream chat rooms for student
  Stream<List<ChatRoom>> streamStudentChatRooms() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chatRooms')
        .where('studentId', isEqualTo: _userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    });
  }

  // Stream chat rooms for health worker
  Stream<List<ChatRoom>> streamHealthWorkerChatRooms() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chatRooms')
        .where('status', whereIn: ['pending', 'active'])
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    });
  }

  // Stream messages for a chat room
  Stream<List<Message>> streamMessages(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  // Get a single chat room
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final doc = await _firestore.collection('chatRooms').doc(roomId).get();
      if (doc.exists) {
        return ChatRoom.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting chat room: $e');
      return null;
    }
  }

  // Mark messages as read
  Future<void> markAsRead({
    required String roomId,
    required String userRole,
  }) async {
    if (!isAuthenticated) return;

    try {
      final updateData = <String, dynamic>{};
      
      if (userRole == 'student') {
        updateData['studentUnread'] = 0;
      } else {
        updateData['hwUnread'] = 0;
      }

      await _firestore.collection('chatRooms').doc(roomId).update(updateData);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // Health worker accepts a chat
  Future<void> acceptChat(String roomId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection('chatRooms').doc(roomId).update({
        'hwId': _userId,
        'status': 'active',
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error accepting chat: $e');
      rethrow;
    }
  }

  // Close a chat
  Future<void> closeChat(String roomId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection('chatRooms').doc(roomId).update({
        'status': 'closed',
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error closing chat: $e');
      rethrow;
    }
  }

  // Delete a chat room (health worker only)
  Future<void> deleteChat(String roomId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      // Delete all messages first
      final messagesSnapshot = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat room
      batch.delete(_firestore.collection('chatRooms').doc(roomId));

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  // Get unread count for student
  Stream<int> streamStudentUnreadCount() {
    if (!isAuthenticated) {
      return Stream.value(0);
    }

    return _firestore
        .collection('chatRooms')
        .where('studentId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['studentUnread'] ?? 0) as int;
      }
      return total;
    });
  }

  // Get unread count for health worker
  Stream<int> streamHealthWorkerUnreadCount() {
    if (!isAuthenticated) {
      return Stream.value(0);
    }

    return _firestore
        .collection('chatRooms')
        .where('status', whereIn: ['pending', 'active'])
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['hwUnread'] ?? 0) as int;
      }
      return total;
    });
  }
}
