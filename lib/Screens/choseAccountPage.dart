import 'package:flutter/material.dart';
import 'package:med_ad_admin/Screens/emp_loginPage.dart';
import 'package:med_ad_admin/Screens/loginpage.dart';

class Choseaccountpage extends StatelessWidget {
  const Choseaccountpage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryPurple = Colors.deepPurple[400]!;
    final secondaryPurple = Colors.deepPurple[200]!;
    final lightPurple = Colors.purple[100]!;

    return Scaffold(
      backgroundColor: lightPurple.withOpacity(0.3), // Soft purple background
      body: Center(
        child: Container(
          width: 400, // Slightly smaller for a more focused look
          padding: const EdgeInsets.all(40.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons full width
            children: <Widget>[
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: [primaryPurple, secondaryPurple],
                ).createShader(bounds),
                child: const Text(
                  'Select Account Type',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple, // Fallback color if shader fails
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Admin Access'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  
Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const pharmacist_login()),
                  );                },
                child: const Text('Pharmacist Access'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Dawaii Admin Portal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}