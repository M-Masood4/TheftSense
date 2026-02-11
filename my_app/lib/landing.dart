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
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'TheftSense\u2122')),
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
            SizedBox(
              width: 80,
              height: 40,
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


