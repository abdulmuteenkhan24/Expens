import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

/// Field that opens a sheet to choose an existing tag or create a new one.
class TagPickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final String hint;

  const TagPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Tag',
    this.hint = 'None — choose or create',
  });

  Future<void> _open(BuildContext context) async {
    final result = await showTagPickerSheet(
      context: context,
      selected: value,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Material(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sell_outlined,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasValue ? value : hint,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                hasValue ? FontWeight.w600 : FontWeight.w400,
                            color: hasValue
                                ? cs.onSurface
                                : cs.onSurface.withValues(alpha: 0.45),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasValue)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                      onPressed: () => onChanged(''),
                      tooltip: 'Clear tag',
                    )
                  else
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Returns selected tag string, empty string for none, or null if cancelled.
Future<String?> showTagPickerSheet({
  required BuildContext context,
  String selected = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _TagPickerSheet(selected: selected),
  );
}

class _TagPickerSheet extends StatefulWidget {
  final String selected;

  const _TagPickerSheet({required this.selected});

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  String _query = '';
  final _createCtrl = TextEditingController();

  @override
  void dispose() {
    _createCtrl.dispose();
    super.dispose();
  }

  Future<void> _createTag(AppState state) async {
    final name = _createCtrl.text.trim();
    if (name.isEmpty) return;

    // Reuse existing tag if same name (case-insensitive).
    for (final t in state.allTags) {
      if (t.toLowerCase() == name.toLowerCase()) {
        if (mounted) Navigator.pop(context, t);
        return;
      }
    }

    await state.ensureTag(name);
    if (mounted) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final tags = state.allTags;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? tags
        : tags.where((t) => t.toLowerCase().contains(q)).toList();
    final height = MediaQuery.of(context).size.height * 0.7;
    final canCreateFromQuery = q.isNotEmpty &&
        !tags.any((t) => t.toLowerCase() == q);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Tag',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Choose an existing tag or create a new one',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search tags…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  // None
                  _tagTile(
                    context,
                    label: 'None',
                    icon: Icons.block,
                    selected: widget.selected.isEmpty,
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  const SizedBox(height: 4),
                  // Create from search query
                  if (canCreateFromQuery)
                    _tagTile(
                      context,
                      label: 'Create “${_query.trim()}”',
                      icon: Icons.add_circle_outline,
                      selected: false,
                      highlight: true,
                      onTap: () async {
                        final name = _query.trim();
                        await state.ensureTag(name);
                        if (context.mounted) Navigator.pop(context, name);
                      },
                    ),
                  if (filtered.isEmpty && !canCreateFromQuery)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          tags.isEmpty
                              ? 'No tags yet — create one below'
                              : 'No matching tags',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    ...filtered.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _tagTile(
                          context,
                          label: t,
                          icon: Icons.sell_outlined,
                          selected: widget.selected.toLowerCase() ==
                              t.toLowerCase(),
                          onTap: () => Navigator.pop(context, t),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Create new section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _createCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _createTag(state),
                      decoration: const InputDecoration(
                        hintText: 'New tag name',
                        prefixIcon: Icon(Icons.add_rounded, size: 20),
                        isDense: true,
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => _createTag(state),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(88, 48),
                    ),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final color = highlight ? cs.primary : cs.primary;

    return Material(
      color: selected
          ? color.withValues(alpha: 0.1)
          : highlight
              ? color.withValues(alpha: 0.06)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected || highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: color)
            : null,
        onTap: onTap,
      ),
    );
  }
}
