import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class DonorFinderScreen extends StatefulWidget {
  const DonorFinderScreen({super.key});

  @override
  State<DonorFinderScreen> createState() => _DonorFinderScreenState();
}

enum DonorViewType { all, nearby } // To manage the view

class _DonorFinderScreenState extends State<DonorFinderScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance of FirebaseAuth
  User? _currentUser;

  bool _isLoading = true; // Overall loading for initial data + user data
  List<Map<String, dynamic>> _allDonorsList = []; // Stores all fetched donors
  String? _errorMessage;
  String? _currentUserEmirate; // To store current user's Emirate

  DonorViewType _selectedViewType = DonorViewType.all; // Default to showing all

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fetch current user's Emirate first (or in parallel)
    if (_currentUser != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (mounted && userDoc.exists && userDoc.data() != null) {
          _currentUserEmirate = userDoc.data()!['emirate'] as String?;
        }
      } catch (e) {
        if (mounted) {
          print("Error fetching current user's Emirate: $e");
          // Not critical for "All Donors" view, but "Nearby" might not work as expected
        }
      }
    }

    // Then fetch all donors
    await _fetchDonors();

    // No longer need to set _isLoading to false here, _fetchDonors handles it
  }

  Future<void> _fetchDonors() async {
    // If _isLoading is already true because of _loadInitialData, don't reset it here
    // unless this is a manual refresh action. For initial load, it's fine.
    if (!mounted) return;
    if (/*!_isLoading*/ _allDonorsList.isEmpty) { // Only set loading if not already loading or for a retry
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }


    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isDonor', isEqualTo: true)
      // .orderBy('name') // Optional: if you want to sort all donors by name (requires index)
          .get();

      if (!mounted) return;

      _allDonorsList = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Optional: If you want to sort all donors by name client-side after fetching
      // _allDonorsList.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));

    } catch (e) {
      if (!mounted) return;
      print('Error fetching donors: $e');
      _errorMessage = 'Failed to load donors. Please try again later.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Donors'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadInitialData, // Retry loading everything
                child: const Text('Try Again'),
              )
            ],
          ),
        ),
      );
    }

    // Determine the list to display based on the selected view type
    List<Map<String, dynamic>> displayedDonors = _allDonorsList;

    if (_selectedViewType == DonorViewType.nearby) {
      if (_currentUserEmirate != null && _currentUserEmirate!.isNotEmpty) {
        displayedDonors = _allDonorsList.where((donor) {
          final String? donorEmirate = donor['emirate'] as String?;
          return donorEmirate == _currentUserEmirate;
        }).toList();
      } else {
        // Handle case where current user's Emirate is not available for "Nearby"
        // You could show all, or show a message, or disable the "Nearby" toggle.
        // For now, if Emirate is unknown, "Nearby" will effectively show nothing if no donor matches 'null'
      }
    }

    // Optional: If you want to sort the "Nearby" list differently (e.g., by name)
    // if (_selectedViewType == DonorViewType.nearby && displayedDonors.isNotEmpty) {
    //   displayedDonors.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
    // }


    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: ToggleButtons(
            isSelected: [
              _selectedViewType == DonorViewType.all,
              _selectedViewType == DonorViewType.nearby,
            ],
            onPressed: (int index) {
              // Prevent toggling to "Nearby" if user's Emirate is unknown
              if (index == 1 && (_currentUserEmirate == null || _currentUserEmirate!.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Your location (Emirate) is not set. Cannot show nearby donors.")),
                );
                return;
              }
              setState(() {
                _selectedViewType = DonorViewType.values[index];
              });
            },
            borderRadius: BorderRadius.circular(8.0),
            selectedBorderColor: Colors.blueAccent,
            selectedColor: Colors.white,
            fillColor: Colors.blueAccent,
            color: Colors.blueAccent,
            constraints: BoxConstraints(
              minHeight: 40.0,
              minWidth: (MediaQuery.of(context).size.width - 48) / 2, // Adjust for padding
            ),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('All Donors'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Nearby Donors'),
              ),
            ],
          ),
        ),
        if (displayedDonors.isEmpty)
          Expanded( // Use Expanded to allow Center to take remaining space
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _selectedViewType == DonorViewType.all
                      ? 'No donors found at the moment.'
                      : (_currentUserEmirate == null || _currentUserEmirate!.isEmpty)
                      ? 'Your location (Emirate) is not set in your profile.'
                      : 'No donors found in your Emirate ($_currentUserEmirate).',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8), // Remove top padding from ListView
              itemCount: displayedDonors.length,
              itemBuilder: (context, index) {
                final donor = displayedDonors[index];
                final String name = donor['name'] as String? ?? 'N/A';
                final String? bloodGroup = donor['bloodGroup'] as String?;
                final String? emirate = donor['emirate'] as String? ?? 'Not specified';
                final String? phoneNumber = donor['phoneNumber'] as String? ?? 'Not available';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent.shade100,
                      child: Text(
                        bloodGroup ?? '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Emirate: $emirate'), // Added label for clarity
                        Text('Phone: $phoneNumber'), // Added label for clarity
                      ],
                    ),
                    // onTap: () { print('Tapped on $name'); },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}