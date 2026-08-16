import 'package:flutter/material.dart';

/// One option in a polished picker list.
class AppSelectOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final Widget? leading;

  const AppSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.color,
    this.leading,
  });
}

/// Modern field that opens a searchable bottom-sheet picker (not a raw dropdown).
class AppSelectField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool searchable;
  final String searchHint;
  final Widget? leading;

  const AppSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.hint,
    this.searchable = true,
    this.searchHint = 'Search…',
    this.leading,
  });

  AppSelectOption<T>? get _selected {
    if (value == null) return null;
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final result = await showAppSelectSheet<T>(
      context: context,
      title: label,
      options: options,
      selected: value,
      searchable: searchable && options.length > 6,
      searchHint: searchHint,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selected;

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
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ] else if (selected?.leading != null) ...[
                    selected!.leading!,
                    const SizedBox(width: 12),
                  ] else if (selected?.icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (selected!.color ?? cs.primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        selected.icon,
                        size: 18,
                        color: selected.color ?? cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected?.label ?? hint ?? 'Select',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: selected != null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected != null
                                        ? cs.onSurface
                                        : cs.onSurface.withValues(alpha: 0.45),
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (selected?.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            selected!.subtitle!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.5),
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
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

/// Full-screen-style bottom sheet picker with optional search.
Future<T?> showAppSelectSheet<T>({
  required BuildContext context,
  required String title,
  required List<AppSelectOption<T>> options,
  T? selected,
  bool searchable = true,
  String searchHint = 'Search…',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return _SelectSheetBody<T>(
        title: title,
        options: options,
        selected: selected,
        searchable: searchable,
        searchHint: searchHint,
      );
    },
  );
}

class _SelectSheetBody<T> extends StatefulWidget {
  final String title;
  final List<AppSelectOption<T>> options;
  final T? selected;
  final bool searchable;
  final String searchHint;

  const _SelectSheetBody({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
    required this.searchHint,
  });

  @override
  State<_SelectSheetBody<T>> createState() => _SelectSheetBodyState<T>();
}

class _SelectSheetBodyState<T> extends State<_SelectSheetBody<T>> {
  String _query = '';

  List<AppSelectOption<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((o) {
      final hay = '${o.label} ${o.subtitle ?? ''}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final height = MediaQuery.of(context).size.height * 0.72;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (widget.searchable) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                ),
              ),
            ),
          ],
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No results',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final o = filtered[i];
                      final isSelected = o.value == widget.selected;
                      final color = o.color ?? cs.primary;
                      return Material(
                        color: isSelected
                            ? color.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: o.leading ??
                              (o.icon != null
                                  ? Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child:
                                          Icon(o.icon, color: color, size: 20),
                                    )
                                  : null),
                          title: Text(
                            o.label,
                            style: TextStyle(
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: o.subtitle != null
                              ? Text(o.subtitle!)
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: color)
                              : null,
                          onTap: () => Navigator.pop(context, o.value),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Segmented type selector (Cash / Bank / Wallet / Card).
class AppSegmentedType<T> extends StatelessWidget {
  final List<({T value, String label, IconData icon})> items;
  final T selected;
  final ValueChanged<T> onChanged;

  const AppSegmentedType({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items.map((item) {
          final on = item.value == selected;
          return Expanded(
            child: Material(
              color: on
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                onTap: () => onChanged(item.value),
                borderRadius: BorderRadius.circular(11),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Icon(
                        item.icon,
                        size: 18,
                        color: on
                            ? (isDark ? Colors.black : Colors.white)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: on
                              ? (isDark ? Colors.black : Colors.white)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
