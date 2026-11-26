// Flutter 3.50 marks the Material umbrella library deprecated while its replacement stabilizes.
// Keep using the stable Flutter SDK Material widgets for broad Android/iOS compatibility.
// ignore_for_file: deprecated_member_use, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'data/studio_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['PotteryTracker'],
      'MIT License\\n\\nCopyright (c) 2026 PotteryTracker contributors\\n\\n'
      'Permission is hereby granted, free of charge, to any person obtaining a copy '
      'of this software and associated documentation files (the "Software"), to deal '
      'in the Software without restriction, including without limitation the rights '
      'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
      'copies of the Software, and to permit persons to whom the Software is '
      'furnished to do so, subject to the following conditions:\\n\\n'
      'The above copyright notice and this permission notice shall be included in all '
      'copies or substantial portions of the Software.\\n\\n'
      'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
      'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
      'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
      'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
      'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
      'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
      'SOFTWARE.',
    );
  });
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
      photos: await _persistPhotos(draft.photos),
    );
    await _load();
    if (mounted) _notify('Record saved.');
  }

  Future<List<String>> _persistPhotos(List<String> photos) async {
    if (photos.isEmpty) return [];
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(root.path, 'record_photos'));
    await folder.create(recursive: true);
    final saved = <String>[];
    for (var i = 0; i < photos.length; i++) {
      final sourcePath = photos[i];
      if (p.equals(p.dirname(sourcePath), folder.path)) {
        saved.add(sourcePath);
        continue;
      }
      final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
      final destination = p.join(folder.path, '${DateTime.now().microsecondsSinceEpoch}_$i$extension');
      await File(sourcePath).copy(destination);
      saved.add(destination);
    }
    return saved;
  }

  Future<void> _edit(StudioRecord record) async {
    final draft = await showDialog<_Draft>(
      context: context,
      builder: (_) => _RecordDialog(category: record.category, record: record),
    );
    if (draft == null) return;
    await StudioDatabase.instance.update(
      id: record.id,
      title: draft.title,
      detail: draft.detail,
      stage: draft.stage,
      notes: draft.notes,
      photos: await _persistPhotos(draft.photos),
    );
    await _load();
    if (mounted) _notify('Changes saved.');
  }

  Future<void> _openPhotoGallery(List<String> photos, int initialIndex) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _PhotoGalleryPage(photos: photos, initialIndex: initialIndex),
    ));
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

  Future<void> _showAbout() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('About PotteryTracker'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pottery studio management for Android and iOS.'),
            SizedBox(height: 12),
            Text('Version 0.1.0'),
            SizedBox(height: 8),
            Text('© 2026 PotteryTracker contributors. Licensed under the MIT License.'),
            SizedBox(height: 8),
            Text('This app uses open-source software. Third-party license notices are included below.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              showLicensePage(
                context: context,
                applicationName: 'PotteryTracker',
                applicationVersion: '0.1.0',
                applicationLegalese: '© 2026 PotteryTracker contributors. MIT License.',
              );
            },
            child: const Text('Open-source licenses'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            tooltip: 'About and open-source licenses',
            icon: const Icon(Icons.info_outline),
            onPressed: _showAbout,
          ),
        ],
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
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (details.isNotEmpty) Text(details),
                                if (record.photos.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(height: 76, child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: record.photos.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                                    itemBuilder: (context, photoIndex) => GestureDetector(
                                      onTap: () => _openPhotoGallery(record.photos, photoIndex),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(File(record.photos[photoIndex]), width: 76, height: 76, fit: BoxFit.cover),
                                      ),
                                    ),
                                  )),
                                ],
                              ]),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                if (current.category == 'sale')
                                  IconButton(tooltip: 'Create listing', icon: const Icon(Icons.description_outlined), onPressed: () => _showListings(record)),
                                IconButton(tooltip: 'Edit record', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(record)),
                                IconButton(tooltip: 'Delete record', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(record)),
                              ]),
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
  const _Draft(this.title, this.detail, this.stage, this.notes, this.photos);
  final String title;
  final String detail;
  final String stage;
  final String notes;
  final List<String> photos;
}

class _RecordDialog extends StatefulWidget {
  const _RecordDialog({required this.category, this.record});
  final String category;
  final StudioRecord? record;
  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _detail = TextEditingController();
  final _notes = TextEditingController();
  String? _stage;
  final List<String> _photos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final existing = widget.record;
    if (existing != null) {
      _title.text = existing.title;
      _detail.text = existing.detail;
      _notes.text = existing.notes;
      _stage = existing.stage.isEmpty ? null : existing.stage;
      _photos.addAll(existing.photos);
    }
  }

  Future<void> _pickPhotos() async {
    final selected = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1800);
    if (selected.isNotEmpty && mounted) setState(() => _photos.addAll(selected.map((photo) => photo.path)));
  }

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
        title: Text((widget.record == null ? 'Add ' : 'Edit ') + (widget.category == 'piece'
            ? 'piece'
            : widget.category == 'material'
                ? 'material'
                : widget.category == 'sale' ? 'finished item' : 'firing')),
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
                Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_photos.isEmpty ? 'Add photos' : 'Add more photos (${_photos.length})'),
                )),
                if (_photos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(height: 72, child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) => Stack(children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => _PhotoGalleryPage(photos: _photos, initialIndex: index),
                        )),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_photos[index]), width: 72, height: 72, fit: BoxFit.cover)),
                      ),
                      Positioned(right: 0, top: 0, child: InkWell(onTap: () => setState(() => _photos.removeAt(index)), child: const CircleAvatar(radius: 11, child: Icon(Icons.close, size: 14)))),
                    ]),
                  )),
                ],
                const SizedBox(height: 8),
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
              Navigator.pop(context, _Draft(_title.text.trim(), _detail.text.trim(), _stage ?? '', _notes.text.trim(), List<String>.from(_photos)));
            },
            child: Text(widget.record == null ? 'Save' : 'Save changes'),
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

class _PhotoGalleryPage extends StatefulWidget {
  const _PhotoGalleryPage({required this.photos, required this.initialIndex});

  final List<String> photos;
  final int initialIndex;

  @override
  State<_PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<_PhotoGalleryPage> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('${_currentIndex + 1} of ${widget.photos.length}'),
          centerTitle: true,
        ),
        body: PageView.builder(
          controller: _controller,
          itemCount: widget.photos.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) => Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Image.file(
                File(widget.photos[index]),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      );
}
