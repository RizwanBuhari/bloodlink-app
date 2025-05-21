import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      // VVVV REPLACE THE EXISTING PRINT STATEMENTS WITH THIS TRY-CATCH BLOCK VVVV
      try {
        // Optional: Show a loading indicator to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logging in...')),
        );

        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(), // Get email from controller
          password: _passwordController.text.trim(), // Get password from controller
        );

        // If login is successful, remove loading SnackBar and show success
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful! Welcome ${userCredential.user?.email}')),
        );

        print("User logged in: ${userCredential.user?.uid}");

        /*if (mounted) { // Check if the widget is still in the tree
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );

        }*/        // Example (if you have a HomeScreen and it's imported):
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const HomeScreen()),
        // );

      } on FirebaseAuthException catch (e) {
        // If Firebase throws an error (e.g., user not found, wrong password)
        ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove "Logging in..."
        String errorMessage = 'Login failed. Please try again.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password. Please try again.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is badly formatted.';
        }
        // You can add more specific error codes if needed
        print('FirebaseAuthException: ${e.code} - ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } catch (e) {
        // For any other unexpected errors
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        print('Generic error during login: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred. Please try again.'), backgroundColor: Colors.red),
        );
      }
      // ^^^^ END OF THE TRY-CATCH BLOCK ^^^^
    } else {
      // This part remains the same: if form is invalid, validators will show messages.
      print('Form is invalid.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center( // Center the form on the screen
          child: SingleChildScrollView( // Allow scrolling if content overflows
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically in the column
                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
                children: <Widget>[
                  // Email TextFormField
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Password TextFormField
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      // We'll add a suffixIcon for password visibility later if desired
                    ),
                    obscureText: true, // Hide password input
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      // You can add more password validation rules here if needed
                      // e.g., minimum length
                      // if (value.length < 6) {
                      //   return 'Password must be at least 6 characters';
                      // }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // Login Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      _loginUser();
                    },
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16.0), // Add some spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push( // Use push, not pushReplacement
                            context,
                            MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                          );
                        },
                        child: const Text(
                          'Register Here',
                          style: TextStyle(
                            // Optional: Add some style to make it look more like a link
                            // fontWeight: FontWeight.bold,
                            // color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // ^^^^ END OF ADDED SECTION ^^^^
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}