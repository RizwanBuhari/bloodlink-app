import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  print("--- main: WidgetsFlutterBinding.ensureInitialized() called ---");

  print("--- main: Firebase.initializeApp starting ---");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("--- main: Firebase.initializeApp completed SUCCESSFULLY ---");
  } catch (e) {
    print("--- main: Firebase.initializeApp FAILED: $e ---");

  }


  print("--- main: runApp(const MyApp()) called ---");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("--- MyApp build method CALLED ---");
    return MaterialApp(
      title: 'Blood Donation App', // Or your preferred app title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red[700] ?? Colors.red), // Using your app's theme color
        useMaterial3: true,
        // You can add more theme customizations here
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red[700] ?? Colors.red, // Consistent AppBar color
          foregroundColor: Colors.white, // Text/icon color on AppBar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600] ?? Colors.redAccent, // Button background
            foregroundColor: Colors.white, // Button text/icon color
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false, // Hides the debug banner

      // StreamBuilder to handle authentication state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          // VITAL DEBUG PRINT for StreamBuilder
          print(
              "--- StreamBuilder REBUILT --- ConnectionState: ${snapshot.connectionState}, HasError: ${snapshot.hasError}, Error: ${snapshot.error}, HasData: ${snapshot.hasData}, User ID: ${snapshot.data?.uid}, User Email: ${snapshot.data?.email}");

          // 1. Handle connection state (while waiting for the first auth event)
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("--- StreamBuilder: State is WAITING (initial auth check) ---");
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Connecting..."),
                  ],
                ),
              ),
            );
          }

          // 2. Handle errors in the auth stream itself
          if (snapshot.hasError) {
            print("--- StreamBuilder: Snapshot HAS ERROR: ${snapshot.error} ---");
            // You might want to show a more user-friendly error screen here
            return Scaffold(
              body: Center(
                child: Text(
                  "Error in authentication stream: ${snapshot.error}\nPlease restart the app.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // 3. After connection state is resolved and no stream error:
          // Check if user data is present (logged in)
          if (snapshot.hasData && snapshot.data != null) {
            print(
                "--- StreamBuilder: User IS LOGGED IN (User ID: ${snapshot.data!.uid}) --- Navigating to HomeScreen ---");
            return const HomeScreen(); // Show HomeScreen
          } else {
            // User is logged out (snapshot.data is null or no data)
            print(
                "--- StreamBuilder: User IS LOGGED OUT or data is null --- Navigating to LoginScreen ---");
            return const LoginScreen(); // Show LoginScreen
          }
        },
      ),

    );
  }
}

