import 'package:articly/presentation/website_displaying/view_models/home_page_view_model.dart';
import 'package:flutter/material.dart';

// ============================================================================
// FUNCTION 1: FILTER BOTTOM SHEET
// ============================================================================
Future<void> showFilterBottomSheet({
  required BuildContext context,
  required FilterType currentValue,
  required ValueChanged<FilterType> onChanged,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag indicator
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter by',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Options wrapped in the new RadioGroup to fix deprecations
                RadioGroup<FilterType>(
                  groupValue: currentValue,
                  onChanged: (FilterType? value) {
                    if (value != null) {
                      onChanged(value);
                      Navigator.pop(context);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterOption(
                        context: context,
                        title: 'Unread',
                        value: FilterType.unread,
                        currentValue: currentValue,
                        onTap: () {
                          onChanged(FilterType.unread);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildFilterOption(
                        context: context,
                        title: 'Reading',
                        value: FilterType.reading,
                        currentValue: currentValue,
                        onTap: () {
                          onChanged(FilterType.reading);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildFilterOption(
                        context: context,
                        title: 'Read',
                        value: FilterType.read,
                        currentValue: currentValue,
                        onTap: () {
                          onChanged(FilterType.read);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Helper widget for Filter Options (No Icons)
Widget _buildFilterOption({
  required BuildContext context,
  required String title,
  required FilterType value,
  required FilterType currentValue,
  required VoidCallback onTap,
}) {
  final isSelected = value == currentValue;
  final colorScheme = Theme.of(context).colorScheme;

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
          // Radio<FilterType>(value: value, activeColor: colorScheme.primary),
        ],
      ),
    ),
  );
}

// ============================================================================
// FUNCTION 2: SORT BOTTOM SHEET
// ============================================================================
Future<void> showSortBottomSheet({
  required BuildContext context,
  required OrderType currentSort,
  required bool isBottomUp,
  required Function(OrderType, bool) onApply,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      // Temporary state for the bottom sheet
      OrderType tempSort = currentSort;
      bool tempBottomUp = isBottomUp;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final colorScheme = Theme.of(context).colorScheme;

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag indicator
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sort by',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sort Options wrapped in RadioGroup
                    RadioGroup<OrderType>(
                      groupValue: tempSort,
                      onChanged: (OrderType? value) {
                        if (value != null) {
                          setModalState(() => tempSort = value);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSortOption(
                            context: context,
                            title: 'Creation date',
                            icon: Icons.calendar_today_rounded,
                            value: OrderType.creationDate,
                            currentValue: tempSort,
                            onTap: () => setModalState(
                              () => tempSort = OrderType.creationDate,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSortOption(
                            context: context,
                            title: 'Alphabetical',
                            icon: Icons.sort_by_alpha_rounded,
                            value: OrderType.name,
                            currentValue: tempSort,
                            onTap: () =>
                                setModalState(() => tempSort = OrderType.name),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(),
                    ),

                    // Bottom Up Checkbox
                    InkWell(
                      onTap: () =>
                          setModalState(() => tempBottomUp = !tempBottomUp),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_downward_rounded,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Switch direction',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Checkbox(
                              value: tempBottomUp,
                              activeColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (bool? value) {
                                if (value != null) {
                                  setModalState(() => tempBottomUp = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          onApply(tempSort, tempBottomUp);
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// Helper widget for Sort Options
Widget _buildSortOption({
  required BuildContext context,
  required String title,
  required IconData icon,
  required OrderType value,
  required OrderType currentValue,
  required VoidCallback onTap,
}) {
  final isSelected = value == currentValue;
  final colorScheme = Theme.of(context).colorScheme;

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
          Radio<OrderType>(value: value, activeColor: colorScheme.primary),
        ],
      ),
    ),
  );
}
