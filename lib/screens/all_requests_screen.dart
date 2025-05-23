import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:url_launcher/url_launcher.dart'; // Optional for tappable phone

class AllRequestsScreen extends StatefulWidget {
  const AllRequestsScreen({super.key});

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

enum RequestViewType { all, nearby }

class _AllRequestsScreenState extends State<AllRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  String? _currentUserEmirate;
  bool _isLoadingUserData = true; // Combined loading state

  // --- State for view type ---
  RequestViewType _selectedViewType = RequestViewType.all; // Default to showing all

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
      return;
    }
    try {
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (mounted) {
        if (userDoc.exists && userDoc.data() != null && userDoc.data()!['emirate'] != null) {
          _currentUserEmirate = userDoc.data()!['emirate'] as String;
        } else {
          print("User profile or Emirate not found for UID: ${_currentUser!.uid}");
          // _currentUserEmirate will remain null, "Nearby" might not work as expected
          // or could be disabled if _currentUserEmirate is null.
        }
      }
    } catch (e) {
      if (mounted) {
        print("Error fetching user's Emirate: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Future<void> _launchPhoneDialer(String phoneNumber) async { ... } // Optional

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Blood Requests'), backgroundColor: Colors.blueAccent),
        body: const Center(child: Text('Please log in to view requests.')),
      );
    }

    if (_isLoadingUserData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Blood Requests'), backgroundColor: Colors.blueAccent),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading data..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Blood Requests'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // --- Toggle Buttons for All / Nearby ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: ToggleButtons(
              isSelected: [
                _selectedViewType == RequestViewType.all,
                _selectedViewType == RequestViewType.nearby,
              ],
              onPressed: (int index) {
                setState(() {
                  _selectedViewType = RequestViewType.values[index];
                });
              },
              borderRadius: BorderRadius.circular(8.0),
              selectedBorderColor: Colors.blueAccent,
              selectedColor: Colors.white,
              fillColor: Colors.blueAccent,
              color: Colors.blueAccent,
              constraints: BoxConstraints(
                minHeight: 40.0,
                minWidth: (MediaQuery.of(context).size.width - 48) / 2, // Adjust padding
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('All Requests'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Nearby Requests'),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('bloodRequests')
                  .where('status', isEqualTo: 'active') // Keep this if you use it
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  print('AllRequestsScreen Stream Error: ${snapshot.error}');
                  return Center(child: Text('Something went wrong: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No active blood requests at the moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  );
                }

                // 1. Filter out requests made by the current user
                List<DocumentSnapshot> displayRequests = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  return data != null && data['requesterId'] != null && data['requesterId'] != _currentUser!.uid;
                }).toList();

                // 2. Apply "Nearby" filter if selected and user's Emirate is known
                if (_selectedViewType == RequestViewType.nearby) {
                  if (_currentUserEmirate != null && _currentUserEmirate!.isNotEmpty) {
                    displayRequests = displayRequests.where((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      return data != null && data['location'] == _currentUserEmirate;
                    }).toList();
                  } else {
                    // User's Emirate is not available, "Nearby" effectively shows nothing
                    // or you could show a message. For now, it will show an empty list
                    // if this condition isn't met for any request.
                    // Or, disable the "Nearby" toggle if _currentUserEmirate is null.
                    if (displayRequests.isNotEmpty) { // Only show message if there were other requests initially
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Your location (Emirate) is not set. Cannot show nearby requests.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      );
                    }
                  }
                }
                // For RequestViewType.all, no further location filtering is done here.
                // All requests (from other users) are already sorted by timestamp from Firestore.

                if (displayRequests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _selectedViewType == RequestViewType.nearby
                            ? 'No nearby requests found.'
                            : 'No active requests from other users right now.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0), // Adjust top padding
                  itemCount: displayRequests.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot document = displayRequests[index];
                    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                    String additionalNotes = data['additionalNotes'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      elevation: 3.0,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            data['bloodGroup'] ?? 'N/A',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                        ),
                        title: Text(
                          'Needs: ${data['bloodGroup']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Location: ${data['location'] ?? 'Not specified'}'),
                            Text('Urgency: ${data['urgency'] ?? 'Not specified'}'),
                            if (data['requesterName'] != null &&
                                data['requesterName'].toString().isNotEmpty &&
                                data['requesterName'] != 'N/A')
                              Text('Requested by: ${data['requesterName']}',
                                  style: const TextStyle(fontStyle: FontStyle.italic)),
                            Text('Contact: ${data['contactPerson'] ?? 'N/A'}'),
                            // GestureDetector for phone (optional)
                            Text('Phone: ${data['contactPhone'] ?? 'N/A'}'),
                            if (additionalNotes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Notes: $additionalNotes',
                                    style: const TextStyle(fontSize: 12.5)),
                              ),
                            if (data['timestamp'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Requested: ${formatTimestamp(data['timestamp'])}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}