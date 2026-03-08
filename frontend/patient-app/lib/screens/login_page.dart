import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'consent_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() async {

    var response = await ApiService.login(
      emailController.text,
      passwordController.text
    );

    if(response["access_token"] != null){

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConsentScreen())
      );

    }

  }

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(title: const Text("Patient Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height:20),

            ElevatedButton(
              onPressed: login,
              child: const Text("Login"),
            )

          ],
        ),
      ),
    );
  }
}