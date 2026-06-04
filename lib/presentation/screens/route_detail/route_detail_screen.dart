import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/bus_route.dart';
import '../../../data/models/bus_stop.dart';
import '../../../data/models/schedule.dart';
import '../../viewmodels/favorites_view_model.dart';
import '../../viewmodels/route_detail_view_model.dart';

class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({required this.routeId, super.key});

  final String routeId;

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          context.read<RouteDetailViewModel>().selectTab(_tabController.index);
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteDetailViewModel>().load(widget.routeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RouteDetailViewModel>();
    final favorites = context.watch<FavoritesViewModel>();
    final route = viewModel.route;

    return Scaffold(
      appBar: AppBar(
        title: Text(route?.routeNumber ?? AppStrings.routes),
        actions: [
          if (route != null)
            IconButton(
              tooltip: 'Favorite',
              icon: Icon(
                favorites.favoriteIds.contains(route.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              onPressed: () => favorites.toggle(route.id),
            ),
          if (route != null)
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.ios_share),
              onPressed: () => _shareRoute(context, route),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'လမ်းမှတ်တိုင်'),
            Tab(text: 'အချိန်ဇယား'),
            Tab(text: 'မြေပုံ'),
          ],
        ),
      ),
      body: viewModel.isLoading || route == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _RouteHeader(route: route),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _StopsTab(route: route),
                      _ScheduleTab(viewModel: viewModel),
                      _MapTab(route: route),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _shareRoute(BuildContext context, BusRoute route) async {
    final text =
        '${route.routeNumber}: ${route.name}\n${route.startStop} → ${route.endStop}\n${route.farePrice.toStringAsFixed(0)} MMK';
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route details copied / လမ်းကြောင်းကို ကူးယူပြီးပါပြီ'),
      ),
    );
  }
}

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.route});

  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    final color = _parseHexColor(route.color);
    final firstSchedule = route.schedule.isEmpty ? null : route.schedule.first;

    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route.routeNumber,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            route.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _DataConfidenceBadge(confidence: route.dataConfidence),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(label: '${route.farePrice.toStringAsFixed(0)} MMK'),
              _InfoChip(label: route.isAirCon ? 'Air-con' : 'Regular'),
              if (firstSchedule != null)
                _InfoChip(
                  label: '${firstSchedule.firstBus} - ${firstSchedule.lastBus}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  }
}

class _DataConfidenceBadge extends StatelessWidget {
  const _DataConfidenceBadge({required this.confidence});

  final DataConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final config = switch (confidence) {
      DataConfidence.terminalOnly => (
        label: 'Terminal data only - intermediate stops not available',
        background: Colors.orange.shade100,
        foreground: Colors.orange.shade900,
      ),
      DataConfidence.estimated => (
        label: 'Stop data from community sources',
        background: Colors.blue.shade50,
        foreground: Colors.blue.shade900,
      ),
      DataConfidence.verified => (
        label: 'Verified route data',
        background: Colors.green.shade50,
        foreground: Colors.green.shade900,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          config.label,
          style: TextStyle(fontSize: 11, color: config.foreground),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      backgroundColor: colorScheme.surface,
      labelStyle: TextStyle(color: colorScheme.primary),
    );
  }
}

class _StopsTab extends StatelessWidget {
  const _StopsTab({required this.route});

  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: route.stops.length,
      itemBuilder: (context, index) {
        final stop = route.stops[index];
        final isFirst = index == 0;
        final isLast = index == route.stops.length - 1;
        return InkWell(
          onTap: () {
            context.read<RouteDetailViewModel>().selectStop(stop);
            _showStopRoutes(context, stop);
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isFirst
                              ? Colors.transparent
                              : AppColors.primary,
                        ),
                      ),
                      Icon(
                        isFirst || isLast
                            ? Icons.flag_circle
                            : Icons.radio_button_checked,
                        color: isFirst || isLast
                            ? AppColors.secondary
                            : AppColors.primary,
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isLast
                              ? Colors.transparent
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Card(
                    child: ListTile(
                      title: Text(stop.name),
                      subtitle: Text(stop.landmark),
                      trailing: const Icon(Icons.info_outline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStopRoutes(BuildContext context, BusStop stop) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(stop.landmark),
              const SizedBox(height: AppSpacing.md),
              Text('Passing routes / ဖြတ်သန်းသော လမ်းကြောင်းများ'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final routeId in stop.routes) Chip(label: Text(routeId)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({required this.viewModel});

  final RouteDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final schedule = viewModel.selectedSchedule;
    final nextDeparture = viewModel.nextDeparture;

    if (schedule == null) {
      return const Center(child: Text('အချိန်ဇယား မရှိသေးပါ'));
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SegmentedButton<RouteDirection>(
          segments: const [
            ButtonSegment(
              value: RouteDirection.forward,
              label: Text('Forward'),
            ),
            ButtonSegment(value: RouteDirection.reverse, label: Text('Return')),
          ],
          selected: {viewModel.selectedDirection},
          onSelectionChanged: (selection) {
            context.read<RouteDetailViewModel>().selectDirection(
              selection.first,
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ScheduleSummaryCard(
                title: 'First Bus',
                value: schedule.firstBus,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ScheduleSummaryCard(
                title: 'Last Bus',
                value: schedule.lastBus,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Departure Times / ထွက်ခွာချိန်များ',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final time in schedule.departureTimes)
              Chip(
                label: Text(time),
                backgroundColor: time == nextDeparture
                    ? AppColors.secondary
                    : Theme.of(context).colorScheme.surface,
              ),
          ],
        ),
      ],
    );
  }
}

class _ScheduleSummaryCard extends StatelessWidget {
  const _ScheduleSummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({required this.route});

  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    final points = route.stops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.isEmpty
            ? const LatLng(16.8409, 96.1735)
            : points.first,
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ybsguide.mm',
        ),
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: AppColors.primary,
                strokeWidth: 5,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final stop in route.stops)
              Marker(
                point: LatLng(stop.latitude, stop.longitude),
                width: 44,
                height: 44,
                child: const Icon(Icons.location_on, color: AppColors.error),
              ),
          ],
        ),
      ],
    );
  }
}
