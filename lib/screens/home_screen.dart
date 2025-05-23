import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'create_request_screen.dart';
import 'package:flutterprojects/screens/my_requests_screen.dart';
import 'package:flutterprojects/screens/all_requests_screen.dart';
import 'package:flutterprojects/screens/donor_finder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    // No need to set _isLoading = true here again as initState handles the initial loading

    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (mounted) {
        if (userData.exists) {
          _userName = userData.get('name') as String?;
        } else {
          _userName = null;
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
      if (mounted) {
        setState(() {
          _userName = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigation to LoginScreen is handled by the StreamBuilder in main.dart
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton( // <--- ADD THIS ICON BUTTON
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
            tooltip: 'View Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _userName != null && _userName!.isNotEmpty
                  ? 'Welcome, $_userName!'
                  : 'Welcome!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // You can add more app functionality here
            // For example, buttons to "Request Blood" or "Find Donors"
            // which we will build in later stages.
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
                );
              },
              child: const Text('Request Blood'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DonorFinderScreen()),
                );
              },
              child: const Text('Find Available Donors'), // You can also update the text if you wish
            ),
            const SizedBox(height: 12), // Optional: for spacing
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyRequestsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Feel free to choose another color or remove styling
              ),
              child: const Text('My Submitted Requests'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // Optional: Style it
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AllRequestsScreen()),
                );
              },
              child: const Text('View Active Requests'),
            ),

          ],
        ),
      ),
    );
  }
}