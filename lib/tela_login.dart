import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tela_home.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final user = await dbHelper.getUser(_emailController.text, _passController.text);
      if (user != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TelaHome()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login inválido')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.contains('@') ? null : "Email inválido",
              ),
              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(labelText: "Senha"),
                obscureText: true,
                validator: (value) => value!.isEmpty ? "Senha obrigatória" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: const Text("Entrar")),
            ],
          ),
        ),
      ),
    );
  }
}
