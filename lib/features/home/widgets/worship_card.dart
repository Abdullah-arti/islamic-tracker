// lib/features/home/widgets/worship_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class WorshipCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool isChecked;
  final ValueChanged<bool> onChanged;
  final bool isFullWidth;

  const WorshipCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isChecked,
    required this.onChanged,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isChecked
            ? const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : null,
        color: isChecked ? null : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isChecked
                ? AppTheme.primaryGreen.withOpacity(0.3)
                : Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isChecked
              ? AppTheme.lightGreen
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!isChecked),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isFullWidth ? 14 : 18,
          ),
          child: isFullWidth
              ? Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: isChecked
                                  ? Colors.white
                                  : AppTheme.primaryGreen,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 13,
                              color: isChecked
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCheckIcon(),
                  ],
                )
              : Column(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: isChecked ? Colors.white : AppTheme.primaryGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12,
                        color: isChecked ? Colors.white70 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    _buildCheckIcon(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCheckIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isChecked
          ? Container(
              key: const ValueKey('checked'),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            )
          : Container(
              key: const ValueKey('unchecked'),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 20, height: 20),
            ),
    );
  }
}
