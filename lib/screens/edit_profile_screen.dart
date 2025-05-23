// lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
// VVVV ADD THESE IMPORTS VVVV
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ^^^^ END OF IMPORTS ^^^^

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentUserData;

  const EditProfileScreen({
    super.key,
    required this.currentUserData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedBloodGroup; // ADDED
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final List<String> _emirates = [
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Umm Al Quwain',
    'Fujairah',
    'Ajman',
    'Ras Al Khaimah',
  ];

  String? _selectedEmirate;

  late TextEditingController _phoneNumberController;
  bool _isLoading = false;
  bool _isDonor = false;


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ^^^^ END OF FIREBASE INSTANCES ^^^^

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUserData['name'] as String? ?? '');
    _selectedBloodGroup = widget.currentUserData['bloodGroup'] as String?;
    // This next part is a safety check:
    // If a blood group was stored, but it's not in our valid list (_bloodGroups),
    // then we shouldn't try to select it in the dropdown. So, we set it to null.
    if (_selectedBloodGroup != null && !_bloodGroups.contains(_selectedBloodGroup)) {
      _selectedBloodGroup = null;
    }
    _isDonor = widget.currentUserData['isDonor'] as bool? ?? false; // <<< ADD THIS LINE
    _phoneNumberController = TextEditingController(text: widget.currentUserData['phoneNumber'] as String? ?? '');

    _selectedEmirate = widget.currentUserData['emirate'] as String?;
    // Safety check: if the saved emirate isn't in our list, clear it
    if (_selectedEmirate != null && !_emirates.contains(_selectedEmirate)) {
      _selectedEmirate = null;
    }
    // Fallback: If 'emirate' is null or not found, AND 'location' exists,
    // AND 'location' is one of the valid emirates, then use 'location'.
    // This helps with migrating users who only had 'location' set to an emirate name.
    if (_selectedEmirate == null && widget.currentUserData.containsKey('location')) {
      String? potentialLocationAsEmirate = widget.currentUserData['location'] as String?;
      if (potentialLocationAsEmirate != null && _emirates.contains(potentialLocationAsEmirate)) {
        _selectedEmirate = potentialLocationAsEmirate;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

// lib/screens/edit_profile_screen.dart
// ... (imports, class definition, initState, dispose, build method etc. all remain the same)

  // VVVV MODIFY THIS METHOD VVVV
  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) {
      return; // Validation failed, do not proceed.
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in. Please re-login.')),
          );
        }
        return; // Exit if no user
      }
      String uid = currentUser.uid;

      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'bloodGroup': _selectedBloodGroup, // Use the state variable
        'phoneNumber': _phoneNumberController.text.trim(),
        'emirate': _selectedEmirate,
        'isDonor': _isDonor,
        // 'email': currentUser.email, // Email is usually part of auth, not directly in this map unless you need it duplicated
        // 'role': widget.currentUserData['role'], // Keep existing role
        // Or if you have a field for it: _roleController.text
      };

      // Ensure 'role' and 'email' are preserved if they exist in the original data
      // and are not meant to be changed by this form.
      // This is important if your Firestore document has more fields than the form.
      if (widget.currentUserData.containsKey('email')) {
        updatedData['email'] = widget.currentUserData['email'];
      }
      if (widget.currentUserData.containsKey('role')) {
        updatedData['role'] = widget.currentUserData['role'];
      }
      // Also preserve fcmToken if it exists
      if (widget.currentUserData.containsKey('fcmToken')) {
        updatedData['fcmToken'] = widget.currentUserData['fcmToken'];
      }


      await _firestore.collection('users').doc(uid).update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop(); // Go back to profile screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
      print('Error updating profile: $e');
    } finally {
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // ^^^^ END OF MODIFIED METHOD ^^^^

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... TextFormField widgets remain the same ...
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup, // Use the state variable
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                hint: const Text('Select Blood Group'), // Shows when no value is selected
                isExpanded: true, // Makes the dropdown take the full width
                items: _bloodGroups.map((String group) { // Populate items from your _bloodGroups list
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() { // Update the state when a new value is selected
                    _selectedBloodGroup = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your blood group';
                  }
                  return null;
                },
              ),
              // ^^^^ END OF DropdownButtonFormField FOR BLOOD GROUP ^^^^

              const SizedBox(height: 16.0), // Spacing

              // VVVV ADD SwitchListTile FOR isDonor VVVV
              SwitchListTile(
                title: const Text('Available to Donate?'),
                subtitle: const Text('Make your profile visible to those seeking donors.'),
                value: _isDonor, // Bind to the _isDonor state variable
                onChanged: (bool value) {
                  setState(() { // Update the state when the switch is toggled
                    _isDonor = value;
                  });
                },
                secondary: Icon(_isDonor ? Icons.visibility : Icons.visibility_off), // Optional: change icon based on state
                activeColor: Theme.of(context).colorScheme.primary, // Optional: for styling
              ),

              const SizedBox(height: 16.0),

              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedEmirate,
                decoration: const InputDecoration(
                  labelText: 'Emirate', // Changed label
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.public), // Changed icon, e.g., public or map
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
                    _selectedEmirate = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your Emirate'; // Updated validation message
                  }
                  return null;
                },
              ),
// ^^^^ END OF DropdownButtonFormField ^^^^
              const SizedBox(height: 30.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  textStyle: const TextStyle(fontSize: 16.0),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // VVVV CALL THE NEW METHOD VVVV
                    _saveProfileChanges();
                    // ^^^^ RATHER THAN JUST SHOWING A SNACKBAR ^^^^
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please correct the errors.')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}