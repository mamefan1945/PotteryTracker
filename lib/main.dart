// Flutter 3.50 marks the Material umbrella library deprecated while its replacement stabilizes.
// Keep using the stable Flutter SDK Material widgets for broad Android/iOS compatibility.
// ignore_for_file: deprecated_member_use, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/studio_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PotteryTrackerApp());
}

class PotteryTrackerApp extends StatelessWidget {
  const PotteryTrackerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PotteryTracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9B6048)),
          scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        ),
        home: const StudioHomePage(),
      );
}

class StudioHomePage extends StatefulWidget {
  const StudioHomePage({super.key});
  @override
  State<StudioHomePage> createState() => _StudioHomePageState();
}

class _StudioHomePageState extends State<StudioHomePage> {
  int _tab = 0;
  bool _loading = false;
  List<StudioRecord> _records = [];

  static const _tabs = [
    _Tab('Studio', Icons.home_outlined, ''),
    _Tab('Pieces', Icons.spa_outlined, 'piece'),
    _Tab('Materials', Icons.palette_outlined, 'material'),
    _Tab('Firings', Icons.local_fire_department_outlined, 'firing'),
    _Tab('For Sale', Icons.storefront_outlined, 'sale'),
    _Tab('Notes', Icons.menu_book_outlined, ''),
  ];

  _Tab get current => _tabs[_tab];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (current.category.isEmpty) {
      if (mounted) setState(() => _records = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await StudioDatabase.instance.records(current.category);
      if (mounted) setState(() => _records = result);
    } catch (error) {
      if (mounted) _notify('Unable to load records: ' + error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeTab(int index) {
    setState(() => _tab = index);
    _load();
  }

  Future<void> _add() async {
    final draft = await showDialog<_Draft>(
      context: context,
      builder: (_) => _RecordDialog(category: current.category),
    );
    if (draft == null) return;
    await StudioDatabase.instance.add(
      category: current.category,
      title: draft.title,
      detail: draft.detail,
      stage: draft.stage,
      notes: draft.notes,
    );
    await _load();
    if (mounted) _notify('Record saved.');
  }

  Future<void> _showListings(StudioRecord record) async {
    await showDialog<void>(context: context, builder: (context) => _ListingDialog(record: record));
  }

  Future<void> _delete(StudioRecord record) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('Delete "' + record.title + '"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await StudioDatabase.instance.delete(record.id);
      await _load();
    }
  }

  void _notify(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final hasRecords = current.category.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.spa_outlined),
          SizedBox(width: 10),
          Text('PotteryTracker', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
      body: SafeArea(child: hasRecords ? _recordPage() : _homePage()),
      floatingActionButton: hasRecords
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: Text(current.category == 'sale' ? 'Add finished item' : 'Add ' + current.title.toLowerCase().substring(0, current.title.length - 1)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _changeTab,
        destinations: [
          for (final item in _tabs)
            NavigationDestination(icon: Icon(item.icon), label: item.title),
        ],
      ),
    );
  }

  Widget _homePage() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(current.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Your pottery workspace', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0E5D9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Keep track of the work you make, the materials you use, and every kiln firing. Your records are stored locally on this device.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          _HomeLink(icon: Icons.spa_outlined, title: 'Pieces', subtitle: 'Track pottery from wet clay to finished work', onTap: () => _changeTab(1)),
          _HomeLink(icon: Icons.palette_outlined, title: 'Materials', subtitle: 'Catalog clay bodies, glazes and ingredients', onTap: () => _changeTab(2)),
          _HomeLink(icon: Icons.local_fire_department_outlined, title: 'Firings', subtitle: 'Record kiln loads, cones and firing results', onTap: () => _changeTab(3)),
          _HomeLink(icon: Icons.storefront_outlined, title: 'For Sale', subtitle: 'Prepare listings for finished pottery', onTap: () => _changeTab(4)),
          if (_tab == 5)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('The studio journal will be added in a later update.'),
            ),
        ],
      );

  Widget _recordPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current.title, style: Theme.of(context).textTheme.headlineMedium),
                Text(current.title == 'Pieces'
                    ? 'Track your pottery projects'
                    : current.title == 'Materials'
                        ? 'Your clay and glaze library'
                        : current.category == 'sale' ? 'Finished pieces and marketplace listing drafts' : 'Kiln and firing history'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(current.icon, size: 48, color: Colors.brown.shade300),
                            const SizedBox(height: 12),
                            Text('No ' + current.title.toLowerCase() + ' yet',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            const Text('Tap Add to create your first record.'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: _records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          final details = [
                            if (record.detail.isNotEmpty) record.detail,
                            if (record.stage.isNotEmpty) record.stage,
                            if (record.notes.isNotEmpty) record.notes,
                          ].join(' • ');
                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF0E5D9),
                                child: Icon(current.icon, color: const Color(0xFF89533F)),
                              ),
                              title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: details.isEmpty ? null : Text(details),
                              trailing: current.category == 'sale'
                                  ? Wrap(mainAxisSize: MainAxisSize.min, children: [
                                      IconButton(tooltip: 'Create listing', icon: const Icon(Icons.description_outlined), onPressed: () => _showListings(record)),
                                      IconButton(tooltip: 'Delete record', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(record)),
                                    ])
                                  : IconButton(tooltip: 'Delete record', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(record)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
}

class _Tab {
  const _Tab(this.title, this.icon, this.category);
  final String title;
  final IconData icon;
  final String category;
}

class _HomeLink extends StatelessWidget {
  const _HomeLink({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF89533F), size: 28),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class _Draft {
  const _Draft(this.title, this.detail, this.stage, this.notes);
  final String title;
  final String detail;
  final String stage;
  final String notes;
}

class _RecordDialog extends StatefulWidget {
  const _RecordDialog({required this.category});
  final String category;
  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _detail = TextEditingController();
  final _notes = TextEditingController();
  String? _stage;

  List<String> get _options => switch (widget.category) {
        'piece' => ['Wet', 'Leather hard', 'Bone dry', 'Bisque fired', 'Glazed', 'Finished'],
        'material' => ['Clay body', 'Glaze', 'Ingredient', 'Other'],
        'sale' => ['Draft', 'Ready to list', 'Listed', 'Sold'],
        _ => ['Bisque', 'Glaze firing', 'Other'],
      };

  String get _nameLabel => widget.category == 'piece'
      ? 'Piece name'
      : widget.category == 'material'
          ? 'Material name'
          : widget.category == 'sale' ? 'Item name' : 'Firing name / load';

  String get _detailLabel => widget.category == 'piece'
      ? 'Clay body (optional)'
      : widget.category == 'material'
          ? 'Type or quantity (optional)'
          : widget.category == 'sale' ? 'Asking price (e.g. 48.00 USD)' : 'Kiln (optional)';

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Add ' + (widget.category == 'piece'
            ? 'piece'
            : widget.category == 'material'
                ? 'material'
                : 'firing')),
        content: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  autofocus: true,
                  decoration: InputDecoration(labelText: _nameLabel),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextField(controller: _detail, decoration: InputDecoration(labelText: _detailLabel)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _stage,
                  decoration: InputDecoration(
                    labelText: widget.category == 'piece'
                        ? 'Current stage'
                        : widget.category == 'material'
                            ? 'Material category'
                            : widget.category == 'sale' ? 'Sale status' : 'Firing type',
                  ),
                  items: _options.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) => setState(() => _stage = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  minLines: widget.category == 'sale' ? 4 : 2,
                  maxLines: widget.category == 'sale' ? 7 : 4,
                  decoration: InputDecoration(labelText: widget.category == 'sale' ? 'Description, dimensions, materials, care and shipping details' : 'Notes (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              Navigator.pop(context, _Draft(_title.text.trim(), _detail.text.trim(), _stage ?? '', _notes.text.trim()));
            },
            child: const Text('Save'),
          ),
        ],
      );
}

