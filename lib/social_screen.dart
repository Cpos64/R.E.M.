import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'profile_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _service = FirestoreService();
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _openProfile(String uid, String email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(uid: uid, email: email),
      ),
    );
  }

  Future<void> _commentDialog(String dreamId) async {
    final ctl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(controller: ctl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) {
      await _service.addComment(dreamId, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchCtl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search friends by email',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.searchUsers(_searchCtl.text),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox();
                }
                final docs = snap.data!.docs;
                return ListView(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['email'] ?? ''),
                      onTap: () => _openProfile(d.id, data['email'] ?? ''),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.sharedDreamsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No shared dreams'));
                }
                return ListView(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final likes = List<String>.from(data['likes'] ?? []);
                    final liked = likes.contains(FirebaseAuth.instance.currentUser?.uid);
                    return ListTile(
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(data['description'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                            onPressed: () => _service.toggleLike(d.id),
                          ),
                          Text('${likes.length}'),
                          IconButton(
                            icon: const Icon(Icons.comment),
                            onPressed: () => _commentDialog(d.id),
                          ),
                        ],
                      ),
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
