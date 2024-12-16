import 'api_service.dart';

class Note {


  final int id; // Уникальный идентификатор квартиры
  final String title; // Название квартиры
  final String description; // Описание квартиры
  final String photo_id; // Ссылка на изображение
  final double price; // Цена квартиры
  bool isFavorite; // Флаг, является ли квартира избранной

  // Конструктор класса Note
  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.photo_id,
    required this.price,
    this.isFavorite = false, // По умолчанию квартира не является избранной
  });

  // Фабричный метод для создания объекта Note из JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      photo_id: json['image_link'] as String,
      price: (json['price'] as num).toDouble(),
      isFavorite: json['favourite'] as bool,
    );
  }

  // Фабричный метод для преобразования объекта CartItem в Note
  factory Note.fromCartItem(CartItem cartItem) {
    return Note(
      id: cartItem.apartmentId,
      title: cartItem.title,
      description: '',
      photo_id: cartItem.photoId ?? '',
      price: cartItem.price,
      isFavorite: false,
    );
  }


  // Метод для преобразования объекта Note в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_link': photo_id,
      'price': price,
      'favourite': isFavorite,
    };
  }
}
