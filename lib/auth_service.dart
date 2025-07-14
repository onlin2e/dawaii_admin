import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<String?> getAccessToken() async {
  try {
    // تحميل ملف JSON من assets
    String jsonString = await rootBundle.loadString('assets/med-ad-firebase-adminsdk-fbsvc-8f97f54b29.json');
    Map<String, dynamic> json = jsonDecode(jsonString);

    // إنشاء بيانات الاعتماد
    var credentials = ServiceAccountCredentials.fromJson(json);

    // إنشاء عميل مصادقة
    var client = await clientViaServiceAccount(credentials, ['https://www.googleapis.com/auth/firebase.messaging']);

    // الحصول على رمز الوصول
    return client.credentials.accessToken.toString();
  } catch (e) {
    print('Error getting access token: $e');
    return null;
  }
}