import 'package:flutter/material.dart';
import 'screens/chat_bot_screen.dart';

class ChatSleeptScreen extends StatelessWidget {
  const ChatSleeptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('ChatSLEEPT')),
      body: ChatBotScreen(),
    );
  }
}
