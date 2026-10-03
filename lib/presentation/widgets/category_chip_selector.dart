import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class CategoryChipSelector extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryChipSelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.defaultCategories;
    final current = selectedCategory ?? 'Tất cả';

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == current;

          return ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.8),
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: Theme.of(context).cardColor,
            elevation: isSelected ? 2 : 0,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).dividerColor.withValues(alpha: 0.4),
              ),
            ),
            onSelected: (selected) {
              if (selected) {
                onCategorySelected(cat == 'Tất cả' ? null : cat);
              }
            },
          );
        },
      ),
    );
  }
}
