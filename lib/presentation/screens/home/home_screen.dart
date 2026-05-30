import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/bus_route.dart';
import '../../../data/models/bus_stop.dart';
import '../../viewmodels/home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const LatLng _yangonCenter = LatLng(16.8661, 96.1951);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final routes = viewModel.routes;
    final recentRoutes = viewModel.recentRoutes;
    final popularRoutes = viewModel.popularRoutes;

    return Stack(
      children: [
        _MapBackdrop(routes: routes),
        const _TopBrandBar(),
        _FloatingRouteBadges(routes: routes),
        DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.48,
          maxChildSize: 0.82,
          builder: (context, scrollController) {
            return _HomePanel(
              scrollController: scrollController,
              recentRoutes: recentRoutes,
              popularRoutes: popularRoutes,
              routes: routes,
              isLoading: viewModel.isLoading,
              onRefresh: viewModel.refresh,
            );
          },
        ),
      ],
    );
  }
}

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop({required this.routes});

  final List<BusRoute> routes;

  @override
  Widget build(BuildContext context) {
    final polylines = routes
        .where((route) => route.routePath.length > 1)
        .take(4)
        .map(
          (route) => Polyline(
            points: route.routePath
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList(),
            color: _routeColor(route).withValues(alpha: 0.78),
            strokeWidth: 4,
          ),
        )
        .toList();

    final markers = routes
        .expand((route) => route.stops)
        .take(18)
        .map(
          (stop) => Marker(
            point: LatLng(stop.latitude, stop.longitude),
            width: 42,
            height: 42,
            child: _StopMarker(stop: stop),
          ),
        )
        .toList();

    return FlutterMap(
      options: const MapOptions(
        initialCenter: HomeScreen._yangonCenter,
        initialZoom: 13.2,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ybsguide.mm',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}

class _TopBrandBar extends StatelessWidget {
  const _TopBrandBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.menu_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () => context.push(RouteNames.settings),
                ),
                const SizedBox(width: 2),
                const _YbsLogo(size: 42),
                const SizedBox(width: 10),
                Text(
                  AppConstants.appNameEn,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingRouteBadges extends StatelessWidget {
  const _FloatingRouteBadges({required this.routes});

  final List<BusRoute> routes;

  @override
  Widget build(BuildContext context) {
    final badges = routes.take(5).toList();
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.only(top: 130),
        child: Align(
          alignment: Alignment.topCenter,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final route in badges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _routeColor(route),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    route.routeNumber.replaceFirst('YBS-', 'Y'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({
    required this.scrollController,
    required this.recentRoutes,
    required this.popularRoutes,
    required this.routes,
    required this.isLoading,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final List<BusRoute> recentRoutes;
  final List<BusRoute> popularRoutes;
  final List<BusRoute> routes;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: const Color(0x26000000),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DBD7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const _YbsLogo(size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppConstants.appNameEn,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF118C7B),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SearchBar(
              onSearchTap: () => context.go(RouteNames.search),
              onMapTap: () => context.go(RouteNames.map),
            ),
            const SizedBox(height: 18),
            Text('Quick Access', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _QuickAccessRoutes(routes: recentRoutes, fallbackRoutes: routes),
            const SizedBox(height: 18),
            Text('Nearby Stops', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _NearbyStopCards(routes: routes),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Routes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => context.go(RouteNames.search),
                  child: const Text('See all'),
                ),
              ],
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (final route in popularRoutes.take(4))
                _RouteTile(
                  route: route,
                  onTap: () =>
                      context.push('${RouteNames.routeDetail}/${route.id}'),
                ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onSearchTap, required this.onMapTap});

  final VoidCallback onSearchTap;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Search route or destination',
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onSearchTap,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF118C7B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'WHERE TO?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Icon(Icons.mic_none_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          height: 52,
          child: IconButton.filled(
            tooltip: 'Open map',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF118C7B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onMapTap,
            icon: const Icon(Icons.map_outlined, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessRoutes extends StatelessWidget {
  const _QuickAccessRoutes({
    required this.routes,
    required this.fallbackRoutes,
  });

  final List<BusRoute> routes;
  final List<BusRoute> fallbackRoutes;

  @override
  Widget build(BuildContext context) {
    final items = (routes.isEmpty ? fallbackRoutes : routes).take(2).toList();
    if (items.isEmpty) {
      return const Text('No recent routes yet');
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _QuickAccessCard(route: items[i], index: i),
          ),
        ],
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.route, required this.index});

  final BusRoute route;
  final int index;

  @override
  Widget build(BuildContext context) {
    final label = index == 0 ? 'Home' : 'Work';

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => context.push('${RouteNames.routeDetail}/${route.id}'),
      child: Container(
        height: 78,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE4F4EF),
              child: Icon(
                index == 0 ? Icons.home_rounded : Icons.work_rounded,
                color: const Color(0xFF118C7B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    route.routeNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA49D)),
          ],
        ),
      ),
    );
  }
}

class _NearbyStopCards extends StatelessWidget {
  const _NearbyStopCards({required this.routes});

  final List<BusRoute> routes;

  @override
  Widget build(BuildContext context) {
    final stops = routes.expand((route) => route.stops).take(2).toList();
    if (stops.isEmpty) {
      return const Text('Nearby stops will appear here');
    }

    return Column(
      children: [
        for (final stop in stops)
          _NearbyStopCard(stop: stop, routeNumber: _routeForStop(routes, stop)),
      ],
    );
  }
}

class _NearbyStopCard extends StatelessWidget {
  const _NearbyStopCard({required this.stop, required this.routeNumber});

  final BusStop stop;
  final String routeNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked, color: Color(0xFF118C7B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text('$routeNumber - 2 min'),
              ],
            ),
          ),
          Container(
            width: 108,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF118C7B),
                  Color(0xFFF2C94C),
                  Color(0xFFE65245),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({required this.route, required this.onTap});

  final BusRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 48,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _routeColor(route),
        child: Text(
          route.routeNumber.replaceFirst('YBS-', ''),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(route.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${route.startStop} -> ${route.endStop}'),
      trailing: Text('${route.farePrice.toStringAsFixed(0)} MMK'),
    );
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({required this.stop});

  final BusStop stop;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: stop.name,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE7F5EF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF118C7B), width: 2),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.directions_bus_filled_rounded,
          size: 17,
          color: Color(0xFF118C7B),
        ),
      ),
    );
  }
}

class _YbsLogo extends StatelessWidget {
  const _YbsLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'YBS Guide logo',
      image: true,
      child: ClipOval(
        child: Image.asset(
          AppConstants.ybsLogoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

Color _routeColor(BusRoute route) {
  final hex = route.color.replaceFirst('#', '');
  final value = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  return Color(value ?? AppColors.primary.toARGB32());
}

String _routeForStop(List<BusRoute> routes, BusStop stop) {
  for (final route in routes) {
    if (route.stops.any((candidate) => candidate.id == stop.id)) {
      return route.routeNumber;
    }
  }
  return 'YBS';
}
