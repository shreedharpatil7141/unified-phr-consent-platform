import 'package:flutter/material.dart';
import 'package:health1/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'medical_basics_screen.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  void login() async {

    setState(() {
      loading = true;
    });

    try {

      var response = await ApiService.login(
        emailController.text,
        passwordController.text
      );

      if(response["access_token"] != null){

        String token = response["access_token"];
        final bool profileComplete = response["profile_complete"] ?? false;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);

        if(!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => profileComplete
                ? const MainScreen()
                : const MedicalBasicsScreen(showSkip: false),
          ),
        );

      }

    } catch(e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Failed"))
      );

    }

    setState(() {
      loading = false;
    });

  }

  @override
  Widget build(BuildContext context){

    return Scaffold(

      body: Container(

        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff3a7bd5),
              Color(0xff00d2ff),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter
          ),
        ),

        child: Center(

          child: SingleChildScrollView(

            padding: const EdgeInsets.all(24),

            child: Card(

              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),

              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [

                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFFD6F5EF),
                      child: Icon(
                        Icons.health_and_safety,
                        size: 38,
                        color: Color(0xFF0F766E),
                      ),
                    ),

                    const SizedBox(height:10),

                    const Text(
                      "HealthSync",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Unified health records, consents, and connected care.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height:20),

                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)
                        ),
                      ),
                    ),

                    const SizedBox(height:15),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)
                        ),
                      ),
                    ),

                    const SizedBox(height:20),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(

                        onPressed: loading ? null : login,

                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                          )
                        ),

                        child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(fontSize:16),
                          ),

                      ),
                    ),

                    const SizedBox(height:10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        const Text("New user?"),

                        TextButton(
                          onPressed: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );

                          },
                          child: const Text("Register")
                        )

                      ],
                    )

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
