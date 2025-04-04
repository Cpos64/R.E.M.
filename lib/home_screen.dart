import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home - R.E.M.'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to R.E.M!'),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/dreams');
              },
              child: Text('Go to Dream Journal'),
            ),
          ],
        ),
      ),
    ); // ✅ Closing parenthesis for Scaffold was missing
  }
}
