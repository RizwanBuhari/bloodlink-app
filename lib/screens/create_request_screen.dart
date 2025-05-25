import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientDetailsController =
  TextEditingController();
  final TextEditingController _contactPersonController =
  TextEditingController();
  final TextEditingController _contactPhoneController =
  TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedUrgency;
  final List<String> _urgencyLevels = [
    'Urgent',
    'Within 24 hours',
    'Within 3 days',
    'Flexible'
  ];
  String? _selectedBloodGroup;
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _emirates = const [
    'Abu Dhabi', 'Dubai', 'Sharjah', 'Umm Al Quwain',
    'Fujairah', 'Ajman', 'Ras Al Khaimah',
  ];
  String? _selectedRequestEmirate;
  Map<String, dynamic>? _currentUserProfileData; // To store fetched user data
  bool _isLoadingUserData = true;

  final String _countryCode = "+971";
  bool _showPhoneNumberZeroHint = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserProfileAndSetEmirate();
  }

  // --- DEFINITION FOR _fetchCurrentUserProfileAndSetEmirate ---
  Future<void> _fetchCurrentUserProfileAndSetEmirate() async {
    if (!mounted) return; // Check if the widget is still in the tree
    setState(() {
      _isLoadingUserData = true;
    });

    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          _currentUserProfileData = userDoc.data() as Map<String, dynamic>;
          // Assuming 'emirate' is the field name in your user profile document
          // and it stores one of the strings from the _emirates list.
          final String? defaultEmirate = _currentUserProfileData!['emirate'];
          if (defaultEmirate != null && _emirates.contains(defaultEmirate)) {
            if (mounted) { // Check mounted again before calling setState
              setState(() {
                _selectedRequestEmirate = defaultEmirate;
              });
            }
          }
        }
      } catch (e) {
        // It's good practice to catch potential errors during async operations
        print("Error fetching user profile for emirate prefill: $e");
        // Optionally, you could show a SnackBar to the user
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(content: Text('Could not load your default emirate.')),
        //   );
        // }
      }
    }

    if (mounted) { // Ensure widget is still mounted before final setState
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }
  // --- END OF _fetchCurrentUserProfileAndSetEmirate DEFINITION ---

  @override
  void dispose() {
    _patientDetailsController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!mounted) return;
    setState(() {
      _showPhoneNumberZeroHint = false;
    });

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
        String enteredDigits = _contactPhoneController.text.trim();
        String fullContactPhoneNumber = _countryCode + enteredDigits;

        // Attempt to get user's name from profile if Firebase display name is null
        String requesterName = currentUser.displayName ?? _currentUserProfileData?['name'] ?? 'N/A';
        if (requesterName == 'N/A' && _currentUserProfileData != null && _currentUserProfileData!['fullName'] != null) {
          requesterName = _currentUserProfileData!['fullName']; // Or whatever your name field is in profiles
        }


        Map<String, dynamic> requestData = {
          'requesterId': currentUser.uid,
          'requesterName': requesterName,
          'requesterEmail': currentUser.email,
          'bloodGroup': _selectedBloodGroup,
          'location': _selectedRequestEmirate,
          'urgency': _selectedUrgency,
          'patientDetails': _patientDetailsController.text.trim().isEmpty
              ? null
              : _patientDetailsController.text.trim(),
          'contactPerson': _contactPersonController.text.trim(),
          'contactPhone': fullContactPhoneNumber,
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
            // _selectedRequestEmirate will be reset if you call _fetchCurrentUserProfileAndSetEmirate() again
            // or you can set it to null if that's the desired behavior after submission
            // _selectedRequestEmirate = null; // Uncomment if you want to clear it fully
          });
          // Optionally re-fetch to set default emirate again, or clear it
          _fetchCurrentUserProfileAndSetEmirate(); // To reset to default or keep it based on fetched data
        }
      } catch (e) {
        print("Error submitting blood request: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to submit request. Please try again. Error: ${e.toString().substring(0, (e.toString().length > 100 ? 100 : e.toString().length))}...'), // Truncate long errors
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
      // If validation fails, check phone hint condition
      final currentPhoneText = _contactPhoneController.text;
      if (currentPhoneText.isNotEmpty && currentPhoneText.startsWith('0')) {
        if (!_showPhoneNumberZeroHint) {
          setState(() {
            _showPhoneNumberZeroHint = true;
          });
        }
      } else {
        if (_showPhoneNumberZeroHint) {
          setState(() {
            _showPhoneNumberZeroHint = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Blood Request'),
        backgroundColor: Colors.redAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                decoration: InputDecoration(
                  labelText: 'Blood Group Needed',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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

              if (_isLoadingUserData)
                Padding(
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
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedRequestEmirate,
                  decoration: InputDecoration(
                    labelText: 'Emirate (for blood request)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                ),
              const SizedBox(height: 16.0),

              DropdownButtonFormField<String>(
                value: _selectedUrgency,
                decoration: InputDecoration(
                  labelText: 'Urgency Level',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                decoration: InputDecoration(
                  labelText: 'Patient Name / Details (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _contactPersonController,
                decoration: InputDecoration(
                  labelText: 'Contact Person Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                decoration: InputDecoration(
                  labelText: 'Contact Phone Number',
                  hintText: '5X XXX XXXX (e.g., 501234567)',
                  prefixText: "$_countryCode ",
                  prefixStyle: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                onChanged: (value) {
                  if (value.isNotEmpty && value.startsWith('0')) {
                    if (!_showPhoneNumberZeroHint) {
                      setState(() {
                        _showPhoneNumberZeroHint = true;
                      });
                    }
                  } else {
                    if (_showPhoneNumberZeroHint) {
                      setState(() {
                        _showPhoneNumberZeroHint = false;
                      });
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the contact phone number';
                  }
                  if (value.trim().length != 9) {
                    return 'Phone number must be 9 digits';
                  }
                  if (value.trim().startsWith('0')) {
                    return 'Number should not start with 0 (e.g., enter 50... not 050...)';
                  }
                  return null;
                },
              ),
              if (_showPhoneNumberZeroHint)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    'Do not start with 0 (e.g., $_countryCode 5xxxxxxxx)',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12.0,
                    ),
                  ),
                ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)
                    )
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