import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/expenses/screens/expense_list_screen.dart';

void main() {
  runApp(const ExpensePreviewApp());
}

class ExpensePreviewApp extends StatelessWidget {
  const ExpensePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ExpenseListScreen(onBack: _ignoreBack),
    );
  }
}

void _ignoreBack() {}
