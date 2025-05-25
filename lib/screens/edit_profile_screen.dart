import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // <--- ADD THIS IMPORT

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
  String? _selectedBloodGroup;
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

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
  final String _countryCode = "+971"; // <--- ADD COUNTRY CODE
  bool _showPhoneNumberZeroHint = false; // <--- ADD THIS STATE VARIABLE
  bool _isLoading = false;
  bool _isDonor = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.currentUserData['name'] as String? ?? '');
    _selectedBloodGroup = widget.currentUserData['bloodGroup'] as String?;
    if (_selectedBloodGroup != null &&
        !_bloodGroups.contains(_selectedBloodGroup)) {
      _selectedBloodGroup = null;
    }
    _isDonor = widget.currentUserData['isDonor'] as bool? ?? false;

    // Initialize phone number, stripping country code if present
    String initialPhoneNumber = widget.currentUserData['phoneNumber'] as String? ?? '';
    if (initialPhoneNumber.startsWith(_countryCode)) {
      initialPhoneNumber = initialPhoneNumber.substring(_countryCode.length);
    }
    _phoneNumberController = TextEditingController(text: initialPhoneNumber);


    _selectedEmirate = widget.currentUserData['emirate'] as String?;
    if (_selectedEmirate != null && !_emirates.contains(_selectedEmirate)) {
      _selectedEmirate = null;
    }
    if (_selectedEmirate == null &&
        widget.currentUserData.containsKey('location')) {
      String? potentialLocationAsEmirate =
      widget.currentUserData['location'] as String?;
      if (potentialLocationAsEmirate != null &&
          _emirates.contains(potentialLocationAsEmirate)) {
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

  Future<void> _saveProfileChanges() async {
    // --- START: HIDE HINT BEFORE VALIDATION ---
    if (_showPhoneNumberZeroHint) {
      setState(() {
        _showPhoneNumberZeroHint = false;
      });
    }
    // --- END: HIDE HINT BEFORE VALIDATION ---

    if (!_formKey.currentState!.validate()) {
      // --- START: RE-EVALUATE HINT VISIBILITY ON VALIDATION FAILURE ---
      final currentPhoneText = _phoneNumberController.text.trim();
      if (currentPhoneText.isNotEmpty && currentPhoneText.startsWith('0')) {
        if (!_showPhoneNumberZeroHint) {
          setState(() {
            _showPhoneNumberZeroHint = true;
          });
        }
      }
      // --- END: RE-EVALUATE HINT VISIBILITY ON VALIDATION FAILURE ---
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No user logged in. Please re-login.')),
          );
        }
        return;
      }
      String uid = currentUser.uid;

      // Validator ensures phone doesn't start with 0 and is 9 digits
      String enteredDigits = _phoneNumberController.text.trim();
      String fullPhoneNumber = _countryCode + enteredDigits;


      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'phoneNumber': fullPhoneNumber, // <--- SAVE FULL PHONE NUMBER
        'emirate': _selectedEmirate,
        'isDonor': _isDonor,
      };

      if (widget.currentUserData.containsKey('email')) {
        updatedData['email'] = widget.currentUserData['email'];
      }
      if (widget.currentUserData.containsKey('role')) {
        updatedData['role'] = widget.currentUserData['role'];
      }
      if (widget.currentUserData.containsKey('fcmToken')) {
        updatedData['fcmToken'] = widget.currentUserData['fcmToken'];
      }

      await _firestore.collection('users').doc(uid).update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
      print('Error updating profile: $e');
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
                value: _selectedBloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype),
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
                    return 'Please select your blood group';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              SwitchListTile(
                title: const Text('Available to Donate?'),
                subtitle: const Text(
                    'Make your profile visible to those seeking donors.'),
                value: _isDonor,
                onChanged: (bool value) {
                  setState(() {
                    _isDonor = value;
                  });
                },
                secondary:
                Icon(_isDonor ? Icons.visibility : Icons.visibility_off),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16.0),

              // --- MODIFIED PHONE NUMBER TextFormField ---
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration( // <--- REMOVE const
                  labelText: 'Phone Number',
                  hintText: '5X XXX XXXX (e.g., 501234567)', // <--- ADD HINT TEXT
                  border: OutlineInputBorder(),
                  prefixText: "$_countryCode ", // <--- ADD PREFIX TEXT
                  prefixStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // <--- ADD PREFIX STYLE
                  // prefixIcon: Icon(Icons.phone), // Prefix text and icon usually don't go well together, choose one.
                  // Using prefixText as per previous examples.
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [ // <--- ADD INPUT FORMATTERS
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                onChanged: (value) { // <--- ADD onChanged
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
                  final trimmedValue = value?.trim() ?? '';
                  if (trimmedValue.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (trimmedValue.length != 9) {
                    return 'Phone number must be 9 digits';
                  }
                  if (trimmedValue.startsWith('0')) {
                    return 'Do not start with 0 (e.g., $_countryCode 5xxxxxxxx)';
                  }
                  return null;
                },
              ),
              // --- Conditionally display the hint ---
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
              // --- END OF PHONE NUMBER MODIFICATIONS ---

              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedEmirate,
                decoration: const InputDecoration(
                  labelText: 'Emirate',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.public),
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
                    return 'Please select your Emirate';
                  }
                  return null;
                },
              ),
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

                  _saveProfileChanges();

                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}