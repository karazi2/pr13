import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/api_service.dart';


class EditNotePage extends StatefulWidget {
  final Note note;
  final Function(Note) onSave;

  const EditNotePage({
    Key? key,
    required this.note,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageLinkController; // Новый контроллер для ссылки на картинку

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _descriptionController = TextEditingController(text: widget.note.description);
    _priceController = TextEditingController(text: widget.note.price.toString());
    _imageLinkController = TextEditingController(text: widget.note.photo_id); // Инициализация с текущей ссылкой
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageLinkController.dispose(); // Освобождаем ресурс
    super.dispose();
  }


  void _saveNote() async {
    final updatedNote = Note(
      id: widget.note.id,
      title: _titleController.text,
      description: _descriptionController.text,
      photo_id: _imageLinkController.text,
      price: double.tryParse(_priceController.text) ?? widget.note.price,
      isFavorite: widget.note.isFavorite,
    );

    try {
      await ApiService().updateApartment(updatedNote); // Отправка на сервер
      widget.onSave(updatedNote); // Локальное обновление
      Navigator.of(context).pop(); // Закрытие экрана
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote, // Сохраняем изменения
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 3,
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Цена'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _imageLinkController, // Поле для ссылки на изображение
                decoration: const InputDecoration(labelText: 'Ссылка на картинку'),
              ),
              const SizedBox(height: 16.0),
              if (_imageLinkController.text.isNotEmpty) // Показываем превью изображения
                Image.network(
                  _imageLinkController.text,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Ошибка загрузки изображения');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
