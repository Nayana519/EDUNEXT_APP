import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<dynamic>> _items = ApiService.getNotifications();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<dynamic>>(
        future: _items,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('No notifications yet'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final n in list)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.circle,
                        size: 10,
                        color: n['read'] == true ? Colors.transparent : Colors.orange),
                    title: Text(n['message']),
                    onTap: () async {
                      await ApiService.markNotificationRead(n['id']);
                      setState(() {
                            _items = ApiService.getNotifications();
                          });
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}