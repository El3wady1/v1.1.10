import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard  extends StatelessWidget {
  final String label;
  final String value;
  final IconData? prefixIcon;
  final Color? labelColor;
  final Color? valueColor;
  final double? labelSize;
  final double? valueSize;
  final FontWeight? labelWeight;
  final FontWeight? valueWeight;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool? isCompact;

  const ProductCard ({
    required this.label,
    required this.value,
    this.prefixIcon,
    this.labelColor,
    this.valueColor,
    this.labelSize = 13,
    this.valueSize = 12,
    this.labelWeight = FontWeight.w600,
    this.valueWeight = FontWeight.w400,
    this.padding,
    this.onTap,
    this.isCompact = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: theme.primaryColor.withOpacity(0.1),
      highlightColor: theme.primaryColor.withOpacity(0.05),
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor.withOpacity(0.8) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isDark ? null : Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: isCompact! ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefixIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  prefixIcon,
                  color: theme.primaryColor,
                  size: 14,
                ),
              ),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontWeight: labelWeight,
                  fontSize: labelSize,
                  color: labelColor ?? (isDark ? Colors.white70 : Colors.grey.shade700),
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: valueSize,
                  fontWeight: valueWeight,
                  color: valueColor ?? (isDark ? Colors.white : Colors.grey.shade800),
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}