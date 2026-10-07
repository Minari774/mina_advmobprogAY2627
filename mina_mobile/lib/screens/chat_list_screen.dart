import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/chat_user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  final _chatService = ChatService();
  late final fb.User? _currentUser;
  Stream<List<ChatUser>>? _users;
  String _search = '';
  bool _syncingProfile = false;
  String? _profileSyncError;

  @override
  void initState() {
    super.initState();
    _currentUser = fb.FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _users = _chatService.getUsers();
      _syncCurrentProfile();
    }
  }

  Future<void> _syncCurrentProfile() async {
    setState(() => _syncingProfile = true);
    try {
      await UserService().syncCurrentFirebaseProfile();
    } catch (error) {
      if (mounted) setState(() => _profileSyncError = error.toString());
    } finally {
      if (mounted) setState(() => _syncingProfile = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chat is available for Firebase accounts. Sign in with your Firebase email to view and message users.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_profileSyncError != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Text(
                'Could not register your profile in the chat directory: $_profileSyncError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatUser>>(
              stream: _users,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _messageState(
                    'Could not load users. Check your connection and Firestore security rules.',
                    icon: Icons.cloud_off_outlined,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.where((user) {
                  if (_search.isEmpty) return true;
                  final searchable =
                      '${user.displayName} ${user.username} ${user.email}'
                          .toLowerCase();
                  return searchable.contains(_search);
                }).toList();
                if (users.isEmpty) {
                  return _messageState(
                    _search.isEmpty
                        ? 'No other users are registered yet.'
                        : 'No users match "${_searchController.text}".',
                    icon: _search.isEmpty
                        ? Icons.people_outline
                        : Icons.search_off,
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 20.h),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => SizedBox(height: 4.h),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 7.h,
                        ),
                        leading: _avatar(user),
                        title: Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatDetailScreen(
                              currentUser: _currentUser,
                              otherUser: user,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_syncingProfile) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

  Widget _avatar(ChatUser user) {
    final initials = user.displayName.trim().isEmpty
        ? '?'
        : user.displayName.trim().substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 25.r,
      backgroundImage: user.image.isEmpty ? null : NetworkImage(user.image),
      child: user.image.isEmpty ? Text(initials) : null,
    );
  }

  Widget _messageState(String message, {required IconData icon}) => Center(
    child: Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42.r, color: Colors.grey),
          SizedBox(height: 12.h),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
