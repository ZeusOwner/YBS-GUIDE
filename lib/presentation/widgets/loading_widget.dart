import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({this.itemCount = 5, super.key});

  final int itemCount;

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.loading,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final opacity = 0.45 + (_controller.value * 0.35);
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: widget.itemCount,
            itemBuilder: (context, index) {
              return Opacity(opacity: opacity, child: const _SkeletonTile());
            },
          );
        },
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(width: 48, height: 48, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, color: color),
                  const SizedBox(height: AppSpacing.sm),
                  Container(height: 12, width: 180, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
