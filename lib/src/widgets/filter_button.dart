import 'package:flutter/material.dart';

class FilterColors {
  static const primary = Color(0xFF7A1E2D);
  static const background = Color(0xFFF7F8FA);
  static const border = Color(0xFFE0E0E0);

  static const chipBg = Color(0xFFF5F5F5);
  static const chipSelected = Color(0xFF7A1E2D);

  static const textDark = Color(0xFF212121);
  static const textGrey = Color(0xFF757575);
}

class FilterButton extends StatelessWidget {
  final List<String> categoryItems;
  final List<String> cardTypeItems;
  final List<String> stationItems;

  final List<String> selectedCategories;
  final List<String> selectedCardTypes;
  final List<String> selectedStations;

  final DateTime? startDate;
  final DateTime? endDate;

  final ValueChanged<List<String>> onCategoryChanged;
  final ValueChanged<List<String>> onCardTypeChanged;
  final ValueChanged<List<String>> onStationChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;

  final VoidCallback onApply;
  final VoidCallback onReset;

  const FilterButton({
    super.key,
    required this.categoryItems,
    required this.cardTypeItems,
    required this.stationItems,
    required this.selectedCategories,
    required this.selectedCardTypes,
    required this.selectedStations,
    required this.startDate,
    required this.endDate,
    required this.onCategoryChanged,
    required this.onCardTypeChanged,
    required this.onStationChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onApply,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.filter_alt),
      label: const Text('Filter'),
      style: ElevatedButton.styleFrom(
        backgroundColor: FilterColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _open(context),
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        List<String> tempCategories = List.from(selectedCategories);
        List<String> tempTypes = List.from(selectedCardTypes);
        List<String> tempStations = List.from(selectedStations);
        DateTime? tempStartDate = startDate;
        DateTime? tempEndDate = endDate;

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, controller) {
            return StatefulBuilder(
              builder: (context, setModal) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    controller: controller,
                    children: [
                      _header(),

                      _dateSection(
                        context,
                        start: tempStartDate,
                        end: tempEndDate,
                        onStart: (d) => setModal(() => tempStartDate = d),
                        onEnd: (d) => setModal(() => tempEndDate = d),
                      ),

                      _expandable(
                        title: 'Kategori',
                        child: _chipGroup(
                          items: categoryItems,
                          selected: tempCategories,
                          onChanged: (v) => setModal(() => tempCategories = v),
                        ),
                      ),

                      _expandable(
                        title: 'Tipe',
                        child: _chipGroup(
                          items: cardTypeItems,
                          selected: tempTypes,
                          onChanged: (v) => setModal(() => tempTypes = v),
                        ),
                      ),

                      _expandable(
                        title: 'Stasiun',
                        child: _chipGroup(
                          items: stationItems,
                          selected: tempStations,
                          onChanged: (v) => setModal(() => tempStations = v),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                onReset();
                                Navigator.pop(context);
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                onCategoryChanged(tempCategories);
                                onCardTypeChanged(tempTypes);
                                onStationChanged(tempStations);
                                onStartDateChanged(tempStartDate);
                                onEndDateChanged(tempEndDate);
                                onApply();
                                Navigator.pop(context);
                              },
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ================= UI PARTS =================

  Widget _header() => Column(
    children: const [
      SizedBox(height: 8),
      Text(
        'Filter Data',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 16),
    ],
  );

  Widget _expandable({required String title, required Widget child}) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [child],
    );
  }

  Widget _chipGroup({
    required List<String> items,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        final isSelected = selected.contains(e);
        return FilterChip(
          label: Text(e),
          selected: isSelected,
          onSelected: (v) {
            final newList = List<String>.from(selected);
            v ? newList.add(e) : newList.remove(e);
            onChanged(newList);
          },
        );
      }).toList(),
    );
  }

  Widget _dateSection(
    BuildContext context, {
    required DateTime? start,
    required DateTime? end,
    required ValueChanged<DateTime?> onStart,
    required ValueChanged<DateTime?> onEnd,
  }) {
    return Row(
      children: [
        Expanded(child: _datePicker(context, 'Tanggal Mulai', start, onStart)),
        const SizedBox(width: 12),
        Expanded(child: _datePicker(context, 'Tanggal Akhir', end, onEnd)),
      ],
    );
  }

  Widget _datePicker(
    BuildContext context,
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onPicked,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          date == null
              ? 'DD-MM-YYYY'
              : '${date.day}/${date.month}/${date.year}',
        ),
      ),
    );
  }
}
