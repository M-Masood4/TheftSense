import 'package:flutter/material.dart';
import 'pages/registration_page.dart';
import 'pages/login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String message = 'You Are Logged Out';

  void _signUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationPage()),
    );
  }

  void _logIn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TheftSense\u2122'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height:120,
              child: Image.asset('lib/materials/theftSenseIcon.png', width:100, height:100)
            ),
            SizedBox(height:100),
            const Text('Welcome', style: TextStyle(fontSize:30)),
            Text(message, style: TextStyle(fontSize:30)),
            const SizedBox(height: 24),
            SizedBox(
              width: 140,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: _signUp,
                child: const Text('Sign Up'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 140,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: _logIn,
                child: const Text('Sign In'),
              ),
            ),
          ]
        )
      ),
    );
  }
}


