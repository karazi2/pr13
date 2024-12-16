import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/api_service.dart';
import 'edit_note_page.dart';

class NotePage extends StatefulWidget {
  final int noteId;
  final Function(Note) onEdit;
  final Function(int) onDelete; // Функция для удаления

  const NotePage({
    Key? key,
    required this.noteId,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late Future<Note> _noteFuture;
  Note? _note;

  @override
  void initState() {
    super.initState();
    _noteFuture = _loadNote();
  }

  Future<Note> _loadNote() async {
    final note = await ApiService().getApartmentById(widget.noteId);
    setState(() {
      _note = note;
    });
    return note;
  }

  Future<void> _deleteNote() async {
    try {
      await ApiService().deleteApartment(widget.noteId); // Запрос на сервер
      widget.onDelete(widget.noteId); // Уведомляем родительский виджет
      Navigator.of(context).pop(); // Возвращаемся на предыдущий экран
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Квартира успешно удалена')),
      );
    } catch (e) {
      print('Ошибка удаления квартиры: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка удаления квартиры')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали квартиры'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _note != null
                ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditNotePage(
                    note: _note!,
                    onSave: (updatedNote) {
                      widget.onEdit(updatedNote);
                      setState(() {
                        _noteFuture = _loadNote();
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить квартиру'),
                  content: const Text('Вы уверены, что хотите удалить эту квартиру?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _deleteNote();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Note>(
        future: _noteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка загрузки данных: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Квартира не найдена'));
          } else {
            return _buildNoteDetails(snapshot.data!);
          }
        },
      ),
    );
  }

  Widget _buildNoteDetails(Note note) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.photo_id.isNotEmpty)
            Image.network(
              note.photo_id,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Text('Ошибка загрузки изображения');
              },
            ),
          const SizedBox(height: 16.0),
          Text(
            note.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Цена: ₽${note.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          Text(
            note.description,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
