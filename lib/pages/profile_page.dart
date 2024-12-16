import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'orders_page.dart'; // Импортируем OrdersPage
import 'chat.dart'; // Импортируем ChatPage (страница чата)

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception('Пользователь не авторизован.');
      }

      print('Current User ID: ${user.id}');
      final response = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        throw Exception('Пользователь не найден в базе данных.');
      }

      setState(() {
        _userName = response['name'] ?? 'Имя не указано';
        _userEmail = user.email;
      });
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );

      setState(() {
        _userName = 'Ошибка загрузки данных';
        _userEmail = '';
      });
    }
  }

  void _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }
  Future<void> _navigateToChat(BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        print('Ошибка: пользователь не авторизован.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: пользователь не авторизован')),
        );
        return;
      }

      // Здесь указываем конкретный seller_id вручную
      final String sellerId = 'a1b2c3d4-e5f6-7890-ab12-cd34ef567890';

      print('Переходим в чат с продавцом ID: $sellerId');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(sellerId: sellerId),
        ),
      );
    } catch (e) {
      print('Ошибка при переходе в чат: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при переходе в чат: $e')),
      );
    }
  }




  void _navigateToOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrdersPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Center(
        child: _userName != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Имя: $_userName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Почта: $_userEmail',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToOrders(context),
              child: const Text('Мои заказы'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _navigateToChat(context),
              child: const Text('Чат с продавцом'),
            ),
          ],
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
