import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _age = TextEditingController();
  final _contact = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    for (final controller in [_first, _last, _age, _contact, _username, _email, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await UserService().createAccount(
        firstName: _first.text,
        lastName: _last.text,
        age: int.parse(_age.text),
        contactNo: _contact.text,
        username: _username.text,
        emailAddress: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account creation failed: ${error.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
            children: [
              const Text('Create your account with Firebase Authentication.'),
              SizedBox(height: 18.h),
              _field(_first, 'First name', validator: _required, textCapitalization: TextCapitalization.words),
              _field(_last, 'Last name', validator: _required, textCapitalization: TextCapitalization.words),
              _field(
                _age,
                'Age',
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  return age == null || age < 13 || age > 120 ? 'Enter an age from 13 to 120' : null;
                },
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _field(
                _contact,
                'Contact number',
                validator: (value) => value == null || value.trim().length < 7 ? 'Enter a valid contact number' : null,
                keyboardType: TextInputType.phone,
              ),
              _field(_username, 'Username', validator: _required),
              _field(
                _email,
                'Email address',
                validator: (value) => value == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
                    ? 'Enter a valid email address'
                    : null,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _password,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least 8 characters, including a letter and a number',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (value) => value == null ||
                        value.length < 8 ||
                        !RegExp(r'[A-Za-z]').hasMatch(value) ||
                        !RegExp(r'\d').hasMatch(value)
                    ? 'Use 8+ characters with at least one letter and one number'
                    : null,
              ),
              SizedBox(height: 22.h),
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandNavy, foregroundColor: Colors.white),
                  onPressed: _loading ? null : _createAccount,
                  child: _loading
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) => Padding(
    padding: EdgeInsets.only(bottom: 14.h),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
    ),
  );
}
