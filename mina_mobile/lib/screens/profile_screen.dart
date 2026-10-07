import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = UserService();
  Map<String, dynamic>? _profile;
  LoginType? _loginType;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final values = await _service.getUserData();
      final type = await _service.getLoginType();
      if (!mounted) return;
      setState(() {
        _profile = values;
        _loginType = type;
        _loadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
      _message('Could not load profile: $error');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Do you want to log out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _service.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  Future<String?> _prompt(String title, {bool obscure = false}) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _TextPromptDialog(
        title: title,
        obscure: obscure,
      ),
    );
  }

  Future<void> _updateUsername() async {
    final name = await _prompt('New username');
    if (name == null || name.trim().isEmpty) return;
    try {
      await _service.updateUsername(username: name);
      if (!mounted) return;
      setState(() {
        _profile = {...?_profile, 'username': name.trim()};
      });
      _message('Username updated.');
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _changePassword(String email) async {
    final current = await _prompt('Current password', obscure: true);
    if (current == null || current.isEmpty || !mounted) return;
    final next = await _prompt('New password (8+ characters)', obscure: true);
    if (next == null || next.length < 8) return;
    try {
      await _service.resetPasswordFromCurrentPassword(
        currentPassword: current,
        newPassword: next,
        email: email,
      );
      if (mounted) _message('Password updated.');
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _deleteAccount(String email) async {
    final password = await _prompt('Confirm password to delete account', obscure: true);
    if (password == null || password.isEmpty) return;
    try {
      await _service.deleteAccount(email: email, password: password);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) return const Center(child: CircularProgressIndicator());
    final user = User.fromJson(_profile ?? {});
    if (user.username.isEmpty && user.email.isEmpty) {
      return const Center(child: Text('Not signed in.'));
    }
    final firebase = _loginType == LoginType.firebase;
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 18.w),
                      child: Column(
                        children: [
                          CircleAvatar(radius: 42.r, child: const Icon(Icons.person, size: 44)),
                          SizedBox(height: 12.h),
                          Text('${user.firstName} ${user.lastName}'.trim().isEmpty ? user.username : '${user.firstName} ${user.lastName}'.trim(), style: Theme.of(context).textTheme.titleLarge),
                          Text('@${user.username}', style: TextStyle(color: Colors.amber.shade800)),
                          SizedBox(height: 6.h),
                          Chip(label: Text(firebase ? 'Firebase Authentication' : 'DummyJSON demo')),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        _row('Email', user.email),
                        _row('Age', user.age?.toString() ?? 'Not provided'),
                        _row('Contact', user.contactNo.isEmpty ? 'Not provided' : user.contactNo),
                        _row('User ID', user.uid.isNotEmpty ? user.uid : '${user.id}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ListTile(leading: const Icon(Icons.alternate_email), title: const Text('Update username'), trailing: const Icon(Icons.chevron_right), onTap: _updateUsername),
                  if (firebase) ...[
                    ListTile(leading: const Icon(Icons.password), title: const Text('Change password'), trailing: const Icon(Icons.chevron_right), onTap: () => _changePassword(user.email)),
                    ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('Delete account'), trailing: const Icon(Icons.chevron_right), onTap: () => _deleteAccount(user.email)),
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text('DummyJSON demo accounts do not support persistent password changes or account deletion.'),
                    ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out'),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => ListTile(
    dense: true,
    title: Text(label),
    trailing: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 190), child: Text(value, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({required this.title, this.obscure = false});

  final String title;
  final bool obscure;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      obscureText: widget.obscure,
      decoration: InputDecoration(labelText: widget.title),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Continue')),
    ],
  );
}
