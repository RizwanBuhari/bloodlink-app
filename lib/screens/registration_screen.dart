import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedBloodGroup;
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  final List<String> _emirates = [
    'Abu Dhabi', 'Dubai', 'Sharjah', 'Umm Al Quwain',
    'Fujairah', 'Ajman', 'Ras Al Khaimah',
  ];
  String? _selectedEmirate;

  final TextEditingController _phoneController = TextEditingController();
  final String _countryCode = "+971";
  bool _showPhoneNumberZeroHint = false; // <--- ADD THIS STATE VARIABLE

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register for BloodLink'),
        backgroundColor: Colors.red[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // ... (other TextFormFields for email, password, name, blood group remain the same) ...
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20), // Spacer

              // Password TextFormField
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Name TextFormField
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                value: _selectedBloodGroup,
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
              const SizedBox(height: 20),

              // --- MODIFIED PHONE NUMBER TextFormField ---
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number', // Assuming it's mandatory
                  hintText: '5X XXX XXXX (e.g., 501234567)', // More specific hint
                  prefixText: "$_countryCode ",
                  prefixStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length != 9) {
                    return 'Phone number must be 9 digits';
                  }
                  if (value.startsWith('0')) {
                    // This validation message will show if the form is submitted
                    // while the input starts with '0'.
                    return 'Do not start with 0 (e.g., $_countryCode 5xxxxxxxx)';
                  }
                  return null;
                },
              ),
              // --- Conditionally display the hint ---
              if (_showPhoneNumberZeroHint)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0), // You can adjust padding
                  child: Text(
                    'Do not start with 0 (e.g., $_countryCode 5xxxxxxxx)',
                    style: TextStyle(
                      color: Colors.red[700], // Example color, adjust as needed
                      fontSize: 12.0,
                    ),
                  ),
                ),
              // --- END OF PHONE NUMBER MODIFICATIONS ---

              const SizedBox(height: 20), // Adjusted spacing slightly for the new hint
              // ... (Dropdown for Emirate remains the same) ...
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Emirate',
                  prefixIcon: Icon(Icons.location_city), // Keeping a similar icon
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                value: _selectedEmirate,
                hint: const Text('Select your Emirate'),
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

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async {
                  // --- START OF ORIGINAL onPressed LOGIC ---
                  if (!mounted) return;

                  // Hide hint explicitly when trying to submit, validator handles error display
                  if (_showPhoneNumberZeroHint) {
                    setState(() {
                      _showPhoneNumberZeroHint = false;
                    });
                  }

                  if (_formKey.currentState!.validate()) {
                    try {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registering User...'),
                          duration: Duration(seconds: 30),
                        ),
                      );

                      UserCredential userCredential =
                      await _auth.createUserWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );

                      if (!mounted) return;
                      User? newUser = userCredential.user;

                      if (newUser != null) {
                        String enteredDigits = _phoneController.text.trim();
                        // Validator should have already ensured it's 9 digits and doesn't start with '0'
                        String fullPhoneNumber = _countryCode + enteredDigits;

                        await _firestore.collection('users').doc(newUser.uid).set({
                          'uid': newUser.uid,
                          'name': _nameController.text.trim(),
                          'email': newUser.email,
                          'bloodGroup': _selectedBloodGroup,
                          'phoneNumber': fullPhoneNumber,
                          'emirate': _selectedEmirate,
                          'createdAt': Timestamp.now(),
                        });
                        print(
                            'User data saved to Firestore. Phone: $fullPhoneNumber');
                      } else {
                        print('User object was null after creation.');
                      }

                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registration Successful! Welcome!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      await Future.delayed(const Duration(seconds: 2));

                      if (!mounted) return;
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                      // If you intend to navigate to HomeScreen after successful registration and pop,
                      // you might want to pushReplacement to avoid users going back to registration.
                      // Example:
                      // Navigator.of(context).pushReplacement(
                      //   MaterialPageRoute(builder: (context) => const HomeScreen()),
                      // );
                    } on FirebaseAuthException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      String errorMessage;
                      if (e.code == 'weak-password') {
                        errorMessage = 'The password provided is too weak.';
                      } else if (e.code == 'email-already-in-use') {
                        errorMessage =
                        'An account already exists for that email.';
                      } else if (e.code == 'invalid-email') {
                        errorMessage = 'The email address is not valid.';
                      } else {
                        errorMessage =
                        'Registration failed. Error: ${e.message}';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.redAccent),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'An unexpected error occurred. Please try again.'),
                            backgroundColor: Colors.redAccent),
                      );
                    }
                  } else {
                    // If validation fails, re-check if the hint needs to be displayed based on current input
                    final currentPhoneText = _phoneController.text;
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

                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}