class _ListingDialog extends StatefulWidget {
  const _ListingDialog({required this.record});
  final StudioRecord record;
  @override
  State<_ListingDialog> createState() => _ListingDialogState();
}
class _ListingDialogState extends State<_ListingDialog> {
  String _platform = 'Etsy';
  String get _description => widget.record.notes.trim().isEmpty ? 'Handmade ceramic pottery. Add dimensions, materials, finish and care details before publishing.' : widget.record.notes.trim();
  String get _listing {
    final item = widget.record.title;
    final price = widget.record.detail.trim();
    final description = _description;
    if (_platform == 'eBay') return '$item | Handmade Ceramic Pottery\n\n$description\n\nCondition: New, handmade\nPrice: $price\n\nReview measurements, shipping and return terms before publishing.';
    if (_platform == 'Facebook Marketplace') return '$item\nPrice: $price\n\n$description\n\nHandmade pottery. Message me with questions or to arrange pickup/shipping.';
    if (_platform == 'Instagram') return '$item\n\n$description\n\nPrice: $price\n\n#handmadepottery #ceramics #pottery #ceramicart #handmade';
    return '$item — Handmade Ceramic Pottery\n\n$description\n\nPrice: $price\n\nAdd dimensions, clay and glaze details, care instructions, processing time, shipping information and relevant search tags.';
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Prepare a marketplace listing'),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Choose a destination. This creates a draft for you to review and publish.'),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _platform, decoration: const InputDecoration(labelText: 'Marketplace'), items: ['Etsy', 'eBay', 'Facebook Marketplace', 'Instagram'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _platform = v ?? 'Etsy')),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: SelectableText(_listing)),
    ]))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      FilledButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _listing)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing copied to clipboard.'))); }, icon: const Icon(Icons.copy), label: const Text('Copy listing')),
    ],
  );
}
