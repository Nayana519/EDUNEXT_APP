IconButton(
  icon: const Icon(Icons.notifications_none),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  },
)