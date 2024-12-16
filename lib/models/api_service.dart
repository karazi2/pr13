  import 'package:dio/dio.dart';
  import 'note.dart';

  class ApiService {
    final Dio _dio = Dio();

    // Получение всех квартир
    Future<List<Note>> getApartments() async {
      try {
        final response = await _dio.get('http://192.168.0.22:8080/apartments');
        if (response.statusCode == 200) {
          return (response.data as List)
              .map((apartment) => Note.fromJson(apartment))
              .toList();
        } else {
          throw Exception('Failed to load apartments');
        }
      } catch (e) {
        throw Exception('Error fetching apartments: $e');
      }
    }

    Future<Note> getApartmentById(int id) async {
      try {
        final response = await _dio.get('http://192.168.0.22:8080/apartments/$id');
        if (response.statusCode == 200) {
          return Note.fromJson(response.data); // Создаем объект Note из JSON
        } else {
          throw Exception('Failed to fetch apartment details');
        }
      } catch (e) {
        throw Exception('Error fetching apartment by ID: $e');
      }
    }
    Future<void> deleteApartment(int apartmentId) async {
      try {
        final response = await _dio.delete('http://192.168.0.22:8080/apartments/delete/$apartmentId');
        if (response.statusCode != 204) {
          throw Exception('Ошибка удаления квартиры');
        }
      } catch (e) {
        throw Exception('Ошибка удаления: $e');
      }
    }
    Future<List<dynamic>> getOrders(String userId) async {
      try {
        final response = await _dio.get('http://192.168.0.22:8080/orders/$userId');
        if (response.statusCode == 200) {
          return response.data as List<dynamic>;
        } else {
          throw Exception('Ошибка загрузки заказов');
        }
      } catch (e) {
        throw Exception('Ошибка: $e');
      }
    }

    Future<void> createApartment(Note note) async {
      try {
        final data = {
          "title": note.title,
          "description": note.description,
          "image_link": note.photo_id,
          "price": note.price,
        };
        final response = await _dio.post('http://192.168.0.22:8080/apartments/create', data: data);

        if (response.statusCode != 200) {
          throw Exception('Ошибка создания квартиры: ${response.statusCode}');
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
        final response = await _dio.put(
          'http://192.168.0.22:8080/apartments/update/${note.id}',
          data: data,
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to update apartment');
        }
      } catch (e) {
        throw Exception('Error updating apartment: $e');
      }
    }

    // Переключение избранного
    Future<void> toggleFavourite(int id) async {
      try {
        final response = await _dio.put(
          'http://192.168.0.22:8080/apartments/favourite/$id',
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to toggle favourite');
        }
      } catch (e) {
        throw Exception('Error toggling favourite: $e');
      }
    }
    Future<List<CartItem>> getCart(String userId) async {
      try {
        final response = await _dio.get('http://192.168.0.22:8080/cart/$userId');
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
    Future<void> createOrder(String userId, List<CartItem> items) async {
      final data = {
        "user_id": userId,
        "items": items.map((item) => item.toJson()).toList(),
      };

      try {
        final response = await _dio.post('http://192.168.0.22:8080/orders', data: data);

        if (response.statusCode == 200) {
          print('Заказ успешно оформлен');
        } else {
          throw Exception('Ошибка оформления заказа');
        }
      } catch (e) {
        print('Ошибка: $e');
        throw Exception('Ошибка оформления заказа: $e');
      }
    }


    // Получение всех элементов корзины
    Future<void> getCartItems(int userId) async {
      try {
        final response = await _dio.get(
          'http://192.168.0.22:8080/cart/$userId',
        );

        if (response.statusCode == 200) {
          // Обработка данных корзины
          print('Cart items: ${response.data}');
        } else {
          throw Exception('Failed to load cart');
        }
      } catch (e) {
        print('Error fetching cart: $e');
      }
    }


    Future<void> addToCart(String userId, int apartmentId) async {
      final data = {
        "user_id": userId,       // UUID как строка
        "apartment_id": apartmentId, // Целое число
        "quantity": 1,
      };

      print('Отправляем запрос: $data'); // Логируем отправляемые данные

      try {
        final response = await _dio.post(
          'http://192.168.0.22:8080/cart',
          data: data,
        );

        if (response.statusCode == 200) {
          print('Успешно добавлено в корзину');
        } else {
          throw Exception('Ошибка добавления в корзину');
        }
      } catch (e) {
        print('Ошибка добавления в корзину: $e');
      }
    }


    Future<void> removeFromCart(String userId, int apartmentId) async {
      try {
        final response = await _dio.delete(
          'http://192.168.0.22:8080/cart/$userId/$apartmentId',
        );

        if (response.statusCode != 200) {
          throw Exception('Ошибка удаления из корзины');
        }
      } catch (e) {
        throw Exception('Ошибка удаления: $e');
      }
    }


  }
  class CartItem {
    final int id; // Уникальный ID элемента корзины
    final int apartmentId; // ID квартиры
    final String userId; // ID пользователя
    final String title; // Название квартиры
    final String? photoId; // Ссылка на изображение (может быть null)
    final double price; // Цена квартиры
    final int quantity; // Количество квартир в корзине

    CartItem({
      required this.id,
      required this.apartmentId,
      required this.userId,
      required this.title,
      this.photoId,
      required this.price,
      required this.quantity,
    });

    // Метод для создания объекта CartItem из JSON
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

    // Метод для преобразования объекта CartItem в JSON
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





