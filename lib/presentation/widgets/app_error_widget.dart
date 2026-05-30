import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    required this.onRetry,
    this.title,
    this.message,
    super.key,
  });

  final String? title;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              title ?? l10n.networkErrorTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ?? l10n.networkErrorMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              button: true,
              label: l10n.retry,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
