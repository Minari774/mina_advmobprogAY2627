import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

enum LoginType { dummyJson, firebase }

class UserService extends ChangeNotifier {
  UserService({fb.FirebaseAuth? auth})
    : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;
  Map<String, dynamic> data = {};

  fb.User? get currentUser => _auth.currentUser;
  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') == 'firebase'
        ? LoginType.firebase
        : LoginType.dummyJson;
  }

  Future<void> _saveLoginType(LoginType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', type.name);
  }

  Future<Map<String, dynamic>> signIn({
    required String emailOrUsername,
    required String password,
    required LoginType loginType,
  }) async {
    if (loginType == LoginType.firebase) {
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailOrUsername.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw StateError('Firebase did not return a user.');
      final token = await user.getIdToken();
      final profile = await _readFirebaseProfile(user);
      data = {
        ...profile,
        'id': 0,
        'uid': user.uid,
        'email': user.email ?? emailOrUsername,
        'firstName': profile['firstName'] ?? '',
        'lastName': profile['lastName'] ?? '',
        'username': profile['username'] ?? user.displayName ?? '',
        'accessToken': token ?? '',
        'refreshToken': '',
      };
      await _saveChatProfile(user, data);
      await _saveLoginType(loginType);
      await _saveUserData(data);
      return data;
    }

    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': emailOrUsername.trim(),
        'password': password,
        'expiresInMins': 60,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(response));
    }
    data = jsonDecode(response.body) as Map<String, dynamic>;
    data['loginType'] = LoginType.dummyJson.name;
    await _saveLoginType(loginType);
    await _saveUserData(data);
    return data;
  }

  /// Sign in using either supported account type without asking the user to
  /// select a provider. Firebase accounts use email addresses; DummyJSON demo
  /// accounts use usernames.
  Future<Map<String, dynamic>> signInWithIdentity({
    required String identity,
    required String password,
  }) async {
    final value = identity.trim();
    if (!value.contains('@')) {
      return signIn(
        emailOrUsername: value,
        password: password,
        loginType: LoginType.dummyJson,
      );
    }

    try {
      return await signIn(
        emailOrUsername: value,
        password: password,
        loginType: LoginType.firebase,
      );
    } on fb.FirebaseAuthException catch (error) {
      // An email-shaped DummyJSON username is uncommon but valid. Let the
      // DummyJSON endpoint confirm or reject it when Firebase credentials fail.
      if (!{
        'user-not-found',
        'invalid-email',
        'invalid-credential',
        'wrong-password',
      }.contains(error.code)) {
        rethrow;
      }
      return signIn(
        emailOrUsername: value,
        password: password,
        loginType: LoginType.dummyJson,
      );
    }
  }

  // Backwards-compatible method used by the original DummyJSON sign-in flow.
  Future<Map<String, dynamic>> loginUser(String username, String password) =>
      signIn(
        emailOrUsername: username,
        password: password,
        loginType: LoginType.dummyJson,
      );

  Future<fb.UserCredential> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String emailAddress,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: emailAddress.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Firebase did not return a new user.');
    await user.updateDisplayName(username.trim());
    await user.reload();
    await _saveLoginType(LoginType.firebase);
    final profile = <String, dynamic>{
      'id': 0,
      'uid': user.uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'age': age,
      'contactNo': contactNo.trim(),
      'username': username.trim(),
      'email': emailAddress.trim(),
      'image': '',
      'gender': '',
    };
    await _saveFirebaseProfile(user.uid, profile);
    await _saveChatProfile(user, profile);
    final token = await _auth.currentUser?.getIdToken();
    await _saveUserData({...profile, 'accessToken': token ?? ''});
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'id',
      'username',
      'email',
      'firstName',
      'lastName',
      'gender',
      'image',
      'age',
      'contactNo',
      'accessToken',
      'refreshToken',
      'token',
      'loginType',
    ]) {
      await prefs.remove(key);
    }
    data = {};
    notifyListeners();
  }

  Future<void> logout() => signOut();

  Future<void> updateUsername({required String username}) async {
    final type = await getLoginType();
    if (type == LoginType.firebase) {
      final user = _requireFirebaseUser();
      await user.updateDisplayName(username.trim());
      await user.reload();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username.trim());
    if (type == LoginType.firebase) {
      final user = _requireFirebaseUser();
      final profile = await _readFirebaseProfile(user);
      profile['username'] = username.trim();
      await _saveFirebaseProfile(user.uid, profile);
      await _saveChatProfile(user, profile);
    }
    notifyListeners();
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    if (await getLoginType() != LoginType.firebase) {
      throw UnsupportedError('DummyJSON demo accounts cannot be deleted.');
    }
    final user = _requireFirebaseUser();
    final credential = fb.EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    await user.delete();
    await signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    if (await getLoginType() != LoginType.firebase) {
      throw UnsupportedError('DummyJSON does not support password changes.');
    }
    final user = _requireFirebaseUser();
    final credential = fb.EmailAuthProvider.credential(
      email: email.trim(),
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<Map<String, dynamic>> getUserData() async {
    if (await getLoginType() == LoginType.firebase) {
      final user = _auth.currentUser;
      if (user == null) return {};
      await user.reload();
      final refreshed = _auth.currentUser ?? user;
      final token = await refreshed.getIdToken();
      final profile = await _readFirebaseProfile(refreshed);
      final result = <String, dynamic>{
        ...profile,
        'id': 0,
        'uid': refreshed.uid,
        'email': refreshed.email ?? '',
        'username': profile['username'] ?? refreshed.displayName ?? '',
        'firstName': profile['firstName'] ?? '',
        'lastName': profile['lastName'] ?? '',
        'accessToken': token ?? '',
        'refreshToken': '',
      };
      await _saveUserData(result);
      return result;
    }
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'age': prefs.getInt('age'),
      'contactNo': prefs.getString('contactNo') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  Future<User> getUser() async => User.fromJson(await getUserData());

  Future<bool> isLoggedIn() async {
    if (await getLoginType() == LoginType.firebase) {
      return _auth.currentUser != null;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> _readFirebaseProfile(fb.User user) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('firebaseProfile_${user.uid}');
    if (raw == null) {
      return {
        'username': user.displayName ?? '',
        'firstName': '',
        'lastName': '',
        'image': user.photoURL ?? '',
      };
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveFirebaseProfile(
    String uid,
    Map<String, dynamic> profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebaseProfile_$uid', jsonEncode(profile));
  }

  /// Makes the signed-in Firebase profile available in the chat directory.
  /// Only display fields are stored in Firestore; age and contact details
  /// remain in the local profile cache.
  Future<void> syncCurrentFirebaseProfile() async {
    final user = _requireFirebaseUser();
    await _saveChatProfile(user, await _readFirebaseProfile(user));
  }

  Future<void> _saveChatProfile(
    fb.User user,
    Map<String, dynamic> profile,
  ) async {
    final email = user.email ?? profile['email']?.toString() ?? '';
    final username = profile['username']?.toString().trim() ?? '';
    final displayFallback = email.contains('@') ? email.split('@').first : '';
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': email,
      'username': username.isEmpty ? displayFallback : username,
      'firstName': profile['firstName']?.toString() ?? '',
      'lastName': profile['lastName']?.toString() ?? '',
      'image': profile['image']?.toString() ?? user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);
    if (userData['id'] is int) await prefs.setInt('id', userData['id'] as int);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    if (userData['age'] is int) {
      await prefs.setInt('age', userData['age'] as int);
    }
    if (userData['contactNo'] is String) {
      await prefs.setString('contactNo', userData['contactNo'] as String);
    }
    await prefs.setString(
      'accessToken',
      userData['accessToken']?.toString() ?? '',
    );
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString(
      'token',
      userData['token']?.toString() ?? user.accessToken,
    );
  }

  fb.User _requireFirebaseUser() =>
      _auth.currentUser ?? (throw StateError('No Firebase user is signed in.'));

  String _responseMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['message'] ?? body['error']?['message'] ?? response.body)
          .toString();
    } catch (_) {
      return response.body;
    }
  }
}
