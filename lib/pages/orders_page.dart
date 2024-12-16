import 'dart:convert'; // Для jsonDecode
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/api_service.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: пользователь не авторизован')),
      );
      return;
    }

    try {
      final orders = await ApiService().getOrders(user.id);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки заказов: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки заказов')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text('Заказов пока нет'))
          : ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];

          // Разбор JSON-строки в массив объектов
          List<dynamic> items = [];
          if (order['items'] is String) {
            items = jsonDecode(order['items']) as List<dynamic>;
          }

          // Название первого элемента
          final title = items.isNotEmpty
              ? items[0]['title'] ?? 'Название не указано'
              : 'Название не указано';

          final totalPrice =
              order['total_price']?.toStringAsFixed(2) ?? '0.00';
          final createdAt = order['created_at'] ?? 'Неизвестно';

          return ListTile(
            title: Text(title),
            subtitle: Text('Итоговая стоимость: ₽$totalPrice'),
            trailing: Text(createdAt),
          );
        },
      ),
    );
  }
}
