import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/api_service.dart';

class CreateNotePage extends StatefulWidget {
  final Function(Note) onCreate;

  const CreateNotePage({Key? key, required this.onCreate}) : super(key: key);

  @override
  _CreateNotePageState createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isLoading = false;

  void _saveNote() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _urlController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Цена должна быть числом')),
      );
      return;
    }

    final urlPattern = r'^(http|https):\/\/';
    if (!RegExp(urlPattern).hasMatch(_urlController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите действительный URL изображения')),
      );
      return;
    }

    final newNote = Note(
      id: 0, // ID будет генерироваться на сервере
      title: _titleController.text,
      description: _descriptionController.text,
      photo_id: _urlController.text,
      price: price,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService().createApartment(newNote); // Отправляем данные на сервер
      widget.onCreate(newNote); // Обновляем список в родительском виджете
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Квартира успешно добавлена')),
      );
    } catch (e) {
      print('Ошибка добавления квартиры: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка добавления квартиры')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать квартиру'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Заголовок'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL изображения'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Цена'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveNote,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Сохранить квартиру'),
            ),
          ],
        ),
      ),
    );
  }
}
