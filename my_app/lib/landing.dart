import 'package:flutter/material.dart';
import 'main.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String message = 'You Are Logged Out';

  void _logIn() {
    setState(() { 
      message = 'You Are Logged In';
    });
    
    // Navigate to the main app
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Shoplifting Detection System App')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Shoplifting Detection System App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome'),
            Text(message),
            SizedBox(
              width: 80,
              height: 20,
              child: FloatingActionButton(
                onPressed: _logIn,
                tooltip: 'Log In',
                child: const Text('Log In'),
              ),
            ),
          ]
        )
      ),
    );
  }
}


