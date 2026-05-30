import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/bus_route.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/search_view_model.dart';
import '../../widgets/loading_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.title, this.onRouteSelected});

  final String? title;
  final Future<void> Function(BusRoute route)? onRouteSelected;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchViewModel>().loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewModel = context.watch<SearchViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? l10n.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: viewModel.searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.clear,
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _controller.clear();
                              context.read<SearchViewModel>().clearSearch();
                            },
                          ),
                  ),
                  onChanged: context.read<SearchViewModel>().search,
                ),
                const SizedBox(height: AppSpacing.md),
                _FilterChips(selectedFilter: viewModel.selectedFilter),
              ],
            ),
          ),
          Expanded(
            child: _SearchBody(
              viewModel: viewModel,
              onRouteSelected: widget.onRouteSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.viewModel, required this.onRouteSelected});

  final SearchViewModel viewModel;
  final Future<void> Function(BusRoute route)? onRouteSelected;

  @override
  Widget build(BuildContext context) {
    if (viewModel.searchQuery.isEmpty) {
      return _RecentSearches(
        searches: viewModel.recentSearches,
        onSelected: (query) =>
            context.read<SearchViewModel>().useRecentSearch(query),
      );
    }
    if (viewModel.isLoading) {
      return const LoadingWidget();
    }
    if (viewModel.filteredRoutes.isEmpty) {
      return const _EmptySearchState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      itemCount: viewModel.filteredRoutes.length,
      itemBuilder: (context, index) {
        final route = viewModel.filteredRoutes[index];
        return _SearchResultCard(
          route: route,
          onTap: () async {
            if (onRouteSelected != null) {
              await onRouteSelected!(route);
              return;
            }
            if (!context.mounted) {
              return;
            }
            context.push('${RouteNames.routeDetail}/${route.id}');
          },
        );
      },
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selectedFilter});

  final RouteSearchFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        Semantics(
          button: true,
          selected: selectedFilter == RouteSearchFilter.all,
          child: FilterChip(
            label: Text(l10n.all),
            selected: selectedFilter == RouteSearchFilter.all,
            onSelected: (_) => context.read<SearchViewModel>().applyFilter(
              RouteSearchFilter.all,
            ),
          ),
        ),
        Semantics(
          button: true,
          selected: selectedFilter == RouteSearchFilter.airConOnly,
          child: FilterChip(
            label: Text(l10n.airConOnly),
            selected: selectedFilter == RouteSearchFilter.airConOnly,
            onSelected: (_) => context.read<SearchViewModel>().applyFilter(
              RouteSearchFilter.airConOnly,
            ),
          ),
        ),
        Semantics(
          button: true,
          selected: selectedFilter == RouteSearchFilter.regular,
          child: FilterChip(
            label: Text(l10n.regular),
            selected: selectedFilter == RouteSearchFilter.regular,
            onSelected: (_) => context.read<SearchViewModel>().applyFilter(
              RouteSearchFilter.regular,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.searches, required this.onSelected});

  final List<String> searches;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (searches.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: searches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.recentSearches,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }
        final search = searches[index - 1];
        return ListTile(
          minLeadingWidth: 48,
          leading: const Icon(Icons.history),
          title: Text(search),
          onTap: () => onSelected(search),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.route, required this.onTap});

  final BusRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final routeColor = _parseHexColor(route.color);

    return Semantics(
      button: true,
      label: '${route.routeNumber}, ${route.name}',
      child: Card(
        child: ListTile(
          onTap: onTap,
          minLeadingWidth: 48,
          leading: SizedBox(
            width: 72,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: routeColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  route.routeNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          title: Text(route.name),
          subtitle: Text(
            '${route.startStop} → ${route.endStop}\n'
            '${l10n.fareKyat(route.farePrice.toStringAsFixed(0))}',
          ),
          isThreeLine: true,
          trailing: Semantics(
            label: route.isAirCon ? l10n.airConOnly : l10n.regular,
            child: Icon(
              route.isAirCon ? Icons.ac_unit : Icons.directions_bus_outlined,
              color: route.isAirCon ? Colors.blue : null,
            ),
          ),
        ),
      ),
    );
  }

  Color _parseHexColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.noSearchResults, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.tryDifferentSearch, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
