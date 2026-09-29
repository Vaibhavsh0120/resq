import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Keep the OSM licence visible even when the map is not being touched.
class OsmMapAttribution extends StatelessWidget {
  const OsmMapAttribution({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomRight,
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 230),
        child: Material(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Center(
                  child: Text(
                    '© OpenStreetMap contributors',
                    softWrap: true,
                    style: TextStyle(color: Colors.black87, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
