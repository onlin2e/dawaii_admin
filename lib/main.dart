import 'package:flutter/material.dart';
import 'package:med_ad_admin/App%20Root/app_root.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase (الأساسية)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تهيئة دعم اللغة الإنجليزية لتنسيق التاريخ
  await initializeDateFormatting('en', null);

  runApp(const AppRoot());
}