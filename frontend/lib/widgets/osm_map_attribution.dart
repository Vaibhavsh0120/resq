import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Keep the licence adjacent to the map without covering its tiles or markers.
class OsmCreditedMap extends StatelessWidget {
  const OsmCreditedMap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: child),
      const OsmMapAttribution(),
    ],
  );
}

class OsmMapAttribution extends StatelessWidget {
  const OsmMapAttribution({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    heightFactor: 1,
    child: TextButton(
      onPressed: () =>
          launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        textStyle: const TextStyle(
          fontSize: 12,
          decoration: TextDecoration.underline,
        ),
      ),
      child: const Text('© OpenStreetMap contributors'),
    ),
  );
}
