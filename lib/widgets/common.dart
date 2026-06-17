import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// Shared UI helpers — keeps screens consistent,
// dark-mode correct, and student-friendly.
// ─────────────────────────────────────────────

/// Time-aware Indonesian greeting (Pagi / Siang / Sore / Malam).
String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 11) return 'Selamat Pagi';
  if (h < 15) return 'Selamat Siang';
  if (h < 18) return 'Selamat Sore';
  return 'Selamat Malam';
}

/// Icon that matches the time of day, for a touch of personality.
IconData greetingIcon([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 11) return Icons.wb_twilight_rounded;
  if (h < 15) return Icons.wb_sunny_rounded;
  if (h < 18) return Icons.wb_cloudy_rounded;
  return Icons.nightlight_round;
}

/// Color that reflects an attendance percentage health band.
Color attendanceColor(num pct) {
  if (pct >= 75) return AppColors.success;
  if (pct >= 50) return AppColors.warning;
  return AppColors.error;
}

/// Adaptive shimmer wrapper so the skeleton matches the active theme
/// instead of always rendering light-grey blocks on a dark background.
class AdaptiveShimmer extends StatelessWidget {
  final Widget child;
  const AdaptiveShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.surfaceVariantDark
          : const Color(0xFFE2E8F0),
      highlightColor: isDark
          ? AppColors.dividerDark
          : const Color(0xFFF8FAFC),
      child: child,
    );
  }
}

/// A simple rounded skeleton block for use inside [AdaptiveShimmer].
class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Animated circular attendance ring with the percentage in the center.
/// Far more glanceable than a flat linear bar — the headline metric students
/// and lecturers check first.
class AttendanceRing extends StatelessWidget {
  final double percentage;
  final double size;
  final double stroke;
  final String? caption;
  const AttendanceRing({
    super.key,
    required this.percentage,
    this.size = 96,
    this.stroke = 9,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final color = attendanceColor(percentage);
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0, end: (percentage / 100).clamp(0.0, 1.0)),
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: stroke,
                  strokeCap: StrokeCap.round,
                  backgroundColor: track,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: TextStyle(
                        fontSize: size * 0.11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutral,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Section label with a small accent bar — gives clear visual hierarchy
/// between the dense sections of a dashboard.
class SectionHeader extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionHeader(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.neutral,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Compact quick-action button (icon pill + label) used on dashboard
/// action rows. Wrap in a [Row]; it expands to share width equally.
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: PressableCard(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable card wrapper that adds a subtle press-scale micro-interaction,
/// matching modern mobile feel without shifting layout bounds.
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(margin: widget.margin, child: widget.child),
      ),
    );
  }
}
