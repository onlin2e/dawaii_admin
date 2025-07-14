import 'package:flutter/material.dart';
import 'package:med_ad_admin/Screens/choseAccountPage.dart';
// import 'package:med_ad_admin/Screens/homescreen.dart';
import 'package:med_ad_admin/Screens/loginpage.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Choseaccountpage(),
    );
  }
}