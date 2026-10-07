import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/chat_user.dart';
import '../models/message.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore, fb.FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? fb.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  String get currentUid =>
      _auth.currentUser?.uid ??
      (throw StateError('Chat requires a Firebase-authenticated account.'));

  Stream<List<ChatUser>> getUsers() {
    final uid = currentUid;
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .where((document) => document.id != uid)
          .map(ChatUser.fromDocument)
          .toList();
      users.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return users;
    });
  }

  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final uid = currentUid;
    _ensureDifferentUsers(uid, otherUserId);
    final roomId = _roomId(uid, otherUserId);
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(MessageModel.fromDocument).toList(),
        );
  }

  Stream<List<MessageModel>> watchMessages(String otherUserId) async* {
    await ensureRoom(otherUserId);
    yield* getMessages(otherUserId);
  }

  Future<void> ensureRoom(String otherUserId) async {
    final uid = currentUid;
    _ensureDifferentUsers(uid, otherUserId);
    final participants = [uid, otherUserId]..sort();
    await _firestore
        .collection('chat_rooms')
        .doc(_roomId(participants[0], participants[1]))
        .set({'participants': participants}, SetOptions(merge: true));
  }

  Future<String> sendMessage({
    required ChatUser recipient,
    required String message,
  }) async {
    final sender = _auth.currentUser;
    if (sender == null) {
      throw StateError('Chat requires a Firebase-authenticated account.');
    }
    _ensureDifferentUsers(sender.uid, recipient.id);

    final roomId = _roomId(sender.uid, recipient.id);
    final participants = [sender.uid, recipient.id]..sort();
    final room = _firestore.collection('chat_rooms').doc(roomId);
    await room.set({
      'participants': participants,
      'lastMessage': message,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final document = await room.collection('messages').add({
      'senderId': sender.uid,
      'senderEmail': sender.email ?? '',
      'receiverId': recipient.id,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
    return document.id;
  }

  Future<void> updateMessageStatus({
    required String otherUserId,
    required String messageId,
    required String status,
  }) async {
    if (status != 'delivered' && status != 'seen') {
      throw ArgumentError.value(status, 'status');
    }
    await _firestore
        .collection('chat_rooms')
        .doc(_roomId(currentUid, otherUserId))
        .collection('messages')
        .doc(messageId)
        .update({'status': status});
  }

  String _roomId(String first, String second) {
    final ids = [first, second]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  void _ensureDifferentUsers(String currentUserId, String otherUserId) {
    if (currentUserId == otherUserId) {
      throw ArgumentError('You cannot start a chat with yourself.');
    }
  }
}
