import 'package:flutter/material.dart';
import '../theme/reparo_theme.dart';

enum BadgeVariant { success, error, warning, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;

    switch (variant) {
      case BadgeVariant.success:
        textColor = ReparoTheme.statusSuccess;
        bgColor = ReparoTheme.statusSuccessBg;
        break;
      case BadgeVariant.error:
        textColor = ReparoTheme.statusError;
        bgColor = ReparoTheme.statusErrorBg;
        break;
      case BadgeVariant.warning:
        textColor = ReparoTheme.statusWarning;
        bgColor = ReparoTheme.statusWarningBg;
        break;
      case BadgeVariant.neutral:
        textColor = ReparoTheme.statusNeutral;
        bgColor = ReparoTheme.statusNeutralBg;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
          fontFamily: ReparoTheme.fontSans,
        ),
      ),
    );
  }
}

