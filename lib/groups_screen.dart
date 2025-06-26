import 'package:flutter/material.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: const Center(
        child: Text(
          'Groups screen coming soon!',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
