import 'package:flutter/material.dart';
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
  //final TextEditingController _bloodGroupController = TextEditingController();
  String? _selectedBloodGroup; // For storing the selected dropdown value
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

  final TextEditingController _phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();

    _phoneController.dispose();
    //_bloodGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register for BloodLink'),
        backgroundColor: Colors.red[700],
      ),
      body: Padding( // MODIFICATION STARTS HERE
        padding: const EdgeInsets.all(16.0), // Add some padding around the form
        child: Form(
          key: _formKey, // Assign the form key
          child: ListView( // Use ListView to prevent overflow with keyboard
            children: <Widget>[
              const SizedBox(height: 20), // Spacer

              // Email TextFormField
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
                  return null; // Return null if the input is valid
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
                  // We'll add an icon to show/hide password later
                ),
                obscureText: true, // Hides the password text
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null; // Return null if the input is valid
                },
              ),
              const SizedBox(height: 20), // Spacer before Name field

              // Name TextFormField
              TextFormField(
                controller: _nameController, // Use the controller defined earlier
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

              const SizedBox(height: 20), // Spacer between Name and Blood Group

              // Blood Group TextFormField
              // Blood Group DropdownFormField
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                value: _selectedBloodGroup, // Uses the new state variable
                hint: const Text('Select Blood Group'),
                isExpanded: true,
                items: _bloodGroups.map((String group) { // Uses the new list of blood groups
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
              const SizedBox(height: 20), // Spacer (existing or add if needed)

              TextFormField(
                controller: _phoneController, // Use the controller declared in Step 12.1
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  // Basic validation: if not empty, check if it looks like a phone number.
                  // This is a very simple check, consider a more robust one for production.
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 7 || !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$').hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                  }
                  return null; // Null means no error (phone is optional or valid)
                },
              ),

              const SizedBox(height: 30),

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
                  backgroundColor: Colors.red[700], // Button background color
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async{
                  if (!mounted) return;
                  if (_formKey.currentState!.validate()) {
                    // Form is valid, proceed with Firebase registration
                    try {
                      // Clear any previous snackbars and show a loading indicator
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registering User...'),
                          duration: Duration(seconds: 30), // Keep it visible during the network request
                        ),
                      );

                      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
                        email: _emailController.text.trim(), // Use .trim() to remove leading/trailing whitespace
                        password: _passwordController.text.trim(),
                      );

                      if (!mounted) return;
                      User? newUser = userCredential.user; // Get the new user

                      if (newUser != null) { // Ensure user is not null
                        String phoneNumber = _phoneController.text.trim();

                        await _firestore.collection('users').doc(newUser.uid).set({
                          'uid': newUser.uid,
                          'name': _nameController.text.trim(),
                          'email': newUser.email, // Store email for convenience
                          'bloodGroup': _selectedBloodGroup,
                          'phoneNumber': phoneNumber.isNotEmpty ? phoneNumber : '', // Store empty string if not provided
                          'emirate': _selectedEmirate,
                          'createdAt': Timestamp.now(), // Good practice to store creation time
                        });

                        print('User data saved to Firestore with phone and emirate for UID: ${newUser.uid}');                        // Handle case where user is null after creation (should be rare)
                        print('User object was null after creation.');
                        // You might want to show an error message to the user here
                        // and potentially prevent further execution or navigation.
                      }

                      // The original print statement for successful registration can now be moved
                      // or removed if the new print statement 'User data saved to Firestore...' is sufficient.
                      // For example, you can remove or comment out:
                      // print('Successfully registered user: ${userCredential.user?.uid}');

                      // If registration is successful, userCredential will not be null
                      print('Successfully registered user: ${userCredential.user?.uid}');
                      ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove "Registering User..." snackbar

                      // Show success SnackBar BRIEFLY before navigating
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar( // Made it const
                          content: Text('Registration Successful! Welcome!'),
                          duration: Duration(seconds: 2), // Short duration
                        ),
                      );
                      await Future.delayed(const Duration(seconds: 2)); // Made it const

                      if (!mounted) return; // Check mounted status again before navigation

                      // Navigate to the HomeScreen and remove the RegistrationScreen from the stack
                      /*Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const HomeScreen()), // Made it const
                      );*/
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }


                    } on FirebaseAuthException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove "Registering User..." snackbar

                      String errorMessage;
                      if (e.code == 'weak-password') {
                        errorMessage = 'The password provided is too weak.';
                      } else if (e.code == 'email-already-in-use') {
                        errorMessage = 'An account already exists for that email.';
                      } else if (e.code == 'invalid-email') {
                        errorMessage = 'The email address is not valid.';
                      } else {
                        errorMessage = 'Registration failed. Error: ${e.message}'; // Display Firebase's detailed message
                      }

                      print('Firebase Auth Exception (${e.code}): ${e.message}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(errorMessage), backgroundColor: Colors.redAccent),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove "Registering User..." snackbar

                      print('Generic Error during registration: ${e.toString()}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('An unexpected error occurred. Please try again.'),
                            backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                child: const Text('Register'),
              ), // <-- Make sure there's a comma here if you plan to add more widgets below
            ],
          ),
        ),
      ), // MODIFICATION ENDS HERE
    );
  }
}