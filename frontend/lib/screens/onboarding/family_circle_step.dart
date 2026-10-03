import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as device_contacts;

import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/primary_button.dart';

/// Onboarding Step 3 — Family Circle.
///
/// Stores private emergency contacts on the user's profile. The Family feature
/// migrates them to its contact list. Household Circle invitations and acceptance
/// are separate actions after onboarding.
class FamilyCircleStep extends StatefulWidget {
  const FamilyCircleStep({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final FamilyCircle initialValue;
  final ValueChanged<FamilyCircle> onChanged;

  @override
  State<FamilyCircleStep> createState() => _FamilyCircleStepState();
}

class _FamilyCircleStepState extends State<FamilyCircleStep> {
  late List<FamilyMember> _members;

  @override
  void initState() {
    super.initState();
    _members = List.of(widget.initialValue.members);
  }

  void _emit() {
    widget.onChanged(
      FamilyCircle(members: List.of(_members), stepCompleted: true),
    );
  }

  void _addMember(FamilyMember member) {
    setState(() => _members.add(member));
    _emit();
  }

  void _removeMember(String id) {
    HapticFeedback.mediumImpact();
    setState(() => _members.removeWhere((m) => m.id == id));
    _emit();
  }

  void _setEmergencyContact(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _members = _members
          .map((m) => m.copyWith(isEmergencyContact: m.id == id))
          .toList();
    });
    _emit();
  }

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<FamilyMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddFamilyMemberSheet(),
    );
    if (added != null) {
      HapticFeedback.mediumImpact();
      _addMember(added);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add the people you trust most. You can mark one as your primary '
          'emergency contact.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_members.isEmpty)
          _EmptyFamilyState(onAdd: _openAddSheet)
        else ...[
          for (final member in _members)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FamilyMemberCard(
                member: member,
                onMakeEmergencyContact: () => _setEmergencyContact(member.id),
                onRemove: () => _removeMember(member.id),
              ),
            ),
          const SizedBox(height: 6),
          SecondaryButton(
            label: 'Add another family member',
            onPressed: _openAddSheet,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
          ),
        ],
      ],
    );
  }
}

class _EmptyFamilyState extends StatelessWidget {
  const _EmptyFamilyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DottedBorderBox(
      onTap: onAdd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const AppIllustration(
              'assets/illustrations/family_circle.png',
              height: 170,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No family members added yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add someone from your contacts',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple dashed-look tap target (Flutter has no built-in dashed border,
/// and pulling in a package for one box isn't worth the dependency — drawn
/// with a CustomPainter instead).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: scheme.outline),
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.md),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({
    required this.member,
    required this.onMakeEmergencyContact,
    required this.onRemove,
  });

  final FamilyMember member;
  final VoidCallback onMakeEmergencyContact;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: member.isEmergencyContact
            ? scheme.error.withValues(alpha: 0.06)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: member.isEmergencyContact
              ? scheme.error.withValues(alpha: 0.35)
              : scheme.outline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: scheme.secondary.withValues(alpha: 0.12),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: scheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(member.relationship, style: textTheme.bodySmall),
                if (member.phoneNumber != null &&
                    member.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(member.phoneNumber!, style: textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (member.isEmergencyContact)
                      Chip(
                        label: const Text('Emergency contact'),
                        labelStyle: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        backgroundColor: scheme.error.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      )
                    else
                      InkWell(
                        onTap: onMakeEmergencyContact,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Set as emergency contact',
                            style: textTheme.labelMedium?.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adding one family member — either picked from device
/// contacts (name + phone pre-filled) or entered manually, then a
/// relationship label is chosen/typed before confirming.
class _AddFamilyMemberSheet extends StatefulWidget {
  const _AddFamilyMemberSheet();

  @override
  State<_AddFamilyMemberSheet> createState() => _AddFamilyMemberSheetState();
}

class _AddFamilyMemberSheetState extends State<_AddFamilyMemberSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  bool _isPickingContact = false;

  static const _commonRelationships = [
    'Parent',
    'Spouse',
    'Sibling',
    'Child',
    'Friend',
    'Guardian',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _pickFromContacts() async {
    setState(() => _isPickingContact = true);
    try {
      final permission = await device_contacts.FlutterContacts.permissions
          .request(device_contacts.PermissionType.read);
      final granted =
          permission == device_contacts.PermissionStatus.granted ||
          permission == device_contacts.PermissionStatus.limited;
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Contacts permission denied — you can still add someone manually.',
              ),
            ),
          );
        }
        return;
      }
      final contacts = await device_contacts.FlutterContacts.getAll(
        properties: {device_contacts.ContactProperty.phone},
      );
      if (!mounted) return;
      final picked = await showModalBottomSheet<device_contacts.Contact>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ContactPickerSheet(contacts: contacts),
      );
      if (picked != null) {
        _nameController.text = picked.displayName ?? '';
        _phoneController.text = picked.phones.isNotEmpty
            ? picked.phones.first.number
            : '';
        HapticFeedback.selectionClick();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open contacts. Add the person manually instead.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingContact = false);
    }
  }

  void _confirm() {
    if (_nameController.text.trim().isEmpty ||
        _relationshipController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name and relationship.')),
      );
      return;
    }
    Navigator.of(context).pop(
      FamilyMember(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  Text(
                    'Add family member',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'Choose from contacts',
                    isLoading: _isPickingContact,
                    onPressed: _isPickingContact ? null : _pickFromContacts,
                    icon: const Icon(Icons.contacts_outlined, size: 18),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Name',
                    controller: _nameController,
                    hintText: 'Full name',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Phone number (optional)',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Relationship',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonRelationships.map((label) {
                      final isSelected = _relationshipController.text == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _relationshipController.text = label);
                        },
                        selectedColor: scheme.secondary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? scheme.onSecondary
                              : scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'Or type a relationship',
                    controller: _relationshipController,
                    hintText: 'e.g. Cousin, Neighbor',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Add to Family Circle',
                    onPressed: _confirm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  const _ContactPickerSheet({required this.contacts});

  final List<device_contacts.Contact> contacts;

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.contacts
        : widget.contacts
              .where(
                (c) => (c.displayName ?? '').toLowerCase().contains(
                  _query.toLowerCase(),
                ),
              )
              .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    autofocus: false,
                    decoration: const InputDecoration(
                      hintText: 'Search contacts',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No contacts found',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final contact = filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.12),
                                child: Text(
                                  (contact.displayName ?? '').isNotEmpty
                                      ? contact.displayName![0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                                ),
                              ),
                              title: Text(contact.displayName ?? ''),
                              subtitle: contact.phones.isNotEmpty
                                  ? Text(contact.phones.first.number)
                                  : null,
                              onTap: () => Navigator.of(context).pop(contact),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
