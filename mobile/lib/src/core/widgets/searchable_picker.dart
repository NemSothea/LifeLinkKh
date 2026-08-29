import 'package:flutter/material.dart';

/// A tappable field that opens a search-and-pick bottom sheet, for choosing one of a
/// small already-fetched list — districts, hospitals, anything where the whole list is
/// already in memory and the only job left is finding one item in it by name.
///
/// Not a `DropdownButtonFormField`: that widget has no room for a search field, and its
/// native menu becomes a long blind scroll once the list passes a handful of items
/// (14 districts today; hospitals are deliberately few now but expected to grow —
/// `docs/po/reference/phnom-penh-hospitals.md`). Not a full route either — this is a
/// single value choice from a known list, not a destination, and pushing a route makes
/// back-navigation ambiguous (cancel the pick, or leave the form?).
///
/// The closed state is an [InputDecorator] wrapping plain text rather than a real
/// `TextField`, so it inherits `AppTheme.inputDecorationTheme`'s border automatically —
/// the same visual language as every other field in the app — without being editable
/// itself; all typing happens in the sheet.
class SearchablePicker<T> extends StatelessWidget {
    const SearchablePicker({
        required this.items,
        required this.labelBuilder,
        required this.searchableTextBuilder,
        required this.selected,
        required this.onSelected,
        required this.fieldLabel,
        required this.hintText,
        required this.searchHint,
        required this.noResultsText,
        this.itemKey,
        super.key,
    });

    final List<T> items;
    final String Function(T item) labelBuilder;

    /// What a query is matched against — can differ from [labelBuilder] (e.g. a
    /// hospital's search text also includes its district, so typing the district
    /// surfaces hospitals in it, even though the closed field only shows the name).
    final String Function(T item) searchableTextBuilder;

    final T? selected;
    final ValueChanged<T> onSelected;
    final String fieldLabel;
    final String hintText;
    final String searchHint;
    final String noResultsText;

    /// Per-item `Key` for the sheet's list tiles, so a caller's widget tests can find a
    /// specific row the same way they would a `DropdownMenuItem`.
    final Key Function(T item)? itemKey;

    Future<void> _open(BuildContext context) async {
        final result = await showModalBottomSheet<T>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => _PickerSheet<T>(
                items: items,
                labelBuilder: labelBuilder,
                searchableTextBuilder: searchableTextBuilder,
                searchHint: searchHint,
                noResultsText: noResultsText,
                itemKey: itemKey,
            ),
        );
        if (result != null) onSelected(result);
    }

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final label = selected == null ? hintText : labelBuilder(selected as T);

        return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(context),
            child: InputDecorator(
                decoration: InputDecoration(labelText: fieldLabel),
                child: Row(
                    children: [
                        Expanded(
                            child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: selected == null
                                    ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                                    : theme.textTheme.bodyLarge,
                            ),
                        ),
                        Icon(Icons.unfold_more, size: 20, color: theme.hintColor),
                    ],
                ),
            ),
        );
    }
}

class _PickerSheet<T> extends StatefulWidget {
    const _PickerSheet({
        required this.items,
        required this.labelBuilder,
        required this.searchableTextBuilder,
        required this.searchHint,
        required this.noResultsText,
        this.itemKey,
    });

    final List<T> items;
    final String Function(T item) labelBuilder;
    final String Function(T item) searchableTextBuilder;
    final String searchHint;
    final String noResultsText;
    final Key Function(T item)? itemKey;

    @override
    State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
    final _queryController = TextEditingController();
    late List<T> _filtered = widget.items;

    @override
    void dispose() {
        _queryController.dispose();
        super.dispose();
    }

    // Plain substring match. Khmer has no letter case, so lowering is a no-op there and
    // a correctness win for the Latin hospital names — no normalization package needed
    // for either script.
    void _onQueryChanged(String query) {
        setState(() {
            _filtered = query.isEmpty
                ? widget.items
                : widget.items
                    .where(
                        (item) => widget
                            .searchableTextBuilder(item)
                            .toLowerCase()
                            .contains(query.toLowerCase()),
                    )
                    .toList();
        });
    }

    @override
    Widget build(BuildContext context) {
        return SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Padding(
                padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        TextField(
                            key: const Key('searchable-picker-query'),
                            controller: _queryController,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                                hintText: widget.searchHint,
                                prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: _onQueryChanged,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                            child: _filtered.isEmpty
                                ? Center(
                                    child: Text(
                                        widget.noResultsText,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                )
                                : ListView.separated(
                                    key: const Key('searchable-picker-results'),
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, _) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                        final item = _filtered[index];
                                        return ListTile(
                                            key: widget.itemKey?.call(item),
                                            title: Text(widget.labelBuilder(item)),
                                            onTap: () => Navigator.of(context).pop(item),
                                        );
                                    },
                                ),
                        ),
                    ],
                ),
            ),
        );
    }
}
