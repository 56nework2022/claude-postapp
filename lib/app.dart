import 'package:flutter/material.dart';

import 'features/disclaimer/disclaimer_gate.dart';
import 'features/project_list/project_list_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '撮影用ポスト画面メーカー',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DisclaimerGate(child: ProjectListPage()),
    );
  }
}
