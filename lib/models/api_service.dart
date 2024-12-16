import 'package:dio/dio.dart';
import 'note.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.0.22:8080'));

  // Получение всех квартир
  Future<List<Note>> getApartments() async {
    try {
      final response = await _dio.get('/apartments');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((apartment) => Note.fromJson(apartment))
            .toList();
      } else {
        throw Exception('Не удалось загрузить квартиры');
      }
    } catch (e) {
      throw Exception('Ошибка получения списка квартир: $e');
    }
  }

  Future<String> createChat(List<String> participants) async {
    try {
      print("Создание чата для участников: $participants"); // Логируем участников

      final response = await _dio.post('/chats', data: {'participants': participants});

      print("Ответ от сервера: ${response.statusCode}"); // Логируем статус ответа

      if (response.statusCode == 200) {
        print("Чат успешно создан, chat_id: ${response.data['chat_id']}"); // Логируем chat_id
        return response.data['chat_id'];
      } else {
        throw Exception('Ошибка создания чата');
      }
    } catch (e) {
      print("Ошибка при создании чата: $e"); // Логируем ошибку
      throw Exception('Ошибка: $e');
    }
  }


  // Синхронизация чатов с API
  Future<void> syncChatsFromAPI() async {
    try {
      final response = await _dio.get('/chats');
      if (response.statusCode == 200) {
        final chats = response.data as List;
        for (var chat in chats) {
          print('Синхронизирован чат: ${chat['id']}');
        }
      } else {
        throw Exception('Ошибка загрузки чатов');
      }
    } catch (e) {
      print('Ошибка синхронизации чатов: $e');
    }
  }

  Future<void> syncMessagesFromAPI(String chatId) async {
    try {
      print("Синхронизируем сообщения для chatId: $chatId"); // Логируем chatId

      final response = await _dio.get('/messages/$chatId');
      print("Ответ от сервера: ${response.statusCode}");

      if (response.statusCode == 200) {
        final messages = response.data as List;
        print("Количество сообщений для chatId: $chatId: ${messages.length}"); // Логируем количество сообщений
        for (var message in messages) {
          print('Сообщение синхронизировано: ${message['id']}');
        }
      } else {
        print("Ошибка получения сообщений: ${response.statusCode}");
        throw Exception('Ошибка загрузки сообщений');
      }
    } catch (e) {
      print("Ошибка синхронизации сообщений: $e");
    }
  }


  // Отправка сообщения
  Future<void> sendMessage(String chatId, String senderId, String message) async {
    try {
      print("Отправка сообщения: chatId=$chatId, senderId=$senderId, message=$message");

      final response = await _dio.post('/messages', data: {
        'chat_id': chatId,
        'sender_id': senderId,
        'message': message,
      });

      print("Ответ от сервера: ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception('Ошибка отправки сообщения');
      } else {
        print("Сообщение отправлено успешно");
      }
    } catch (e) {
      print("Ошибка отправки сообщения: $e");
      throw Exception('Ошибка: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      print("Загружаем сообщения для chatId: $chatId"); // Логируем перед отправкой запроса

      // Отправляем запрос на сервер
      final response = await _dio.get('/messages/$chatId');

      // Логируем статус ответа
      print("Статус ответа от сервера: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Логируем данные, полученные от сервера
        print("Ответ от сервера: ${response.data}");

        // Проверяем, что данные не пустые
        if (response.data != null && response.data.isNotEmpty) {
          // Преобразуем ответ в список сообщений
          return List<Map<String, dynamic>>.from(response.data);
        } else {
          print("Ответ от сервера пустой для chatId: $chatId");
          throw Exception('Сообщения не найдены');
        }
      } else {
        print("Ошибка от сервера: Статус ${response.statusCode}"); // Логируем ошибку сервера
        throw Exception('Ошибка получения сообщений');
      }
    } catch (e) {
      print("Ошибка при загрузке сообщений: $e"); // Логируем ошибку
      throw Exception('Ошибка: $e');
    }
  }



  // Получение данных квартиры по ID
  Future<Note> getApartmentById(int id) async {
    try {
      final response = await _dio.get('/apartments/$id');
      if (response.statusCode == 200) {
        return Note.fromJson(response.data);
      } else {
        throw Exception('Не удалось получить данные квартиры');
      }
    } catch (e) {
      throw Exception('Ошибка получения данных квартиры: $e');
    }
  }

  // Удаление квартиры
  Future<void> deleteApartment(int apartmentId) async {
    try {
      final response = await _dio.delete('/apartments/delete/$apartmentId');
      if (response.statusCode != 204) {
        throw Exception('Ошибка удаления квартиры');
      }
    } catch (e) {
      throw Exception('Ошибка удаления: $e');
    }
  }

  // Получение списка заказов
  Future<List<dynamic>> getOrders(String userId) async {
    try {
      final response = await _dio.get('/orders/$userId');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Ошибка загрузки заказов');
      }
    } catch (e) {
      throw Exception('Ошибка: $e');
    }
  }

  // Создание квартиры
  Future<void> createApartment(Note note) async {
    try {
      final data = {
        "title": note.title,
        "description": note.description,
        "image_link": note.photo_id,
        "price": note.price,
      };
      final response = await _dio.post('/apartments/create', data: data);
      if (response.statusCode != 200) {
        throw Exception('Ошибка создания квартиры');
      }
    } catch (e) {
      throw Exception('Ошибка создания квартиры: $e');
    }
  }

  // Обновление информации о квартире
  Future<void> updateApartment(Note note) async {
    final data = {
      "ID": note.id,
      "Title": note.title,
      "Description": note.description,
      "ImageLink": note.photo_id,
      "Price": note.price,
    };
    try {
      final response = await _dio.put('/apartments/update/${note.id}', data: data);
      if (response.statusCode != 200) {
        throw Exception('Ошибка обновления информации о квартире');
      }
    } catch (e) {
      throw Exception('Ошибка обновления квартиры: $e');
    }
  }

  // Переключение статуса "Избранное"
  Future<void> toggleFavourite(int id) async {
    try {
      final response = await _dio.put('/apartments/favourite/$id');
      if (response.statusCode != 200) {
        throw Exception('Ошибка обновления статуса "Избранное"');
      }
    } catch (e) {
      throw Exception('Ошибка: $e');
    }
  }

  // Получение корзины пользователя
  Future<List<CartItem>> getCart(String userId) async {
    try {
      final response = await _dio.get('/cart/$userId');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((cartItem) => CartItem.fromJson(cartItem))
            .toList();
      } else {
        throw Exception('Ошибка загрузки корзины');
      }
    } catch (e) {
      throw Exception('Ошибка: $e');
    }
  }

  // Добавление элемента в корзину
  Future<void> addToCart(String userId, int apartmentId) async {
    final data = {
      "user_id": userId,
      "apartment_id": apartmentId,
      "quantity": 1,
    };
    try {
      final response = await _dio.post('/cart', data: data);
      if (response.statusCode != 200) {
        throw Exception('Ошибка добавления в корзину');
      }
    } catch (e) {
      throw Exception('Ошибка добавления в корзину: $e');
    }
  }

  // Удаление элемента из корзины
  Future<void> removeFromCart(String userId, int apartmentId) async {
    try {
      final response = await _dio.delete('/cart/$userId/$apartmentId');
      if (response.statusCode != 200) {
        throw Exception('Ошибка удаления из корзины');
      }
    } catch (e) {
      throw Exception('Ошибка удаления: $e');
    }
  }

  // Создание заказа
  Future<void> createOrder(String userId, List<CartItem> items) async {
    final data = {
      "user_id": userId,
      "items": items.map((item) => item.toJson()).toList(),
    };
    try {
      final response = await _dio.post('/orders', data: data);
      if (response.statusCode != 200) {
        throw Exception('Ошибка создания заказа');
      }
    } catch (e) {
      throw Exception('Ошибка создания заказа: $e');
    }
  }
}

// Класс CartItem
class CartItem {
  final int id;
  final int apartmentId;
  final String userId;
  final String title;
  final String? photoId;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.apartmentId,
    required this.userId,
    required this.title,
    this.photoId,
    required this.price,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      apartmentId: json['apartment_id'] as int,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      photoId: json['photo_id'] as String?,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartment_id': apartmentId,
      'user_id': userId,
      'title': title,
      'photo_id': photoId,
      'price': price,
      'quantity': quantity,
    };
  }
}
