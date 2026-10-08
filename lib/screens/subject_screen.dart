DefaultTabController(
  length: 3,
  child: Column(
    children: [
      Container(
        width: double.infinity,
        color: const Color(0xFF2F6F4E),
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          42,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CS301',
              style: TextStyle(color: Colors.white),
            ),
            Text(
              'Database Systems',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Dr. Meera Sharma',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),

      const TabBar(
        tabs: [
          Tab(text: 'Feed'),
          Tab(text: 'Materials'),
          Tab(text: 'Assignments'),
        ],
      ),

      Expanded(
        child: TabBarView(
          children: [
            FeedTab(),
            MaterialsTab(),
            AssignmentsTab(),
          ],
        ),
      ),
    ],
  ),
)