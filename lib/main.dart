import 'package:flutter/material.dart';
import 'package:zuliadog/core/theme.dart';
import 'package:zuliadog/features/home.dart';
import 'package:zuliadog/auth/service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.init();
  runApp(const ZuliadogApp());
}

class ZuliadogApp extends StatelessWidget {
  const ZuliadogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
