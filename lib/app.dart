import 'package:flutter/material.dart';
import 'screens/home/home_page.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}