import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/app_lock_wrapper.dart';

class MyLifeApp extends StatelessWidget {
  const MyLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyLife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
        scaffoldBackgroundColor: kBg,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: kCard,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const AppLockWrapper(),
    );
  }
}
