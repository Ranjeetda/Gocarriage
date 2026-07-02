import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gocarriage_universal/resource/image_paths.dart';

enum StatusType { success, error }
Future<T?> showStatusDialog<T>(
    BuildContext context, {
      required StatusType type,
      required String title,
      required String message,
      required String primaryLabel,
      VoidCallback? onPrimary,
      String? secondaryLabel,
      VoidCallback? onSecondary,
    }) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'status',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.9 + 0.1 * curved.value,
          child: Center(
            child: StatusDialog(
              type: type,
              title: title,
              message: message,
              primaryLabel: primaryLabel,
              onPrimary: onPrimary ?? () => Navigator.of(ctx).pop(),
              secondaryLabel: secondaryLabel,
              onSecondary: onSecondary,
            ),
          ),
        ),
      );
    },
  );
}

class StatusDialog extends StatefulWidget {
  const StatusDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final StatusType type;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  bool get isSuccess => type == StatusType.success;

  @override
  State<StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<StatusDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _accentA =>
      widget.isSuccess ? const Color(0xFF6FD39B) : const Color(0xFFF07474);
  Color get _accentB =>
      widget.isSuccess ? const Color(0xFF3FA877) : const Color(0xFFD8433F);
  Color get _glow => widget.isSuccess
      ? const Color(0xFFF0781E) // warm orange glow for success
      : const Color(0xFFD8433F);

  static const double _ring = 116;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: 340,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // ---- Card ----
            Padding(
              padding: const EdgeInsets.only(top: _ring / 2),
              child: _Card(
                glow: _glow,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: _ring / 2 + 16),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: Colors.white.withOpacity(0.66),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _PillButton(
                      label: widget.primaryLabel,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: widget.isSuccess
                            ? const [Color(0xFFF79A3C), Color(0xFFEF7A1E)]
                            : const [Color(0xFFF07474), Color(0xFFDC4B47)],
                      ),
                      shadowColor: widget.isSuccess
                          ? const Color(0xFFEF7A1E)
                          : const Color(0xFFDC4B47),
                      onTap: widget.onPrimary,
                    ),
                    if (widget.secondaryLabel != null) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.onSecondary,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: Colors.white.withOpacity(0.7),
                        ),
                        child: Text(
                          widget.secondaryLabel!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ---- Icon circle + pulse rings ----
            SizedBox(
              width: _ring,
              height: _ring,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      _pulseRing(_pulse.value),
                      _pulseRing((_pulse.value + 0.5) % 1.0),
                      child!,
                    ],
                  );
                },
                child: Container(
                  width: _ring,
                  height: _ring,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_accentA, _accentB],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accentB.withOpacity(0.45),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isSuccess ? Icons.check_rounded : Icons.close_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulseRing(double t) {
    final scale = 0.75 + t * 0.95;
    final opacity = (1 - t) * 0.45;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: _ring,
        height: _ring,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _accentB.withOpacity(opacity.clamp(0.0, 1.0)),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.glow});
  final Widget child;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          // base gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xF5423A34), Color(0xF5302A26)],
                ),
              ),
            ),
          ),
          // warm corner glow
          Positioned(
            right: -20,
            bottom: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [glow.withOpacity(0.42), glow.withOpacity(0.0)],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.fromLTRB(30, 16, 30, 32),
            child: child,
          ),
        ],
      ),
    );
  }
}


class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.gradient,
    required this.shadowColor,
    this.onTap,
  });

  final String label;
  final Gradient gradient;
  final Color shadowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
