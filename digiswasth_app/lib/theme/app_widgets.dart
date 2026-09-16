import 'package:flutter/material.dart';
import 'app_theme.dart';

class NightCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const NightCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: StatusColors.of(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StatusColors.of(status)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: StatusColors.of(status),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}