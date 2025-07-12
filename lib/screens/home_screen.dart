import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'create_request_screen.dart';
import 'my_requests_screen.dart';
import 'all_requests_screen.dart';
import 'donor_finder_screen.dart';
import 'blood_bank_locations_screen.dart';
import 'login_screen.dart';

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
          _userName = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    print("--- HomeScreen _logout: _logout() CALLED ---");
    try {
      print("--- HomeScreen _logout: Attempting FirebaseAuth.instance.signOut() ---");
      await FirebaseAuth.instance.signOut();
      print("--- HomeScreen _logout: FirebaseAuth.instance.signOut() COMPLETED ---");

      if (mounted) {
        print(
            "--- HomeScreen _logout: Forcing navigation to LoginScreen after successful sign out ---");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) =>
          false,
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

      }
    }
  }

  void _navigateToProfile() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      print("--- HomeScreen _navigateToProfile: Cannot navigate to profile, no current user. ---");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to view the profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("--- HomeScreen build method CALLED. isLoading: $_isLoading, userName: $_userName ---");

    final List<_BoxButtonData> buttons = [
      _BoxButtonData(
        label: 'Request Blood',
        color: Colors.red[600]!,
        icon: Icons.bloodtype,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRequestScreen()));
        },
      ),
      _BoxButtonData(
        label: 'Find Donors',
        color: Colors.green[600]!,
        icon: Icons.people_alt,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DonorFinderScreen()));
        },
      ),
      _BoxButtonData(
        label: 'My Requests',
        color: Colors.teal,
        icon: Icons.list_alt,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRequestsScreen()));
        },
      ),
      _BoxButtonData(
        label: 'Active Requests',
        color: Colors.blueAccent,
        icon: Icons.view_list,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AllRequestsScreen()));
        },
      ),
      _BoxButtonData(
        label: 'Blood Banks',
        color: Colors.orangeAccent,
        icon: Icons.location_on,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BloodBankLocationsScreen()));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
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
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            children: [
              Text(
                _userName != null && _userName!.isNotEmpty
                    ? 'Welcome, $_userName!'
                    : 'Welcome!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Grid of box buttons
              Expanded(
                child: GridView.builder(
                  itemCount: buttons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3, // Width / height ratio
                  ),
                  itemBuilder: (context, index) {
                    final btn = buttons[index];
                    return _BoxButton(
                      label: btn.label,
                      color: btn.color,
                      icon: btn.icon,
                      onTap: btn.onTap,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxButtonData {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  _BoxButtonData({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}

class _BoxButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _BoxButton({
    Key? key,
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white24,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 0.7,
                ),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}
