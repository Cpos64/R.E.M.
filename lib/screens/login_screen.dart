import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('password', _passwordController.text.trim());
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

Future<void> _submit() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  print('➡️ Attempting ${_isLogin ? 'sign-in' : 'sign-up'} with $email');

  try {
    // we declare this here so both branches can assign to it
    late final UserCredential cred;

    if (_isLogin) {
      cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      print('✅ Sign-in succeeded! UID=${cred.user?.uid}');
    } else {
      cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      print('✅ Account creation succeeded! UID=${cred.user?.uid}');
    }

    // on success, save creds if “remember me” was checked
    await _saveCredentials();
    // your StreamBuilder in main.dart will automatically navigate on auth change
  } on TimeoutException {
    print('⚠️ Authentication timed out after 15s');
    setState(() => _error = 'Connection timed out. Please try again.');
  } on FirebaseAuthException catch (e) {
    print('❌ FirebaseAuthException: code=${e.code}, msg=${e.message}');
    setState(() => _error = e.message);
  } catch (e) {
    print('❌ Unknown error: $e');
    setState(() => _error = 'Something went wrong');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 10),
            ],
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
  controller: _passwordController,
  decoration: InputDecoration(labelText: 'Password'),
  obscureText: true,
),
SizedBox(height: 10),

CheckboxListTile(
  title: Text('Remember Me'),
  value: _rememberMe,
  onChanged: (value) {
    setState(() {
      _rememberMe = value ?? false;
    });
  },
),

SizedBox(height: 10),
_isLoading
    ? CircularProgressIndicator()
    : ElevatedButton(
        onPressed: _submit,
        child: Text(_isLogin ? 'Login' : 'Sign Up'),
      ),

            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                });
              },
              child: Text(_isLogin ? 'Create new account' : 'Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
