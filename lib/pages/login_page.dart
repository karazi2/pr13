  import 'package:flutter/material.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'register_page.dart';
  import '../main.dart';


  class LoginPage extends StatelessWidget {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    Future<void> _login(BuildContext context) async {
      try {
        if (emailController.text.isEmpty || passwordController.text.isEmpty) {
          throw Exception('Пожалуйста, заполните все поля.');
        }

        print('Авторизация...');
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        final user = response.user;
        if (user == null) {
          throw Exception('Неправильный логин или пароль');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вход успешен!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainNavigation()),
        );
      } catch (e) {
        print('Ошибка при входе: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Вход')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Пароль'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _login(context),
                child: const Text('Войти'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                child: const Text('Еще нет аккаунта? Зарегистрироваться'),
              ),
            ],
          ),
        ),
      );
    }
  }
