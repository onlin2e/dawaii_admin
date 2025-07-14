import 'package:flutter/material.dart';
import 'package:med_ad_admin/Screens/AddPatientPage.dart';
import 'package:med_ad_admin/Screens/MedicinesPage.dart';
import 'package:med_ad_admin/Screens/NotificationsPage.dart';
import 'package:med_ad_admin/Screens/PatientsPage.dart';
import 'package:med_ad_admin/Screens/SettingsPage.dart';
import 'package:med_ad_admin/Screens/choseaccountpage.dart'; // استيراد صفحة Choseaccountpage
import 'package:med_ad_admin/Screens/Allnotificationpage.dart'; // استيراد صفحة Allnotificationpage

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isCollapsed = false;
  int currentIndex = 0;

  // إضافة Allnotificationpage إلى القوائم
  final List<String> pageTitles = [
    "Patients",
    "Notifications",
    "All Notifications", // عنوان صفحة Allnotificationpage
    "Medicines",
    "Add Patient",
    "Settings"
  ];

  final List<IconData> pageIcons = [
    Icons.people,
    Icons.notifications,
    Icons.notifications_active, // أيقونة صفحة Allnotificationpage
    Icons.medication,
    Icons.person_add,
    Icons.settings
  ];

  final List<Widget> pages = [
    Patientspage(),
    NotificationsPage(),
    Allnotificationpage(), // إضافة صفحة Allnotificationpage
    MedicinesPage(),
    AddPatientPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCollapsed ? 70 : 250,
            color: Colors.blueGrey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isCollapsed = !isCollapsed;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: isCollapsed
                      ? null
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Dashboard",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            const Text("Welcome, ",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                ),
                const Divider(color: Colors.white54),
                // Navigation Items
                ...List.generate(pageTitles.length, (index) {
                  return buildNavItem(pageIcons[index], pageTitles[index], index);
                }),
                const Spacer(), // لإبعاد زر تسجيل الخروج إلى الأسفل
                const Divider(color: Colors.white54),
                buildLogoutItem(context), // إضافة زر تسجيل الخروج
                const SizedBox(height: 20),
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

  Widget buildNavItem(IconData icon, String title, int index) {
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

  Widget buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.white),
      title: isCollapsed
          ? null
          : const Text("Logout", style: TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Choseaccountpage()),
        );
      },
    );
  }
}
