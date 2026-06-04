import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/bus_stop.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/trip_planner_view_model.dart';
import '../../widgets/app_shell.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripPlannerViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewModel = context.watch<TripPlannerViewModel>();

    return AppShell(
      title: l10n.tripPlanner,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _StopPicker(
                  label: l10n.fromStop,
                  stops: viewModel.stops,
                  onSelected: context.read<TripPlannerViewModel>().setOrigin,
                ),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  button: true,
                  label: 'Swap stops',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.swap_vert),
                      onPressed: context.read<TripPlannerViewModel>().swapStops,
                    ),
                  ),
                ),
                _StopPicker(
                  label: l10n.toStop,
                  stops: viewModel.stops,
                  onSelected: context
                      .read<TripPlannerViewModel>()
                      .setDestination,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: viewModel.isLoading
                        ? null
                        : context.read<TripPlannerViewModel>().findRoutes,
                    icon: const Icon(Icons.route),
                    label: Text(l10n.findRoutes),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: viewModel.results.isEmpty
                ? Center(child: Text(l10n.noTripResults))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount:
                        viewModel.results.length +
                        (viewModel.resultNote == null ? 0 : 1),
                    itemBuilder: (context, index) {
                      final note = viewModel.resultNote;
                      if (note != null && index == 0) {
                        return _LimitedResultsNote(note: note);
                      }
                      final resultIndex = note == null ? index : index - 1;
                      return _TripResultCard(
                        result: viewModel.results[resultIndex],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LimitedResultsNote extends StatelessWidget {
  const _LimitedResultsNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            note,
            style: TextStyle(color: colorScheme.onSecondaryContainer),
          ),
        ),
      ),
    );
  }
}

class _StopPicker extends StatelessWidget {
  const _StopPicker({
    required this.label,
    required this.stops,
    required this.onSelected,
  });

  final String label;
  final List<BusStop> stops;
  final ValueChanged<BusStop> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<BusStop>(
      displayStringForOption: (stop) => stop.name,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) {
          return stops.take(8);
        }
        return stops.where((stop) {
          return stop.name.toLowerCase().contains(query) ||
              stop.landmark.toLowerCase().contains(query);
        });
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        );
      },
    );
  }
}

class _TripResultCard extends StatelessWidget {
  const _TripResultCard({required this.result});

  final TripPlanResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final routeNumbers = result.routes
        .map((route) => route.routeNumber)
        .join(' → ');

    return Card(
      child: ListTile(
        minLeadingWidth: 48,
        leading: Icon(
          result.isDirect ? Icons.directions_bus : Icons.compare_arrows,
        ),
        title: Text(result.isDirect ? l10n.directRoute : l10n.transferRoute),
        subtitle: Text(
          [
            routeNumbers,
            if (result.transferStop != null)
              l10n.changeAt(result.transferStop!.name),
            l10n.stopsCount(result.estimatedStops),
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: Text(l10n.fareKyat(result.totalFare.toStringAsFixed(0))),
      ),
    );
  }
}
