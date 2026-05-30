import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_names.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/favorites_view_model.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewModel = context.watch<FavoritesViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favorites)),
      body: viewModel.favoriteItems.isEmpty
          ? const _EmptyFavoritesState()
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: viewModel.favoriteItems.length,
              onReorderItem: viewModel.reorderFavorites,
              itemBuilder: (context, index) {
                final item = viewModel.favoriteItems[index];
                return Dismissible(
                  key: ValueKey(item.favorite.routeId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    color: AppColors.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await viewModel.removeFavorite(item.favorite.routeId);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.removedFromFavorites),
                        action: SnackBarAction(
                          label: l10n.undo,
                          onPressed: () =>
                              viewModel.restoreFavorite(item.favorite),
                        ),
                      ),
                    );
                  },
                  child: Semantics(
                    button: true,
                    label: item.route.name,
                    child: Card(
                      child: ListTile(
                        onTap: () => context.push(
                          '${RouteNames.routeDetail}/${item.route.id}',
                        ),
                        minLeadingWidth: 48,
                        leading: CircleAvatar(
                          child: Text(item.route.routeNumber),
                        ),
                        title: Text(item.favorite.nickname ?? item.route.name),
                        subtitle: Text(
                          '${item.route.startStop} → ${item.route.endStop}',
                        ),
                        trailing: const Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  const _EmptyFavoritesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context).noFavorites,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
