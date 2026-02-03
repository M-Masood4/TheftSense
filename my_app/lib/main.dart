import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shoplifting Detection System App',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color.fromARGB(255, 40, 141, 209)),
      ),
      home: const MyHomePage(
        title: 'Shoplifting Detection System App 2',
      )
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //int _counter = 0;
  String message = 'You Are Logged Out';

  void _logIn() {
    setState(() { message = 'You Are Logged In'; });
  }

  void _logOut() {
    setState(() { message = 'You Are Logged Out'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black, 
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Cameras'),
                BottomNavigationBarItem(icon: Icon(Icons.login), label: 'History'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings')
              ]
            ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Welcome'),
            
            Text(message),
            
            SizedBox(
              width:80,
              height:20,
              child: FloatingActionButton(
                onPressed: _logIn,
                tooltip: 'Log In',
                child: const Text('Log In'),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width:80,
              height:20,
              child: FloatingActionButton(
                onPressed: _logOut,
                tooltip: 'Log Out',
                child: const Text('Log Out'),
              ),
            ),
            /*
            BottomNavigationBar(
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.black, 
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Cameras'),
                BottomNavigationBarItem(icon: Icon(Icons.login), label: 'History'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings')
              ]
            )
            */
          ],
        ),
      ),
    );
  }
}
