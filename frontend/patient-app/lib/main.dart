import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_page.dart';
import 'screens/home_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const HealthSyncApp());
}

class HealthSyncApp extends StatefulWidget {
  const HealthSyncApp({super.key});

  @override
  State<HealthSyncApp> createState() => _HealthSyncAppState();
}

class _HealthSyncAppState extends State<HealthSyncApp> {

  Widget startPage = const SizedBox();

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if(token != null){
      startPage = const MainScreen();
    } else {
      startPage = const LoginPage();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "HealthSync",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: startPage,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int currentIndex = 0;

  final List<Widget> screens = [
    const HomeScreen(),
    const ConsentScreen(),
    const ProfileScreen(),
  ];

  void changeTab(int index){
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(

      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: changeTab,

        destinations: const [

          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),

          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: "Consent",
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),

        ],
      ),
    );
  }
}