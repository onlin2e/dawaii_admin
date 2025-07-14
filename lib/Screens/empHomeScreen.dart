import 'package:flutter/material.dart';
import 'package:med_ad_admin/Screens/MedicinesPage.dart';
// import 'package:med_ad_admin/Screens/PatientsPage.dart';
import 'package:med_ad_admin/Screens/choseaccountpage.dart';
import 'package:med_ad_admin/Screens/emp_PatientPage.dart'; // استيراد صفحة Choseaccountpage

class PharmacistHomeScreen extends StatefulWidget {
  const PharmacistHomeScreen({super.key});

  @override
  State<PharmacistHomeScreen> createState() => _PharmacistHomeScreenState();
}

class _PharmacistHomeScreenState extends State<PharmacistHomeScreen> {
  bool isCollapsed = false;
  int currentIndex = 0;

  final List<String> pageTitles = [
    "Patients",
    "Medicines",
  ];

  final List<IconData> pageIcons = [
    Icons.people,
    Icons.medication,
  ];

  final List<Widget> pages = [
    EmpPatientpage(),
    MedicinesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: isCollapsed ? 70 : 250,
            color: Colors.blueGrey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Center(
                  child: IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isCollapsed = !isCollapsed;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: isCollapsed
                      ? null
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Dashboard",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text("Pharmacist Panel",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                ),
                Divider(color: Colors.white54),
                // Navigation Items
                ...List.generate(pageTitles.length, (index) {
                  return _buildNavItem(pageIcons[index], pageTitles[index], index);
                }),
                Spacer(), // لإبعاد زر تسجيل الخروج إلى الأسفل
                Divider(color: Colors.white54),
                _buildLogoutItem(context), // إضافة زر تسجيل الخروج
                SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    bool isSelected = currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.white),
      title: isCollapsed
          ? null
          : Text(title,
              style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      tileColor: isSelected ? Colors.white24 : Colors.transparent,
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.white),
      title: isCollapsed
          ? null
          : Text("Logout", style: TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Choseaccountpage()),
        );
      },
    );
  }
}