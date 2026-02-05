import 'package:flutter/material.dart';
import 'home.dart';
import 'cameras.dart';
import 'history.dart';
import 'settings.dart';
import 'landing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shoplifting Detection System App',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color.fromARGB(255, 40, 141, 209)),
      ),
      home: const LandingPage(
        // title: 'Shoplifting Detection System App',
      )
    );
  }
}

/// VERY IMPORTANT: 
/// If your page is stateful (ie: new elements are
/// going to be added dynamically, such as adding a new camera). 
/// You need to:
/// 1) take the 'MyHomePage' class below and
///    replace 'MyHomePage' with the name of your page.
/// 2) then you can start working in the '_MyHomePageState' class.
/// otherwise, flutter will complain and require to mark elements
/// as final.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // String message = 'You Are Logged Out';
  int _selectedIndex = 0;
  // bool _userLoggedIn = false;

  /// The _logIn() function logs the user in, for now it just opens
  /// the main app and displays the bottom navigation bar,
  // void _logIn() {
  //   setState(() { 
  //     message = 'You Are Logged In';
  //     _userLoggedIn = true;
  //   });
  // }

  // void _logOut() {
  //   setState(() { 
  //     message = 'You Are Logged Out'; 
  //     _userLoggedIn = false;
  //   });
  // }

  /// This is the list of pages. Right now each page is just a
  /// 'Center' object that displays the page name, but it should
  /// work well enough for you to start working on it.
  
  late final List<Widget> _pages = [
    HomePage(),
    CameraPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  // Widget _loginPage() {
  //   return Center(
  //     //mainAxisAlignment: .center,
  //     child: Column(
  //       mainAxisAlignment: .center,
  //       children: [
  //         const Text('Welcome'),
         
  //         Text(message),
            
  //         SizedBox(
  //           width:80,
  //           height:20,
  //           child: FloatingActionButton(
  //             onPressed: _logIn,
  //             tooltip: 'Log In',
  //             child: const Text('Log In'),
  //             ),
  //           ),
  //         /*
  //         const SizedBox(height: 20),

  //         SizedBox(
  //           width:80,
  //           height:20,
  //           child: FloatingActionButton(
  //             onPressed: _logOut,
  //             tooltip: 'Log Out',
  //             child: const Text('Log Out'),
  //           ),
  //         ),
  //         */
  //       ]
  //     )
  //   );
  // }

  void _changePage(int page_index) {
    setState(() { _selectedIndex = page_index; });
  }

  /// The build() function is called when runApp() is executed,
  /// every widget declared in build() is displayed.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      // if the user is logged in, display the home page, else display login page
      // body: _userLoggedIn ? IndexedStack(index: _selectedIndex, children: _pages,) : _loginPage(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      /**
       * This is the bottom navigation bar (child of Scaffold).
       * Each icon on the bar is a child of the bar.
       * First, it checks if the user is logged in before being displayed.
       * onTap: executes the function when an icon is pressed.
       * currentIndex: index of the page that is selected (must be 0 < x < items.length)
       */
      bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: _changePage,
        currentIndex: _selectedIndex,
        items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Cameras'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ]
),
    );
  }
}
