import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          ListTile(
            leading: Badge(child: Icon(Icons.warning_amber_rounded)),
            title: Text('Heavy rainfall advisory'),
            subtitle: Text('A verified weather warning affects your district.'),
            trailing: Text('Now'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.people_alt_outlined),
            title: Text('Ananya checked in safe'),
            subtitle: Text('Her last shared location was updated.'),
            trailing: Text('18m'),
          ),
        ],
      ),
    );
  }
}
