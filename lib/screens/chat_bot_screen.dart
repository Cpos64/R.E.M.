// lib/screens/chat_bot_screen.dart

import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);
  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final _chatService = ChatService();
  final _controller = TextEditingController();
  final List<_Message> _messages = [];
  bool _loading = false;
  int _mode = 0; // 0=chat, 1=interpret, 2=image

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text, isUser: true, isImage: false));
      _loading = true;
    });
    _controller.clear();

    try {
      String reply;
      if (_mode == 0) {
        reply = await _chatService.sendChat(text);
        setState(() => _messages.add(_Message(reply, isUser: false, isImage: false)));
      } else if (_mode == 1) {
        reply = await _chatService.interpretDream(text);
        setState(() => _messages.add(_Message(reply, isUser: false, isImage: false)));
      } else {
        final url = await _chatService.generateImage(text);
        setState(() => _messages.add(_Message(url, isUser: false, isImage: true)));
      }
    } catch (e) {
      setState(() => _messages.add(_Message('Error: $e', isUser: false, isImage: false)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Mode selector ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ToggleButtons(
            isSelected: [_mode==0, _mode==1, _mode==2],
            onPressed: (i) => setState(() => _mode = i),
            children: const [
              Padding(padding: EdgeInsets.all(8), child: Text('Chat')),
              Padding(padding: EdgeInsets.all(8), child: Text('Interpret')),
              Padding(padding: EdgeInsets.all(8), child: Text('Image')),
            ],
          ),
        ),

        // ── Message list ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _messages.length,
            itemBuilder: (_, idx) {
              final m = _messages[idx];
              if (m.isImage) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.network(m.text),
                );
              }
              return Align(
                alignment:
                  m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical:4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: m.isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(
                      color: m.isUser ? Colors.white : null
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_loading) const LinearProgressIndicator(),

        // ── Input bar ──
        SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: _mode==2
                      ? 'Describe the dream to illustrate…'
                      : 'Type your message…'
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _handleSend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Simple message holder
class _Message {
  final String text;
  final bool isUser;
  final bool isImage;
  _Message(this.text, {required this.isUser, required this.isImage});
}
