import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartPage extends StatefulWidget {
  final List<Note> cartItems; // Принимаем список Note (корзина)

  const CartPage({Key? key, required this.cartItems}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<Note> _cartItems; // Локальная копия корзины

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems; // Инициализируем локальную копию корзины
  }

  // Подсчет общей стоимости
  double _calculateTotalPrice() {
    return _cartItems.fold(0.0, (sum, item) => sum + item.price);
  }
  Future<void> _submitOrder() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: пользователь не авторизован')),
      );
      return;
    }

    try {
      // Преобразуем элементы корзины в список объектов CartItem
      final cartItems = _cartItems.map((item) {
        return CartItem(
          id: item.id,
          apartmentId: item.id,
          userId: user.id,
          title: item.title,
          photoId: item.photo_id,
          price: item.price,
          quantity: 1, // Укажите количество, если оно фиксированное
        );
      }).toList();

      // Отправляем заказ через ApiService
      await ApiService().createOrder(user.id, cartItems);

      setState(() {
        _cartItems.clear(); // Очищаем корзину после успешного заказа
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ успешно оформлен')),
      );
    } catch (e) {
      print('Ошибка оформления заказа: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка оформления заказа')),
      );
    }
  }

  // Удаление элемента
  Future<void> _removeFromCart(int itemId, int index) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: пользователь не авторизован')),
      );
      return;
    }

    try {
      await ApiService().removeFromCart(user.id, itemId);

      setState(() {
        _cartItems.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Элемент удален из корзины')),
      );
    } catch (e) {
      print('Ошибка удаления из корзины: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка удаления из корзины')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
      ),
      body: _cartItems.isEmpty
          ? const Center(child: Text('Корзина пуста'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return ListTile(
                  leading: item.photo_id.isNotEmpty
                      ? Image.network(
                    item.photo_id,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported),
                  )
                      : const Icon(Icons.image_not_supported),
                  title: Text(item.title),
                  subtitle:
                  Text('₽${item.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle,
                        color: Colors.red),
                    onPressed: () async {
                      await _removeFromCart(item.id, index);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Общая стоимость:',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₽${_calculateTotalPrice().toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cartItems.isEmpty ? null : _submitOrder,
                  child: const Text('Оформить заказ'),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
