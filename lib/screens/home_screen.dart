import 'package:flutter/material.dart';
import 'package:flutter/material.dart'; // Already present
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your screen imports
import 'profile_screen.dart';
import 'create_request_screen.dart';
import 'my_requests_screen.dart'; // Corrected path assuming it's in the same 'screens' directory
import 'all_requests_screen.dart'; // Corrected path
import 'donor_finder_screen.dart'; // Corrected path
import 'blood_bank_locations_screen.dart'; // Corrected path
import 'login_screen.dart'; // Added for forced navigation

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
      // If no current user on init (e.g., app started fresh and user not logged in),
      // then we are not loading user name.
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

    // Ensure _isLoading is true when fetching starts, in case _fetchUserName is called again.
    if (mounted && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (mounted) {
        if (userData.exists && userData.data() != null) {
          final data = userData.data() as Map<String, dynamic>;
          _userName = data['name'] as String?; // Assuming 'name' field exists
        } else {
          _userName = null; // Explicitly set to null if not found
          print(
              "--- HomeScreen _fetchUserName: User document not found or empty for UID: ${_currentUser!.uid} ---");
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('--- HomeScreen _fetchUserName: Error fetching user name: $e ---');
      if (mounted) {
        setState(() {
          _userName = null; // Set to null on error
          _isLoading = false;
        });
      }
    }
  }

  // Corrected _logout method
  Future<void> _logout() async {
    print("--- HomeScreen _logout: _logout() CALLED ---");
    try {
      print("--- HomeScreen _logout: Attempting FirebaseAuth.instance.signOut() ---");
      await FirebaseAuth.instance.signOut();
      print("--- HomeScreen _logout: FirebaseAuth.instance.signOut() COMPLETED ---");

      // If widget is still mounted, force navigation to LoginScreen
      if (mounted) {
        print(
            "--- HomeScreen _logout: Forcing navigation to LoginScreen after successful sign out ---");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) =>
          false, // This predicate removes all routes before LoginScreen
        );
      } else {
        print(
            "--- HomeScreen _logout: User signed out successfully, but widget is not mounted. Cannot navigate. ---");
      }
    } catch (e) {
      print("--- HomeScreen _logout: ERROR during _logout(): $e ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
        // Optional: If you want to navigate to LoginScreen even if there's an error during logout
        // You could add navigation here if desired for error cases too.
        // print("--- HomeScreen _logout: Forcing navigation to LoginScreen after ERROR during sign out ---");
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (context) => const LoginScreen()),
        //   (Route<dynamic> route) => false,
        // );
      }
    }
  }

  void _navigateToProfile() {
    if (_currentUser != null) { // Good practice to check if user exists
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      // Optionally, handle the case where there's no user (e.g., show a message)
      print("--- HomeScreen _navigateToProfile: Cannot navigate to profile, no current user. ---");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to view the profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("--- HomeScreen build method CALLED. isLoading: $_isLoading, userName: $_userName ---");
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonWidth = screenWidth * 0.8; // Ensure this is not too wide for smaller screens

    final ButtonStyle commonButtonStyle = ElevatedButton.styleFrom(
      minimumSize: Size(buttonWidth > 0 ? buttonWidth : 200, 48), // Add a fallback minimum width
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      foregroundColor: Colors.white, // Text color for buttons (if background is dark)
      backgroundColor: Colors.red[600], // Example button background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 2,
    );

    // Specific styles for buttons that might have different background colors
    final ButtonStyle tealButtonStyle = commonButtonStyle.copyWith(
      backgroundColor: MaterialStateProperty.all<Color?>(Colors.teal),
    );
    final ButtonStyle blueAccentButtonStyle = commonButtonStyle.copyWith(
      backgroundColor: MaterialStateProperty.all<Color?>(Colors.blueAccent),
    );
    final ButtonStyle orangeAccentButtonStyle = commonButtonStyle.copyWith(
      backgroundColor: MaterialStateProperty.all<Color?>(Colors.orangeAccent),
    );
    final ButtonStyle defaultButtonStyle = commonButtonStyle.copyWith(
      backgroundColor: MaterialStateProperty.all<Color?>(Colors.grey[300]),
      foregroundColor: MaterialStateProperty.all<Color?>(Colors.black), // Text black for light background
    );


    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        // backgroundColor is inherited from theme in main.dart if set, or can be overridden here
        // backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
            tooltip: 'View Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Calls the corrected _logout method
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                _userName != null && _userName!.isNotEmpty
                    ? 'Welcome, $_userName!'
                    : 'Welcome!',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87), // Adjusted text color
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Button 1: Request Blood
              ElevatedButton(
                style: defaultButtonStyle,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                        const CreateRequestScreen()),
                  );
                },
                child: const Text('Request Blood'),
              ),
              const SizedBox(height: 15),

              // Button 2: Find Available Donors
              ElevatedButton(
                style: defaultButtonStyle,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DonorFinderScreen()),
                  );
                },
                child: const Text('Find Available Donors'),
              ),
              const SizedBox(height: 15),

              // Button 3: My Submitted Requests
              ElevatedButton(
                style: tealButtonStyle, // Using specific style
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyRequestsScreen()),
                  );
                },
                child: const Text('My Submitted Requests'),
              ),
              const SizedBox(height: 15),

              // Button 4: View Active Requests
              ElevatedButton(
                style: blueAccentButtonStyle, // Using specific style
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AllRequestsScreen()),
                  );
                },
                child: const Text('View Active Requests'),
              ),
              const SizedBox(height: 15),

              // Button 5: Blood Bank Locations
              ElevatedButton(
                style: orangeAccentButtonStyle, // Using specific style
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                        const BloodBankLocationsScreen()),
                  );
                },
                child: const Text('Blood Bank Locations'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}