import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:med_ad_admin/Screens/empHomeScreen.dart';
// import 'package:med_ad_admin/Screens/homescreen.dart';

class pharmacist_login extends StatefulWidget {
  const pharmacist_login({super.key});

  @override
  State<pharmacist_login> createState() => _pharmacist_loginState();
}

class _pharmacist_loginState extends State<pharmacist_login> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('emp').get();

      for (var doc in querySnapshot.docs) {
        String storedUsername = doc['userName'];
        String storedPassword = doc['password'];

        if (_usernameController.text == storedUsername &&
            _passwordController.text == storedPassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PharmacistHomeScreen()),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid username or password')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 106, 31, 217)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Center(
            child: Container(
              width: screenWidth * 0.4,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome Pharmacist!',
                      style: TextStyle(
                        color: Color.fromARGB(255, 11, 165, 142),
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Log in to continue',
                      style: TextStyle(
                        color: Color.fromARGB(255, 11, 165, 142),
                        fontSize: screenWidth * 0.02,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: 'Enter Username',
                        prefixIcon: Icon(Icons.person, color: Color.fromARGB(255, 11, 165, 142)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Color.fromARGB(255, 11, 165, 142)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: 'Enter Password',
                        prefixIcon: Icon(Icons.lock, color: Color.fromARGB(255, 11, 165, 142)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Color.fromARGB(255, 11, 165, 142)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 106, 31, 217),
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: screenHeight * 0.02,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}