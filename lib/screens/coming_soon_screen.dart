import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('$title - coming soon', style: const TextStyle(fontSize: 16)));
}