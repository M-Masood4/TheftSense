import 'package:flutter/material.dart';

class TwoFaPage extends StatelessWidget {
  const TwoFaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        centerTitle: true,
      ),
      body: const SizedBox.shrink(),
    );
  }
}
