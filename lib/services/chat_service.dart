// lib/services/chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

const _defaultChatModel  = String.fromEnvironment('OPENAI_CHAT_MODEL',  defaultValue: 'gpt-3.5-turbo');
const _defaultImageModel = String.fromEnvironment('OPENAI_IMAGE_MODEL', defaultValue: 'dall-e-3');

class ChatService {
  // 1) Use dart-define instead of dotenv:
  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  final http.Client _client;

  ChatService({http.Client? client})
      : _client = client ?? http.Client() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Missing OPENAI_API_KEY. '
        'Pass it via --dart-define, e.g. '
        'flutter run --dart-define=OPENAI_API_KEY=sk-xxx',
      );
    }
  }

  Uri get _chatEndpoint =>
      Uri.parse('https://api.openai.com/v1/chat/completions');

  Uri get _imageEndpoint =>
      Uri.parse('https://api.openai.com/v1/images/generations');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  Future<String> sendChat(String message) async {
    final res = await _client.post(
      _chatEndpoint,
      headers: _headers,
      body: jsonEncode({
        'model': _defaultChatModel,
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
      _chatEndpoint,
      headers: _headers,
      body: jsonEncode({
        'model': _defaultChatModel,
        'messages': [
          { 'role': 'system', 'content': "Interpret the user's dream." },
          { 'role': 'user',   'content': dream },
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
      _imageEndpoint,
      headers: _headers,
      body: jsonEncode({
        'model': _defaultImageModel, 
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
