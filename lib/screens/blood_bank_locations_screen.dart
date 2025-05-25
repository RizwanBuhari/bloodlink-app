import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class BloodBank {
  final String id; // Document ID from Firestore
  final String name;
  final String address;
  final String emirate;
  final String phoneNumber;
  final String operatingHours;
  final String googleMapsLink;

  BloodBank({
    required this.id,
    required this.name,
    required this.address,
    required this.emirate,
    required this.phoneNumber,
    required this.operatingHours,
    required this.googleMapsLink,
  });

  factory BloodBank.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BloodBank(
      id: doc.id,
      name: data['name'] ?? 'N/A',
      address: data['address'] ?? 'N/A',
      emirate: data['emirate'] ?? 'N/A',
      phoneNumber: data['phoneNumber'] ?? 'N/A',
      operatingHours: data['operatingHours'] ?? 'N/A',
      googleMapsLink: data['googleMapsLink'] ?? '',
    );
  }
}

class BloodBankLocationsScreen extends StatefulWidget {
  const BloodBankLocationsScreen({super.key});

  @override
  State<BloodBankLocationsScreen> createState() =>
      _BloodBankLocationsScreenState();
}

class _BloodBankLocationsScreenState extends State<BloodBankLocationsScreen> {
  final Stream<QuerySnapshot> _allBloodBanksStream =
  FirebaseFirestore.instance.collection('bloodBanks').snapshots();
  late Stream<QuerySnapshot> _displayedBloodBanksStream;

  int _selectedFilterIndex = 0;
  List<bool> _isSelected = [true, false];

  String? _userEmirate;
  bool _isLoadingUserEmirate = true;

