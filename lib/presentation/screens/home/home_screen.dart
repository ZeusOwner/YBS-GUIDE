import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

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
    final popularRoutes = viewModel.popularRoutes;
    final syncMessage = viewModel.consumeSyncMessage();
    if (syncMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(syncMessage)));
      });
    }

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
              popularRoutes: popularRoutes,
              routes: routes,
              homeRoute: viewModel.homeRoute,
              workRoute: viewModel.workRoute,
              nearbyStops: viewModel.nearbyStops,
              nearbyStopsState: viewModel.nearbyStopsState,
              locationPermissionStatus: viewModel.locationPermissionStatus,
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
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.92),
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
                  color: colorScheme.onSurfaceVariant,
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
    required this.popularRoutes,
    required this.routes,
    required this.homeRoute,
    required this.workRoute,
    required this.nearbyStops,
    required this.nearbyStopsState,
    required this.locationPermissionStatus,
    required this.isLoading,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final List<BusRoute> popularRoutes;
  final List<BusRoute> routes;
  final BusRoute? homeRoute;
  final BusRoute? workRoute;
  final List<NearbyStop> nearbyStops;
  final NearbyStopsState nearbyStopsState;
  final LocationPermission? locationPermissionStatus;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
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
                  color: colorScheme.outlineVariant,
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
              onSearchTap: () => context.push(RouteNames.assistant),
              onMapTap: () => context.go(RouteNames.map),
            ),
            const SizedBox(height: 18),
            Text('Quick Access', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _QuickAccessRoutes(homeRoute: homeRoute, workRoute: workRoute),
            const SizedBox(height: 18),
            Text('Nearby Stops', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _NearbyStopCards(
              state: nearbyStopsState,
              nearbyStops: nearbyStops,
              locationPermissionStatus: locationPermissionStatus,
            ),
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
  const _QuickAccessRoutes({required this.homeRoute, required this.workRoute});

  final BusRoute? homeRoute;
  final BusRoute? workRoute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAccessCard(type: 'home', route: homeRoute),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAccessCard(type: 'work', route: workRoute),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.type, required this.route});

  final String type;
  final BusRoute? route;

  @override
  Widget build(BuildContext context) {
    final isHome = type == 'home';
    final label = isHome ? 'Home' : 'Work';
    final icon = isHome ? Icons.home_rounded : Icons.work_rounded;
    final colorScheme = Theme.of(context).colorScheme;

    if (route == null) {
      return _DashedQuickAccessCard(
        label: isHome ? 'Set Home Route' : 'Set Work Route',
        icon: icon,
        onTap: () => context.push('/select-route/$type'),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => context.push('${RouteNames.routeDetail}/${route!.id}'),
      onLongPress: () => _showQuickAccessOptions(context, type),
      child: Container(
        height: 78,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: colorScheme.outlineVariant),
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
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(icon, color: const Color(0xFF118C7B)),
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
                    route!.routeNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuickAccessOptions(BuildContext context, String type) {
    final viewModel = context.read<HomeViewModel>();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(type == 'work' ? 'Work Route' : 'Home Route'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push('/select-route/$type');
            },
            child: const Text('Change'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              viewModel.clearQuickAccessRoute(type);
            },
            child: const Text('Remove shortcut'),
          ),
        ],
      ),
    );
  }
}

class _DashedQuickAccessCard extends StatelessWidget {
  const _DashedQuickAccessCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: colorScheme.primary),
        child: SizedBox(
          height: 78,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(15),
    );
    final path = ui.Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 8), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _NearbyStopCards extends StatelessWidget {
  const _NearbyStopCards({
    required this.state,
    required this.nearbyStops,
    required this.locationPermissionStatus,
  });

  final NearbyStopsState state;
  final List<NearbyStop> nearbyStops;
  final LocationPermission? locationPermissionStatus;

  @override
  Widget build(BuildContext context) {
    if (state == NearbyStopsState.idle ||
        locationPermissionStatus == null ||
        locationPermissionStatus == LocationPermission.denied ||
        locationPermissionStatus == LocationPermission.unableToDetermine) {
      return _NearbyStopsPermissionCard(
        onTap: () =>
            context.read<HomeViewModel>().requestLocationAndLoadNearbyStops(),
      );
    }

    switch (state) {
      case NearbyStopsState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(child: CircularProgressIndicator()),
        );
      case NearbyStopsState.idle:
        return const SizedBox.shrink();
      case NearbyStopsState.permissionDenied:
        return _NearbyMessage(
          message: 'Location permission is needed to find nearby stops.',
          actionLabel: 'Enable Location',
          onPressed:
              locationPermissionStatus == LocationPermission.deniedForever
              ? () => context.read<HomeViewModel>().openLocationSettings()
              : () => context
                    .read<HomeViewModel>()
                    .requestLocationAndLoadNearbyStops(),
        );
      case NearbyStopsState.empty:
        return const _NearbyMessage(message: 'No stops found within 800m');
      case NearbyStopsState.noLocation:
        return _NearbyMessage(
          message: 'Location unavailable. Try again after setting GPS.',
          actionLabel: 'Retry',
          onPressed: () =>
              context.read<HomeViewModel>().requestLocationAndLoadNearbyStops(),
        );
      case NearbyStopsState.error:
        return _NearbyMessage(
          message: 'Unable to load nearby stops',
          actionLabel: 'Retry',
          onPressed: () =>
              context.read<HomeViewModel>().requestLocationAndLoadNearbyStops(),
        );
      case NearbyStopsState.ready:
        break;
    }

    return Column(
      children: [
        for (final nearbyStop in nearbyStops)
          _NearbyStopCard(nearbyStop: nearbyStop),
      ],
    );
  }
}

class _NearbyStopsPermissionCard extends StatelessWidget {
  const _NearbyStopsPermissionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Enable location to find buses near you',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find buses near you',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Tap to enable location for nearby stops',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyStopCard extends StatelessWidget {
  const _NearbyStopCard({required this.nearbyStop});

  final NearbyStop nearbyStop;

  @override
  Widget build(BuildContext context) {
    final routeText = nearbyStop.routeNumbers.isEmpty
        ? 'YBS'
        : nearbyStop.routeNumbers.join(', ');
    final distance = nearbyStop.distanceMeters >= 1000
        ? '${(nearbyStop.distanceMeters / 1000).toStringAsFixed(1)}km'
        : '${nearbyStop.distanceMeters.round()}m';

    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: nearbyStop.routeIds.isEmpty
          ? null
          : () => context.push(
              '${RouteNames.routeDetail}/${nearbyStop.routeIds.first}',
            ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
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
                    nearbyStop.stop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text('$routeText · $distance'),
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
      ),
    );
  }
}

class _NearbyMessage extends StatelessWidget {
  const _NearbyMessage({
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
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
