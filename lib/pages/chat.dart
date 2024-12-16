import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/api_service.dart';

class ChatPage extends StatefulWidget {
  final String sellerId;

  const ChatPage({Key? key, required this.sellerId}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  String? _chatId; // ID чата
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: пользователь не авторизован')),
      );
      return;
    }

    try {
      // Создаем или находим чат
      final chatId = await _apiService.createChat([user.id, widget.sellerId]);
      print("Создан chatId: $chatId"); // Логирование chatId
      setState(() {
        _chatId = chatId;
      });

      // Загружаем сообщения
      _loadMessages();
    } catch (e) {
      print('Ошибка инициализации чата: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_chatId == null) {
      print("chatId не найден, загрузка сообщений невозможна.");
      return;
    }

    try {
      final messages = await _apiService.getMessages(_chatId!);
      print("Загружены сообщения: $messages"); // Логирование сообщений
      setState(() {
        _messages = messages;
      });
    } catch (e) {
      print('Ошибка загрузки сообщений: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_chatId == null || _messageController.text.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await _apiService.sendMessage(
        _chatId!,
        user.id,
        _messageController.text.trim(),
      );

      _messageController.clear();
      _loadMessages(); // Обновляем сообщения после отправки
    } catch (e) {
      print('Ошибка отправки сообщения: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Чат с продавцом')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['sender_id'] ==
                    Supabase.instance.client.auth.currentUser?.id;

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      message['message'],
                      style: TextStyle(
                          color: isMe ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                    const InputDecoration(hintText: 'Напишите сообщение...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
