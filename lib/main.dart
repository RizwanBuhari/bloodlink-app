import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this line
import 'firebase_options.dart';                   // Add this line
import 'screens/registration_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart'; // Adjust path if your screens are elsewhere
import 'screens/home_screen.dart';
import 'package:flutterprojects/screens/login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line
  await Firebase.initializeApp(                // Add this line
    options: DefaultFirebaseOptions.currentPlatform, // Add this line
  );                                           // Add this line
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase App', // You can change the title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Optional: hides the debug banner

      // VVVV THIS IS THE MAIN CHANGE VVVV
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          // Show a loading indicator while checking auth state (good practice)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // After connection state is resolved:
          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in (snapshot.data contains the User object)
            return const HomeScreen(); // Show HomeScreen
          } else {
            // User is logged out (snapshot.data is null)
            return const LoginScreen(); // Show LoginScreen
          }
        },
      ),
      // ^^^^ END OF MAIN CHANGE ^^^^
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}