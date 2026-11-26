import 'package:flutter/material.dart';

void main() {
  runApp(const PotteryTrackerApp());
}

class PotteryTrackerApp extends StatelessWidget {
  const PotteryTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const clay = Color(0xFF9B6048);
    return MaterialApp(
      title: 'PotteryTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: clay,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAF7F2),
          foregroundColor: Color(0xFF342820),
          elevation: 0,
        ),
      ),
      home: const StudioHomePage(),
    );
  }
}

class StudioHomePage extends StatefulWidget {
  const StudioHomePage({super.key});

  @override
  State<StudioHomePage> createState() => _StudioHomePageState();
}

class _StudioHomePageState extends State<StudioHomePage> {
  int _selectedIndex = 0;

  static const _sections = <_StudioSection>[
    _StudioSection(
      title: 'Studio',
      subtitle: 'Your pottery workspace',
      icon: Icons.home_outlined,
      description: 'A home for your current work, studio activity, and reminders.',
    ),
    _StudioSection(
      title: 'Pieces',
      subtitle: 'Pottery projects',
      icon: Icons.spa_outlined,
      description: 'Track each piece from forming and drying through bisque, glazing, and completion.',
    ),
    _StudioSection(
      title: 'Materials',
      subtitle: 'Clay and glaze library',
      icon: Icons.palette_outlined,
      description: 'Keep clay bodies, glaze recipes, ingredients, test tiles, and studio stock organized.',
    ),
    _StudioSection(
      title: 'Firings',
      subtitle: 'Kiln history',
      icon: Icons.local_fire_department_outlined,
      description: 'Record kiln loads, firing schedules, cone targets, temperatures, and results.',
    ),
    _StudioSection(
      title: 'Notes',
      subtitle: 'Studio journal',
      icon: Icons.menu_book_outlined,
      description: 'Capture observations, measurements, costs, and lessons learned.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons pottery_outlined, size: 26),
            SizedBox(width: 10),
            Text('PotteryTracker', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(section.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(section.subtitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.brown.shade600)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E5D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(section.icon, size: 34, color: const Color(0xFF89533F)),
                  const SizedBox(height: 14),
                  Text(section.description, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'This area is being built. Your pottery records will live here as features are added.',
                    style: TextStyle(color: Color(0xFF6F6259)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Planned workspace', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const _FeatureRow(icon: Icons.inventory_2_outlined, title: 'Pieces and project stages'),
            const _FeatureRow(icon: Icons.science_outlined, title: 'Glaze recipes and test tiles'),
            const _FeatureRow(icon: Icons.thermostat_outlined, title: 'Kiln firings and cone tracking'),
            const _FeatureRow(icon: Icons.photo_library_outlined, title: 'Photos and project history'),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          for (final item in _sections)
            NavigationDestination(icon: Icon(item.icon), label: item.title),
        ],
      ),
    );
  }
}

class _StudioSection {
  const _StudioSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String description;
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF89533F)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
