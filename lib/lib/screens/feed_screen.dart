import 'package:flutter/material.dart';
import '../services/api_service.dart';

Color hexToColor(String hex) =>
    Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class feed')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getFeed(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return const Center(child: Text('No announcements yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final p = posts[i];
              final color = hexToColor(p['color']);
              return Card(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: color, width: 4)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['subject_code'] ?? 'Class-wide',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(p['title'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(p['body']),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}