// lib/services/chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  ChatService({http.Client? client})
      : _client = client ?? http.Client(),
        _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  final http.Client _client;
  final String _apiKey;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  Future<String> sendChat(String message) async {
    final res = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: _headers,
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': message}
        ],
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['choices'][0]['message']['content'] as String;
    }
    throw Exception('Chat failed: ${res.statusCode} ${res.body}');
  }

  Future<String> interpretDream(String dream) async {
    final res = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: _headers,
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': "Interpret the user's dream."
          },
          {'role': 'user', 'content': dream}
        ],
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['choices'][0]['message']['content'] as String;
    }
    throw Exception('Interpret failed: ${res.statusCode} ${res.body}');
  }

  Future<String> generateImage(String dream) async {
    final res = await _client.post(
      Uri.parse('https://api.openai.com/v1/images/generations'),
      headers: _headers,
      body: jsonEncode({
        'prompt': dream,
        'n': 1,
        'size': '512x512',
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['data'][0]['url'] as String;
    }
    throw Exception('Image gen failed: ${res.statusCode} ${res.body}');
  }
}
