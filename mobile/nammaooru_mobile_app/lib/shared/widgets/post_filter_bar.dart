import 'package:flutter/material.dart';
import '../../core/theme/village_theme.dart';

class PostFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final double? selectedRadius;
  final ValueChanged<double?> onRadiusChanged;
  final String searchText;
  final ValueChanged<String> onSearchSubmitted;
  final Color accentColor;
  final String Function(String)? categoryLabelBuilder;

  const PostFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedRadius,
    required this.onRadiusChanged,
    this.searchText = '',
    required this.onSearchSubmitted,
    this.accentColor = VillageTheme.primaryGreen,
    this.categoryLabelBuilder,
  });

  static const List<_RadiusOption> radiusOptions = [
    _RadiusOption(5, '5 km'),
    _RadiusOption(10, '10 km'),
    _RadiusOption(25, '25 km'),
    _RadiusOption(50, '50 km'),
    _RadiusOption(100, '100 km'),
    _RadiusOption(null, 'All'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: TextEditingController(text: searchText)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: searchText.length),
                  ),
                decoration: InputDecoration(
                  hintText: 'Search by location...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                          onPressed: () => onSearchSubmitted(''),
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.search,
                onSubmitted: onSearchSubmitted,
              ),
            ),
          ),
          // Radius + Category chips row
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Radius dropdown
                _buildRadiusChip(context),
                const SizedBox(width: 8),
                // Category chips
                ...categories.map((cat) {
                  final isSelected = (selectedCategory == null && cat == categories.first) ||
                      selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(categoryLabelBuilder?.call(cat) ?? cat),
                      selected: isSelected,
                      onSelected: (_) => onCategoryChanged(cat == categories.first ? null : cat),
                      selectedColor: accentColor.withOpacity(0.2),
                      checkmarkColor: accentColor,
                      labelStyle: TextStyle(
                        color: isSelected ? accentColor : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildRadiusChip(BuildContext context) {
    final currentOption = radiusOptions.firstWhere(
      (o) => o.value == selectedRadius,
      orElse: () => radiusOptions[3], // default 50km
    );
    return PopupMenuButton<double?>(
      onSelected: onRadiusChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => radiusOptions.map((option) {
        return PopupMenuItem<double?>(
          value: option.value,
          child: Row(
            children: [
              if (option.value == selectedRadius)
                Icon(Icons.check, size: 16, color: accentColor)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(option.label),
            ],
          ),
        );
      }).toList(),
      child: Chip(
        avatar: Icon(Icons.my_location, size: 16, color: accentColor),
        label: Text(
          currentOption.label,
          style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: accentColor.withOpacity(0.1),
        side: BorderSide(color: accentColor.withOpacity(0.3)),
      ),
    );
  }
}

class _RadiusOption {
  final double? value;
  final String label;
  const _RadiusOption(this.value, this.label);
}
