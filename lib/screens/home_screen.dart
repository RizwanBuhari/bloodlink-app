// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> { // <--- Line 12 (Error should disappear after fix)
  User? _currentUser;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fetchUserName();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserName() async {
    if (_currentUser == null) { // Guard clause
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    print("Fetching user name for UID: ${_currentUser!.uid}"); // Now safe to use !
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users') // Make sure 'users' is your collection name
          .doc(_currentUser!.uid)
          .get();

      if (mounted) {
        if (userData.exists) {
          // Assuming the name field in Firestore is 'name'
          // Adjust '.get('name')' if your field is named differently (e.g., 'fullName', 'username')
          _userName = userData.get('name') as String?; // Cast to String? for safety
          print("User name fetched: $_userName");
        } else {
          print('User document does not exist for UID: ${_currentUser!.uid}');
          _userName = null; // Or handle as "User" or some default
        }
        setState(() {
          _isLoading = false; // Data fetched (or not found), stop loading
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
      if (mounted) {
        setState(() {
          _userName = null; // Error occurred, name is unknown
          _isLoading = false; // Stop loading even if there's an error
        });
      }
    }
  } // <------------------------------------------ _fetchUserName() METHOD ENDS HERE
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    print("User signed out.");
    // If you are NOT using a root StreamBuilder to handle auth state changes for navigation,
    // you might need to explicitly navigate here:
    // if (mounted) {
    //   Navigator.of(context).pushAndRemoveUntil(
    //     MaterialPageRoute(builder: (context) => LoginScreen()), // Replace LoginScreen with your actual login screen widget
    //     (Route<dynamic> route) => false,
    //   );
    // }
  }
  // VVVV BUILD METHOD SHOULD BE HERE, OUTSIDE _fetchUserName VVVV
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser; // This is temporary

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // <--- CHANGE THIS LINE
            tooltip: 'Logout',  // <--- ADD THIS LINE
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // Show loading indicator when _isLoading is true
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              // Display user's name if available, otherwise a generic welcome
              _userName != null && _userName!.isNotEmpty
                  ? 'Welcome, $_userName!'
                  : 'Welcome!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            /*const SizedBox(height: 8), // Adjusted spacing
            // Display email using the _currentUser state variable
            if (_currentUser != null) // Use the state variable _currentUser
              Text(
                'Email: ${_currentUser!.email}', // Make sure to use _currentUser.email
                style: const TextStyle(fontSize: 16),
              )
            else
              const Text(
                'Not logged in', // This case should ideally not be hit if navigation is correct
                style: TextStyle(fontSize: 16),
              ),*/
            const SizedBox(height: 20),
            // You can add more widgets or app functionality here
          ],
        ),
      ),
    );
  } // <------------------------------------------ build() METHOD ENDS HERE
} // <------------------------------------------ _HomeScreenState CLASS ENDS HERE