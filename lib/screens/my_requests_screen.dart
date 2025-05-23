import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    // It's good practice to also ensure the user is still valid
    // when the widget is built, not just in initState.
    // We'll handle this in the build method.
  }
  Future<void> _showDeleteConfirmationDialog(String documentId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this blood request?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteRequest(documentId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRequest(String documentId) async {
    try {
      await _firestore.collection('bloodRequests').doc(documentId).delete();
      print('Request $documentId deleted successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting request $documentId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting request: $e')),
        );
      }
    }
  }
  // We will add the build method and other logic in the next steps.
  // For now, to make the file valid Dart, let's add an empty build method:
  @override
  Widget build(BuildContext context) {
    _currentUser = _auth.currentUser; // Refresh current user state on build

    if (_currentUser == null) {
      // Handle case where user is not logged in or becomes logged out.
      // This screen shouldn't be accessible if not logged in,
      // but this is a good safeguard.
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Blood Requests'),
          backgroundColor: Colors.redAccent,
        ),
        body: const Center(
          child: Text('Please log in to see your requests.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Blood Requests'),
        backgroundColor: Colors.redAccent,
        // Potentially add a leading back button if not handled by Navigator automatically
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bloodRequests')
            .where('requesterId', isEqualTo: _currentUser!.uid)
            .orderBy(
            'timestamp', descending: true) // Show newest requests first
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}'); // Log the error
            return Center(
                child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You have not made any blood requests yet. '
                      'Go to the "Create Request" screen to make one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            );
          }

          // If we have data, build the list
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<
                  String,
                  dynamic>;
              String documentId = document.id; // Get the document ID

              // Basic display - we will improve this later and add delete
              return Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 4.0),
                elevation: 3.0,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Text(
                      data['bloodGroup'] ?? 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                  title: Text(
                    'Blood Group: ${data['bloodGroup']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location: ${data['location'] ?? 'Not specified'}'),
                      Text('Urgency: ${data['urgency'] ?? 'Not specified'}'),
                      if (data['timestamp'] != null)
                        Text(
                          'Requested: ${formatTimestamp(data['timestamp'])}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Delete Request',
                    onPressed: () {
                      _showDeleteConfirmationDialog(documentId); // Call the confirmation dialog
                    },
                  ),
                  // We will add a trailing delete icon/button in the next step
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  // You can use the intl package for more sophisticated formatting
  return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
}