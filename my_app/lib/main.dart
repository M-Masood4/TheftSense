import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'cameras.dart';
import 'history.dart';
import 'settings.dart';
import 'landing.dart';

List<CameraDescription> priv_cameras = [];
List<CameraDescription> cameras = [];

const bool _usePhoneTestMode = bool.fromEnvironment('USE_PHONE_TEST_MODE', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kIsWeb) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: _usePhoneTestMode,
      forceRecaptchaFlow: !_usePhoneTestMode,
    );
  }
  //priv_cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      /// NOTE: this is overriding the settings
      /// in landing.dart, if you want to change
      /// the app's color scheme, remove 'theme'.
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.white,
          onSecondary: Colors.black,
          error: Colors.black,
          onError: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      home: const LandingPage(),
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
  int _selectedIndex = 0;

  /// This is the list of pages. Right now each page is just a
  /// 'Center' object that displays the page name, but it should
  /// work well enough for you to start working on it.

  late final List<Widget> _pages = [
    HomePage(),
    CameraPage(),
    const HistoryPage(),
    SettingsPage(),
  ];
  void _changePage(int page_index) {
    setState(() {
      _selectedIndex = page_index;
    });
  }

  /// The build() function is called when runApp() is executed,
  /// every widget declared in build() is displayed.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
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
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _changePage,
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Cameras'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
