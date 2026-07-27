import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class SegmentedPillItem {
  final String label;
  final IconData? icon;

  const SegmentedPillItem({required this.label, this.icon});
}

class SegmentedPillNav extends StatelessWidget {
  final List<String>? options;
  final List<SegmentedPillItem>? items;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final ValueChanged<int>? onItemSelected;

  const SegmentedPillNav({
    super.key,
    this.options,
    this.items,
    required this.selectedIndex,
    this.onSelected,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final itemList = items ?? options?.map((o) => SegmentedPillItem(label: o)).toList() ?? [];
    final callback = onSelected ?? onItemSelected ?? (_) {};

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.cardDarkGlass.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.accentEmeraldLight.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: List.generate(itemList.length, (idx) {
          final isSelected = idx == selectedIndex;
          final item = itemList[idx];

          return Expanded(
            child: GestureDetector(
              onTap: () => callback(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  gradient: isSelected ? GerexGradients.primaryCTA : null,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accentEmeraldLight.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textDarkBody.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textDarkBody.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
