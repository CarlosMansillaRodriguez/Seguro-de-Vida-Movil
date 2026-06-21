/*import 'package:flutter/material.dart';
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
  bool _loading = false;

  Future<void> login() async {
    setState(() => _loading = true);
    try {
      final success = await auth.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        await auth.esperarDeteccionRol();
        if (auth.esSistema) {
          Navigator.pushReplacementNamed(context, '/sistema');
        } else if (auth.esAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (auth.esAgente) {
          Navigator.pushReplacementNamed(context, '/agente');
        } else {
          // Cliente u otro rol
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales inválidas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Ingresa para gestionar tu seguro de vida",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: "Correo electrónico"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: "Contraseña"),
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
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : login,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Ingresar",
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthService();
  bool _loading = false;

  Future<void> login() async {
    setState(() => _loading = true);
    try {
      final success = await auth.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        await auth.esperarDeteccionRol();

        // Registramos el token FCM del dispositivo ahora que ya hay sesión.
        NotificationService().registrarTokenEnBackend();

        if (auth.esSistema) {
          Navigator.pushReplacementNamed(context, '/sistema');
        } else if (auth.esAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (auth.esAgente) {
          Navigator.pushReplacementNamed(context, '/agente');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales inválidas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Ingresa para gestionar tu seguro de vida",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: "Correo electrónico"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: "Contraseña"),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/forgot'),
                  child: const Text("¿Olvidaste tu contraseña?"),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text("¿No tienes cuenta? Regístrate"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : login,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Ingresar", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}