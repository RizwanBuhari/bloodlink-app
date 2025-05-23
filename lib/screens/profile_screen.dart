// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart'; // <--- ADD THIS IMPORT

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _fetchUserData();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No user logged in. Please login again.";
        });
      }
      print("ProfileScreen: No current user found in initState.");
    }
  }

  Future<void> _fetchUserData() async {
    // ... (keep existing _fetchUserData method as is) ...
    // ... (no changes needed in _fetchUserData for this step)
    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Cannot fetch data: User is not available.";
        });
      }
      return;
    }

    // Ensure _isLoading is true at the start of fetching if not already
    // This is useful for the .then() block after editing, to show loading again
    if (mounted) { // Only set state if it needs changing
      setState(() {
        _isLoading = true;
        _errorMessage = ''; // Clear previous errors
      });
    }

    try {
      final String uid = _currentUser!.uid;
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(uid).get();

      if (mounted) {
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data();
            _isLoading = false;
          });
          print("User data fetched successfully: $_userData");
        } else {
          setState(() {
            _errorMessage = "User data not found in Firestore.";
            _isLoading = false;
          });
          print("User data not found for UID: $uid");
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load profile data. Please try again.";
          _isLoading = false;
        });
      }
    }
  }


  Widget _buildProfileItem(String label, String? value) {
    // ... (keep existing _buildProfileItem method as is) ...
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // VVVV MODIFY THIS METHOD VVVV
  void _navigateToEditProfile() {
    if (_userData != null && _currentUser != null) { // Also check _currentUser for safety
      print("Navigating to Edit Profile with data: $_userData");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(currentUserData: _userData!),
        ),
      ).then((result) { // The 'result' can be used if EditProfileScreen pops with a value
        // This block executes when EditProfileScreen is popped (e.g., after saving)
        // Re-fetch data to reflect any changes.
        print("Returned from EditProfileScreen. Refreshing data.");
        _fetchUserData(); // Re-fetch data
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not available to edit.')),
      );
    }
  }
  // ^^^^ END OF MODIFIED METHOD ^^^^


  @override
  Widget build(BuildContext context) {
    // ... (keep existing build method as is, no changes needed here for this step) ...
    // ... (the ElevatedButton for 'Edit Profile' will now use the updated _navigateToEditProfile)
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.red[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : _userData != null
          ? RefreshIndicator(
        onRefresh: _fetchUserData,
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileItem('Name', _userData!['name'] as String?),
            _buildProfileItem('Email', _currentUser?.email),
            _buildProfileItem('Blood Group', _userData!['bloodGroup'] as String?),
            _buildProfileItem('Phone Number', _userData!['phoneNumber'] as String?),
            _buildProfileItem('Emirate', _userData!['emirate'] as String?),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                onPressed: _navigateToEditProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      )
          : const Center(
        child: Text('No user data found or user is null.'),
      ),
    );
  }
}