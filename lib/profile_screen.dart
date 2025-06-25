import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final String email;
  const ProfileScreen({super.key, required this.uid, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = FirestoreService();
  int _dreamCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await _service.dreamCountForUser(widget.uid);
    setState(() => _dreamCount = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.email)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Dreams logged: $_dreamCount'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.sharedDreamsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs
                    .where((d) => d['userId'] == widget.uid)
                    .toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('No shared dreams'));
                }
                return ListView(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final likes = (data['likes'] as List?)?.length ?? 0;
                    return ListTile(
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(data['description'] ?? ''),
                      trailing: Text('Likes: $likes'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
