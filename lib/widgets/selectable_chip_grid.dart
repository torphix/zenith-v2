import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class SelectableChipGrid extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final int crossAxisCount;

  const SelectableChipGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onToggle(option);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? ZenithColors.primary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? ZenithColors.primary.withValues(alpha: 0.4)
                    : ZenithColors.cardBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              option,
              style: ZenithTheme.dmSans(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? ZenithColors.primary
                    : ZenithColors.text,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
