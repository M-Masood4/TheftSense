import 'package:flutter/material.dart';
import 'pages/registration_page.dart';
import 'pages/login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {

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
            SizedBox(height:50),
            const Text('Welcome to TheftSense\u2122', style: TextStyle(fontSize:30)),
            SizedBox(height: 80),
            SizedBox(
              width: 200,
              height: 50,
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
              width: 200,
              height: 50,
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


