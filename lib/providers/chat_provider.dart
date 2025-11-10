import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Message {
  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
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
      senderId: data['senderId'] ?? '',
      senderRole: data['senderRole'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class ChatRoom {
  final String id;
  final String studentId;
  final String? hwId;
  final String status;
  final String lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final int studentUnread;
  final int hwUnread;
  final String? subject;

  ChatRoom({
    required this.id,
    required this.studentId,
    this.hwId,
    required this.status,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    this.studentUnread = 0,
    this.hwUnread = 0,
    this.subject,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      hwId: data['hwId'],
      status: data['status'] ?? 'pending',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studentUnread: data['studentUnread'] ?? 0,
      hwUnread: data['hwUnread'] ?? 0,
      subject: data['subject'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'hwId': hwId,
      'status': status,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'studentUnread': studentUnread,
      'hwUnread': hwUnread,
      'subject': subject,
    };
  }
}

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Stream all chat rooms for a student
  Stream<List<ChatRoom>> streamStudentChatRooms() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('chatRooms')
        .where('studentId', isEqualTo: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromFirestore(doc))
            .toList());
  }

  // Stream all chat rooms for health workers (pending and assigned)
  Stream<List<ChatRoom>> streamHealthWorkerChatRooms() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection('chatRooms')
        .where('status', whereIn: ['pending', 'active'])
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromFirestore(doc))
            .toList());
  }

  // Stream messages for a specific chat room
  Stream<List<Message>> streamMessages(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }

  // Create a new chat room (student initiates)
  Future<String> startNewChat({String? subject}) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final chatRoom = ChatRoom(
      id: '', // Will be assigned by Firestore
      studentId: currentUserId!,
      status: 'pending',
      lastMessage: subject ?? 'New chat started',
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now(),
      subject: subject,
    );

    final docRef = await _firestore
        .collection('chatRooms')
        .add(chatRoom.toFirestore());

    return docRef.id;
  }

  // Send a message
  Future<void> sendMessage({
    required String roomId,
    required String text,
    required String senderRole,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    if (text.trim().isEmpty) return;

    final batch = _firestore.batch();

    // Add message to subcollection
    final messageRef = _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    final message = Message(
      id: messageRef.id,
      senderId: currentUserId!,
      senderRole: senderRole,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    batch.set(messageRef, message.toFirestore());

    // Update chat room with last message and unread count
    final roomRef = _firestore.collection('chatRooms').doc(roomId);
    final updateData = {
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    };

    // Increment unread count for the recipient
    if (senderRole == 'student') {
      updateData['hwUnread'] = FieldValue.increment(1);
      updateData['status'] = 'active'; // Activate if was pending
    } else {
      updateData['studentUnread'] = FieldValue.increment(1);
    }

    batch.update(roomRef, updateData);

    await batch.commit();
  }

  // Mark messages as read
  Future<void> markAsRead({
    required String roomId,
    required String userRole,
  }) async {
    if (currentUserId == null) return;

    final roomRef = _firestore.collection('chatRooms').doc(roomId);
    
    if (userRole == 'student') {
      await roomRef.update({'studentUnread': 0});
    } else {
      await roomRef.update({'hwUnread': 0});
    }
  }

  // Health worker claims a chat
  Future<void> claimChat(String roomId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _firestore.collection('chatRooms').doc(roomId).update({
      'hwId': currentUserId,
      'status': 'active',
    });
  }

  // Close a chat
  Future<void> closeChat(String roomId) async {
    await _firestore.collection('chatRooms').doc(roomId).update({
      'status': 'closed',
    });
  }

  // Get a single chat room
  Future<ChatRoom?> getChatRoom(String roomId) async {
    final doc = await _firestore.collection('chatRooms').doc(roomId).get();
    if (!doc.exists) return null;
    return ChatRoom.fromFirestore(doc);
  }
}
