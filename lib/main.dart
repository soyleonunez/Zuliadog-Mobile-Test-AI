import 'package:flutter/material.dart';
import 'package:zuliadog/core/theme.dart';
import 'package:zuliadog/features/home.dart';
// <- NUEVO

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZuliadogApp());
}

class ZuliadogApp extends StatelessWidget {
  const ZuliadogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeView(), // <- SIEMPRE abre Home + menú
    );
  }
}