  // --- ADD FIREBASE AUTH INSTANCE ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _displayedBloodBanksStream = _allBloodBanksStream;
    _fetchUserEmirate(); // Call to fetch user's emirate
  }

  // --- MODIFIED _fetchUserEmirate METHOD ---
  Future<void> _fetchUserEmirate() async {
    if (mounted) {
      setState(() {
        _isLoadingUserEmirate = true;
      });
    }

    String? fetchedUserEmirate; // Variable to store the fetched emirate

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // User is logged in, try to get their emirate from Firestore
        final DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
            .collection('users') // Your users collection
            .doc(currentUser.uid) // Document ID is the user's UID
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data()!;
          // Assuming the field name for emirate in your 'users' collection is 'emirate'
          fetchedUserEmirate = userData['emirate'] as String?;
          if (fetchedUserEmirate != null) {
            print("User's emirate fetched successfully: $fetchedUserEmirate");
          } else {
            print("User's emirate field is null or not found in their document.");
          }
        } else {
          print(
              "User document not found in Firestore for UID: ${currentUser.uid}. Cannot determine emirate.");
        }
      } else {
        // No user is logged in
        print(
            "No user logged in. 'Nearby' filter will likely show all or no results based on handling.");
      }
    } catch (e) {
      print("Error fetching user emirate: $e");
      // Optionally, show a generic error to the user or handle differently
      if (mounted) {
        // You could show a snackbar here if desired, but for now, just logging
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Could not load your location data.')),
        // );
      }
    }

    if (mounted) {
      setState(() {
        _userEmirate = fetchedUserEmirate; // Store the fetched (or null) emirate
        _isLoadingUserEmirate = false; // Set loading state to false
        // Important: Apply filter after user emirate is fetched (or determined to be unavailable)
        // This ensures that if "Nearby" is pre-selected or becomes selected,
        // it uses the most up-to-date _userEmirate.
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    if (!mounted) return; // Prevent calling setState on unmounted widget

    Stream<QuerySnapshot> newStream;
    if (_selectedFilterIndex == 0) {
      // "All"
      newStream = _allBloodBanksStream;
    } else {
      // "Nearby"
      if (_userEmirate != null && _userEmirate!.isNotEmpty) {
        print("Applying 'Nearby' filter for emirate: $_userEmirate");
        newStream = _firestore // Use the instance variable for Firestore
            .collection('bloodBanks')
            .where('emirate', isEqualTo: _userEmirate)
            .snapshots();
      } else {
        // User emirate not available or user not logged in,
        // For "Nearby", we might show nothing or all.
        // Current logic shows a message in StreamBuilder.
        // Let's ensure the stream doesn't accidentally show "All" if userEmirate is null for "Nearby"
        // by providing an empty stream or a stream that explicitly yields no results.
        // However, the UI already handles showing a message, so keeping it as _allBloodBanksStream
        // if user emirate is null still makes some sense as a fallback,
        // but the message "Your emirate is not available..." is more user-friendly.

        // If you want "Nearby" to show *nothing* if emirate is not available:
        // newStream = Stream.empty();

        // If you want "Nearby" to default to "All" (with a console message):
        print(
            "User emirate not available for 'Nearby' filter. Consider logging in or updating profile. Defaulting to show all for now in background, but UI should show message.");
        newStream = _allBloodBanksStream; // Or handle as an empty list in UI
      }
    }

    // Only call setState if the stream has actually changed to avoid unnecessary rebuilds
    if (_displayedBloodBanksStream != newStream) {
      setState(() {
        _displayedBloodBanksStream = newStream;
      });
    } else if (_selectedFilterIndex == 1 && _userEmirate == null && !_isLoadingUserEmirate) {
      // Special case: if "Nearby" is selected, user emirate is loaded and is null,
      // force a rebuild so the StreamBuilder shows the "emirate not available" message.
      setState(() {});
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      print('Could not launch $urlString');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map: Invalid URL')),
        );
      }
      return;
    }
    await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Bank Locations'),
        backgroundColor: Colors.red[700],
        // --- OPTIONAL: Add a refresh button for testing/manual refresh of user emirate ---
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.refresh),
        //     onPressed: () {
        //       print("Manual refresh triggered for _fetchUserEmirate");
        //      _fetchUserEmirate();
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              isSelected: _isSelected,
              onPressed: (int index) {
                if (!mounted) return;
                setState(() {
                  _selectedFilterIndex = index;
                  for (int i = 0; i < _isSelected.length; i++) {
                    _isSelected[i] = i == index;
                  }
                  // When toggle button is pressed, always re-apply the filter.
                  // _fetchUserEmirate is NOT called here again, it relies on the
                  // _userEmirate already fetched during initState or manual refresh.
                  _applyFilter();
                });
              },
              borderRadius: BorderRadius.circular(8.0),
              selectedBorderColor: Colors.red[700],
              selectedColor: Colors.white,
              fillColor: Colors.red[400],
              color: Colors.red[400],
              constraints: BoxConstraints(
                minHeight: 40.0,
                minWidth: (MediaQuery.of(context).size.width - 32) / 2,
              ),
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('All'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Nearby'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _displayedBloodBanksStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }

                // --- MODIFIED LOADING LOGIC ---
                // 1. If "Nearby" is selected AND we are actively loading user's emirate:
                if (_selectedFilterIndex == 1 && _isLoadingUserEmirate) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Loading your location for 'Nearby' filter..."),
                        SizedBox(height: 10),
                        CircularProgressIndicator(),
                      ],
                    ),
                  );
                }

                // 2. Generic stream loading (data for blood banks is loading)
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 3. Handle No Data or User Emirate Not Available for "Nearby"
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  // If "Nearby" is selected, user emirate loading is done, but it's null/empty
                  if (_selectedFilterIndex == 1 &&
                      (_userEmirate == null || _userEmirate!.isEmpty) &&
                      !_isLoadingUserEmirate) {
                    return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Your emirate is not available to filter by "Nearby". Please update your profile or ensure you are logged in. You can select "All" to see all locations.',
                            textAlign: TextAlign.center,
                          ),
                        ));
                  }
                  // Generic "No blood banks found" (applies to "All" or "Nearby" if filter yields no results)
                  return const Center(child: Text('No blood banks found.'));
                }

                // 4. If Data Exists, Display it
                return ListView(
                  children:
                  snapshot.data!.docs.map((DocumentSnapshot document) {
                    BloodBank bloodBank = BloodBank.fromFirestore(document);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        title: Text(bloodBank.name),
                        subtitle: Text('${bloodBank.address}\n'
                            'Hours: ${bloodBank.operatingHours}\n'
                            'Phone: ${bloodBank.phoneNumber}'),
                        isThreeLine: true,
                        onTap: () {
                          if (bloodBank.googleMapsLink.isNotEmpty) {
                            _launchURL(bloodBank.googleMapsLink);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Map link is not available.')),
                              );
                            }
                            print(
                                'Google Maps link is empty for ${bloodBank.name}');
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}