// lib/services/chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  ChatService({ required this.baseUrl });
  final String baseUrl;

  Future<String> sendChat(String message) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type':'application/json'},
      body: jsonEncode({'message': message}),
    );
    if (res.statusCode==200) {
      return jsonDecode(res.body)['answer'] as String;
    }
    throw Exception('Chat failed: ${res.statusCode} ${res.body}');
  }

  Future<String> interpretDream(String dream) async {
    final res = await http.post(
      Uri.parse('$baseUrl/interpret'),
      headers: {'Content-Type':'application/json'},
      body: jsonEncode({'dream': dream}),
    );
    if (res.statusCode==200) {
      return jsonDecode(res.body)['interpretation'] as String;
    }
    throw Exception('Interpret failed: ${res.statusCode} ${res.body}');
  }

  Future<String> generateImage(String dream) async {
    final res = await http.post(
      Uri.parse('$baseUrl/dream-image'),
      headers: {'Content-Type':'application/json'},
      body: jsonEncode({'dream': dream}),
    );
    if (res.statusCode==200) {
      return jsonDecode(res.body)['url'] as String;
    }
    throw Exception('Image gen failed: ${res.statusCode} ${res.body}');
  }
}
