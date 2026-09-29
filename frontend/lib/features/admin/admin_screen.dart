import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_surfaces.dart';
import 'admin_api.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return const Scaffold(
        body: Center(child: Text('Sign in as an administrator.')),
      );
    }
    return FutureBuilder<bool>(
      future: user
          .getIdTokenResult(true)
          .then((token) => token.claims?['admin'] == true),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return const Scaffold(
            body: Center(child: Text('Administrator access is required.')),
          );
        }
        return const AdminScreen();
      },
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = AdminApi();
  late Future<List<List<Map<String, dynamic>>>> _records = _load();

  Future<List<List<Map<String, dynamic>>>> _load() => Future.wait([
    _api.list('reports'),
    _api.list('places'),
    _api.list('source-health'),
    _api.list('audit'),
  ]);

  void _refresh() => setState(() => _records = _load());

  Future<void> _moderate(Map<String, dynamic> report, bool approve) async {
    final id = report['id'] as String;
    if (approve) {
      final controller = TextEditingController();
      final description = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve report'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Public summary without personal details',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (description == null || description.length < 3) return;
      await _run(
        () => _api.post('reports/$id:approve', {
          'public_description': description,
        }),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject report?'),
          content: const Text(
            'The report will not appear in public updates. Its photo will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _run(() => _api.post('reports/$id:reject', {}));
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _showPhoto(String id) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Screened private photo'),
        content: FutureBuilder(
          future: _api.photo(id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Photo is unavailable or expired.');
            }
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return Image.memory(
              snapshot.data!,
              semanticLabel: 'Screened report photo',
              fit: BoxFit.contain,
              cacheWidth: 1200,
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _newPlace() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _PlaceDialog(),
    );
    if (result != null) await _run(() => _api.post('places', result));
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('ResQ operations'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Reports'),
            Tab(text: 'Places'),
            Tab(text: 'Sources'),
            Tab(text: 'Audit'),
          ],
        ),
      ),
      body: FutureBuilder(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Operations data is unavailable.'),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return TabBarView(
            children: [
              _list(
                data[0],
                (item) => AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['hazard']?.toString() ?? 'Report',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(item['description']?.toString() ?? ''),
                      Text('Photo: ${item['photoState'] ?? 'none'}'),
                      if (item['photoState'] == 'clean')
                        TextButton(
                          onPressed: () => _showPhoto(item['id'] as String),
                          child: const Text('View screened photo'),
                        ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          FilledButton(
                            onPressed: () => _moderate(item, true),
                            child: const Text('Approve'),
                          ),
                          OutlinedButton(
                            onPressed: () => _moderate(item, false),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Stack(
                children: [
                  _list(
                    data[1],
                    (item) => AppSectionCard(
                      child: ListTile(
                        title: Text(item['name']?.toString() ?? 'Place'),
                        subtitle: Text(
                          '${item['sourceUrl'] ?? ''}\nVerified ${item['verifiedAt'] ?? ''}',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: FloatingActionButton.extended(
                      onPressed: _newPlace,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Verify a place'),
                    ),
                  ),
                ],
              ),
              _list(
                data[2],
                (item) => AppSectionCard(
                  child: ListTile(
                    title: Text(item['id']?.toString() ?? 'Source'),
                    subtitle: Text(
                      'Status: ${item['status'] ?? 'unknown'}\nLast checked: ${item['lastCheckedAt'] ?? item['lastRunAt'] ?? 'never'}',
                    ),
                    trailing: item['failures'] != null && item['failures'] != 0
                        ? const Icon(Icons.warning_amber_rounded)
                        : null,
                  ),
                ),
              ),
              _list(
                data[3],
                (item) => AppSectionCard(
                  child: ListTile(
                    title: Text(item['action']?.toString() ?? 'Action'),
                    subtitle: Text(
                      '${item['target'] ?? ''}\n${item['at'] ?? ''}',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _list(
    List<Map<String, dynamic>> items,
    Widget Function(Map<String, dynamic>) row,
  ) => AppPageContent(
    maxWidth: 900,
    child: items.isEmpty
        ? const Center(child: Text('No records yet.'))
        : ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final item in items) ...[
                row(item),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
  );
}

class _PlaceDialog extends StatefulWidget {
  const _PlaceDialog();
  @override
  State<_PlaceDialog> createState() => _PlaceDialogState();
}

class _PlaceDialogState extends State<_PlaceDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _type = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _source = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _name,
      _type,
      _latitude,
      _longitude,
      _source,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Verify a place'),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Name'),
              _field(_type, 'Type'),
              _field(_latitude, 'Latitude'),
              _field(_longitude, 'Longitude'),
              _field(_source, 'Official source HTTPS URL'),
              _field(_note, 'What was verified and when'),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(context, {
            'name': _name.text.trim(),
            'type': _type.text.trim(),
            'latitude': double.parse(_latitude.text),
            'longitude': double.parse(_longitude.text),
            'source_url': _source.text.trim(),
            'source_note': _note.text.trim(),
          });
        },
        child: const Text('Publish verified place'),
      ),
    ],
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        if (label == 'Latitude' &&
            (double.tryParse(value) == null ||
                double.parse(value) < 6 ||
                double.parse(value) > 38)) {
          return 'Enter an Indian latitude';
        }
        if (label == 'Longitude' &&
            (double.tryParse(value) == null ||
                double.parse(value) < 68 ||
                double.parse(value) > 98)) {
          return 'Enter an Indian longitude';
        }
        if (label.contains('URL') && !value.startsWith('https://')) {
          return 'Use an HTTPS source URL';
        }
        return null;
      },
    ),
  );
}
