export 'home.dart';

import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const placeholderColor = Color(0xFFD9D9D9);
    const sectionTitleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Review', style: sectionTitleStyle),
          const SizedBox(height: 12),
          _ReviewPlaceholder(color: placeholderColor),
          const SizedBox(height: 12),
          _ReviewPlaceholder(color: placeholderColor),
          const SizedBox(height: 12),
          _ReviewPlaceholder(color: placeholderColor),
          const SizedBox(height: 20),
          const Text('Dashboard', style: sectionTitleStyle),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _DashboardTile(color: placeholderColor)),
              SizedBox(width: 16),
              Expanded(child: _DashboardTile(color: placeholderColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _DashboardTile(color: placeholderColor)),
              SizedBox(width: 16),
              Expanded(child: _DashboardTile(color: placeholderColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewPlaceholder extends StatelessWidget {
  const _ReviewPlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}