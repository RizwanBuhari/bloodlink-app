import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientDetailsController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedUrgency;
  final List<String> _urgencyLevels = ['Urgent', 'Within 24 hours', 'Within 3 days', 'Flexible'];
  String? _selectedBloodGroup;
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _emirates = const [
    'Abu Dhabi', 'Dubai', 'Sharjah', 'Umm Al Quwain', 'Fujairah', 'Ajman', 'Ras Al Khaimah',
  ];
  String? _selectedRequestEmirate;
  Map<String, dynamic>? _currentUserProfileData;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserProfileAndSetEmirate();
  }

  Future<void> _fetchCurrentUserProfileAndSetEmirate() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
        if (mounted) {
          if (userDoc.exists) {
            _currentUserProfileData = userDoc.data();
            if (_currentUserProfileData != null && _currentUserProfileData!['emirate'] != null) {
              final String userEmirate = _currentUserProfileData!['emirate'] as String;
              if (_emirates.contains(userEmirate)) {
                setState(() {
                  _selectedRequestEmirate = userEmirate;
                });
              }
            }
          } else {
            print("User profile not found in Firestore for UID: ${currentUser.uid}");
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching your profile: ${e.toString()}')),
          );
        }
        print("Error fetching user profile for request form: $e");
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No user logged in.')),
        );
      }
      print("No current user to fetch profile from for the request form.");
    }
    if (mounted) {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  @override
  void dispose() {
    _patientDetailsController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: No user logged in. Please login again.'),
                backgroundColor: Colors.red),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      try {
        Map<String, dynamic> requestData = {
          'requesterId': currentUser.uid,
          'requesterName': currentUser.displayName ?? 'N/A',
          'requesterEmail': currentUser.email,
          'bloodGroup': _selectedBloodGroup,
          'location': _selectedRequestEmirate,
          'urgency': _selectedUrgency,
          'patientDetails': _patientDetailsController.text.trim().isEmpty
              ? null
              : _patientDetailsController.text.trim(),
          'contactPerson': _contactPersonController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'active',
        };

        await _firestore.collection('bloodRequests').add(requestData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Blood request submitted successfully!'),
                backgroundColor: Colors.green),
          );
          _formKey.currentState?.reset();
          _patientDetailsController.clear();
          _contactPersonController.clear();
          _contactPhoneController.clear();
          _notesController.clear();
          setState(() {
            _selectedUrgency = null;
            _selectedBloodGroup = null;
            _selectedRequestEmirate = null; // Will be re-fetched by initState if user stays
            // or if you call _fetchCurrentUserProfileAndSetEmirate() again.
            // For now, null is fine.
          });
        }
      } catch (e) {
        print("Error submitting blood request: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to submit request. Please try again. Error: ${e.toString()}'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
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
        title: const Text('Create Blood Request'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group Needed',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
                hint: const Text('Select Blood Group'),
                isExpanded: true,
                items: _bloodGroups.map((String group) {
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBloodGroup = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the blood group';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // VVVV CORRECTED SECTION FOR EMIRATE DROPDOWN VVVV
              if (_isLoadingUserData)
                Padding( // No semicolon here if it's part of collection-if
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      SizedBox(width: 15),
                      Text("Loading user's Emirate..."),
                    ],
                  ),
                ) // No semicolon here
              else
                DropdownButtonFormField<String>( // No semicolon here
                  value: _selectedRequestEmirate,
                  decoration: const InputDecoration(
                    labelText: 'Emirate (for blood request)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  hint: const Text('Select Emirate'),
                  isExpanded: true,
                  items: _emirates.map((String emirate) {
                    return DropdownMenuItem<String>(
                      value: emirate,
                      child: Text(emirate),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRequestEmirate = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the Emirate for the request';
                    }
                    return null;
                  },
                ), // <<< ADDED A COMMA HERE, as it's followed by SizedBox
              // ^^^^ END OF CORRECTED SECTION ^^^^

              const SizedBox(height: 16.0), // This was the line with "Expected to find ','"

              DropdownButtonFormField<String>(
                value: _selectedUrgency,
                decoration: const InputDecoration(
                  labelText: 'Urgency Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high_outlined),
                ),
                hint: const Text('Select Urgency'),
                isExpanded: true,
                items: _urgencyLevels.map((String level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUrgency = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the urgency level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _patientDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name / Details (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the contact person\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the contact phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30.0),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.send_outlined),
                label: const Text('Submit Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  textStyle: const TextStyle(fontSize: 16.0),
                ),
                onPressed: _submitRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}