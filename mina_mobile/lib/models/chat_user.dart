import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  const ChatUser({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.image,
  });

  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String image;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    if (username.isNotEmpty) return username;
    return email.isNotEmpty ? email : 'User';
  }

  factory ChatUser.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return ChatUser(
      id: document.id,
      email: data['email']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      firstName: data['firstName']?.toString() ?? '',
      lastName: data['lastName']?.toString() ?? '',
      image: data['image']?.toString() ?? '',
    );
  }
}
