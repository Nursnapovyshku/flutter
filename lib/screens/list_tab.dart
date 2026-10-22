import 'package:flutter/material.dart';
import '../models/event.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_card.dart';

class ListTab extends StatefulWidget {
  const ListTab({
    super.key,
    required this.events,
    required this.onOpen,
    required this.onFavourite,
    required this.onAdd,
    this.favouritesOnly = false,
  });
  final List<Event> events;
  final ValueChanged<Event> onOpen;
  final ValueChanged<Event> onFavourite;
  final VoidCallback onAdd;
  final bool favouritesOnly;

  @override
  State<ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<ListTab> {
  final _search = TextEditingController();
  EventCategory? _category;
  bool _includePast = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _search.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = widget.events
        .where(
          (event) =>
              (!widget.favouritesOnly || event.favourite) &&
              (event.title.toLowerCase().contains(query)) &&
              (_category == null || event.category == _category) &&
              (_includePast || !event.isPast),
        )
        .toList();
    filtered.sort((a, b) {
      if (a.isPast != b.isPast) return a.isPast ? 1 : -1;
      return a.starts.compareTo(b.starts);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Search events',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _search.clear,
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final category in EventCategory.values) ...[
                const SizedBox(width: 6),
                ChoiceChip(
                  label: Text(category.label),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
              ],
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: FilterChip(
              label: const Text('Include past'),
              selected: _includePast,
              onSelected: (value) => setState(() => _includePast = value),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: widget.favouritesOnly
                      ? Icons.favorite_border
                      : Icons.event_busy,
                  message: widget.favouritesOnly
                      ? 'No matching favourites'
                      : 'No matching events',
                  actionLabel: 'Clear filters',
                  onAction: () => setState(() {
                    _search.clear();
                    _category = null;
                    _includePast = true;
                  }),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 4),
                        itemBuilder: (_, i) => EventCard(
                          event: filtered[i],
                          onTap: () => widget.onOpen(filtered[i]),
                          onFavourite: () => widget.onFavourite(filtered[i]),
                        ),
                      );
                    }
                    final columns = (constraints.maxWidth / 360).floor().clamp(
                      2,
                      6,
                    );
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(16) / 16;
                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 32 + 96 * textScale,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => EventCard(
                        event: filtered[i],
                        onTap: () => widget.onOpen(filtered[i]),
                        onFavourite: () => widget.onFavourite(filtered[i]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
