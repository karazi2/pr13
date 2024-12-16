import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/api_service.dart';
import 'create_note_page.dart' as pages;
import '../pages/note_page.dart';

class HomePage extends StatefulWidget {
  final Function(Note) onToggleFavorite;
  final Function(Note) onAddNote;
  final Function(Note) onDeleteNote;
  final List<Note> cartItems;
  final Function(Note) onAddToCart;
  final Function(Note) onEditNote;

  const HomePage({
    Key? key,
    required this.onToggleFavorite,
    required this.onAddNote,
    required this.onDeleteNote,
    required this.cartItems,
    required this.onAddToCart,
    required this.onEditNote,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Note>> _notesFuture;
  List<Note> _allNotes = [];
  String _searchQuery = '';
  String _selectedFilter = 'Все'; // Фильтрация: студия, однокомнатная, двухкомнатная
  String _sortOrder = 'price_asc'; // Сортировка: price_asc, price_desc, title_asc, title_desc

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _notesFuture = ApiService().getApartments().then((notes) {
        _allNotes = notes; // Сохраняем данные для локальной обработки
        return _applyFiltersAndSorting();
      });
    });
  }
  void _editNoteHandler(Note updatedNote) {
    setState(() {
      // Найти индекс заметки
      final index = widget.cartItems.indexWhere((note) => note.id == updatedNote.id);
      if (index != -1) {
        // Обновить данные
        widget.cartItems[index] = updatedNote;
      }
    });
  }

  Future<List<Note>> _applyFiltersAndSorting() async {
    var filteredNotes = _allNotes;

    // Фильтрация по названию
    if (_selectedFilter != 'Все') {
      filteredNotes = filteredNotes
          .where((note) => note.title.toLowerCase().contains(_selectedFilter.toLowerCase()))
          .toList();
    }

    // Поиск по названию
    if (_searchQuery.isNotEmpty) {
      filteredNotes = filteredNotes
          .where((note) => note.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Сортировка
    if (_sortOrder == 'price_asc') {
      filteredNotes.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOrder == 'price_desc') {
      filteredNotes.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortOrder == 'title_asc') {
      filteredNotes.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortOrder == 'title_desc') {
      filteredNotes.sort((a, b) => b.title.compareTo(a.title));
    }

    return filteredNotes;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аренда Квартир'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotes,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      pages.CreateNotePage(onCreate: widget.onAddNote),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель управления: Поиск, фильтрация и сортировка
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Поиск
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Поиск по названию',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _notesFuture = Future.value(_applyFiltersAndSorting());
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Фильтрация и сортировка
                // Фильтрация и сортировка
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Элементы по краям
                  children: [
                    // Фильтрация
                    Expanded(
                      child: DropdownButtonHideUnderline( // Скрываем подчеркивание
                        child: DropdownButton<String>(
                          isExpanded: false, // Треугольник ближе к тексту
                          value: _selectedFilter,
                          onChanged: (value) {
                            setState(() {
                              _selectedFilter = value!;
                              _notesFuture = Future.value(_applyFiltersAndSorting());
                            });
                          },
                          items: ['Все', 'Студия', 'Однокомнатная', 'Двухкомнатная']
                              .map((filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          ))
                              .toList(),
                        ),
                      ),
                    ),

                    // Сортировка
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: false,
                          value: _sortOrder,
                          onChanged: (value) {
                            setState(() {
                              _sortOrder = value!;
                              _notesFuture = Future.value(_applyFiltersAndSorting());
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'price_asc', child: Text('Цена ↑')),
                            DropdownMenuItem(value: 'price_desc', child: Text('Цена ↓')),
                            DropdownMenuItem(value: 'title_asc', child: Text('А-Я')),
                            DropdownMenuItem(value: 'title_desc', child: Text('Я-А')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),

          // Список квартир
          Expanded(
            child: FutureBuilder<List<Note>>(
              future: _notesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Ошибка загрузки данных: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Нет доступных квартир'));
                } else {
                  final notes = snapshot.data!;
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.6,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    padding: const EdgeInsets.all(10),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotePage(
                                noteId: note.id,
                                onEdit: _editNoteHandler,
                                onDelete: (deletedNoteId) {
                                  setState(() {
                                    notes.removeWhere((note) => note.id == deletedNoteId);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (note.photo_id.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    note.photo_id,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text('Ошибка загрузки изображения'),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  note.title,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '₽${note.price.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  note.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      note.isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: note.isFavorite ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () async {
                                      try {
                                        await ApiService().toggleFavourite(note.id);
                                        setState(() {
                                          note.isFavorite = !note.isFavorite;
                                          widget.onToggleFavorite(note);
                                        });
                                      } catch (e) {
                                        print('Ошибка изменения избранного: $e');
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_shopping_cart),
                                    onPressed: () {
                                      widget.onAddToCart(note);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
