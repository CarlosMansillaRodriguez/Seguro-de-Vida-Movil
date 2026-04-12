import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthService();

  void login() async {
  bool success = await auth.login(
    emailController.text,
    passwordController.text,
  );

  if (success) {
    Navigator.pushReplacementNamed(context, '/dashboard');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credenciales inválidas')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Text(
                "Bienvenido 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Ingresa para gestionar tu seguro de vida",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Correo electrónico",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Contraseña",
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot'),
                  child: const Text("¿Olvidaste tu contraseña?"),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  child: const Text("Ingresar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}