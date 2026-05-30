import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/bus_route.dart';
import '../../../data/models/bus_stop.dart';
import '../../viewmodels/map_view_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LayerHitNotifier<String> _routeHitNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _searchController.dispose();
    _routeHitNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MapViewModel>();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: MapViewModel.yangonCenter,
            initialZoom: 12,
            onPositionChanged: (camera, _) {
              context.read<MapViewModel>().updateZoom(camera.zoom);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ybsguide.mm',
              fallbackUrl: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
              errorTileCallback: (_, _, _) {
                context.read<MapViewModel>().markTileError();
              },
            ),
            GestureDetector(
              onTap: () {
                final routeId = _routeHitNotifier.value?.hitValues.firstOrNull;
                if (routeId == null) {
                  return;
                }
                final route = viewModel.routes
                    .where((route) => route.id == routeId)
                    .firstOrNull;
                if (route != null) {
                  context.read<MapViewModel>().selectRoute(route);
                }
              },
              child: PolylineLayer<String>(
                hitNotifier: _routeHitNotifier,
                polylines: _routePolylines(viewModel),
              ),
            ),
            MarkerLayer(markers: _markers(viewModel)),
            const Scalebar(
              alignment: Alignment.bottomLeft,
              padding: EdgeInsets.only(left: 16, bottom: 168),
            ),
          ],
        ),
        _SearchOverlay(
          controller: _searchController,
          onResultSelected: (result) {
            _focusResult(result, viewModel);
            context.read<MapViewModel>().clearSearch();
            _searchController.clear();
          },
        ),
        _MapControls(
          onZoomIn: () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom + 1,
          ),
          onZoomOut: () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom - 1,
          ),
          onCompass: () => _mapController.rotate(0),
          onLocation: () => _centerOnUser(context),
          onFilter: () => _showFilterSheet(context),
        ),
        if (viewModel.isLoading)
          const Center(child: CircularProgressIndicator()),
        if (viewModel.hasTileError) const _NoInternetBanner(),
        _NearbyStopsSheet(stops: viewModel.nearbyStops),
      ],
    );
  }

  List<Polyline<String>> _routePolylines(MapViewModel viewModel) {
    return [
      for (final route in viewModel.visibleRoutes)
        Polyline(
          points: route.routePath
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: _parseHexColor(route.color).withAlpha(
            viewModel.selectedRoute == null ||
                    viewModel.selectedRoute?.id == route.id
                ? 230
                : 80,
          ),
          strokeWidth: viewModel.selectedRoute?.id == route.id ? 7 : 4,
          hitValue: route.id,
        ),
    ];
  }

  List<Marker> _markers(MapViewModel viewModel) {
    if (viewModel.zoom < 11.5 && viewModel.visibleStops.isNotEmpty) {
      return [
        Marker(
          point: MapViewModel.yangonCenter,
          width: 64,
          height: 64,
          child: _ClusterMarker(count: viewModel.visibleStops.length),
        ),
      ];
    }

    return [
      if (viewModel.userLocation != null)
        Marker(
          point: viewModel.userLocation!,
          width: 44,
          height: 44,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 34),
        ),
      for (final stop in viewModel.visibleStops)
        Marker(
          point: LatLng(stop.latitude, stop.longitude),
          width: 44,
          height: 44,
          child: const _BusStopMarker(),
        ),
    ];
  }

  Future<void> _centerOnUser(BuildContext context) async {
    final location = await context.read<MapViewModel>().requestUserLocation();
    if (location == null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location unavailable / တည်နေရာ မရရှိပါ')),
      );
      return;
    }
    _mapController.move(location, 15);
  }

  void _focusResult(Object result, MapViewModel viewModel) {
    if (result is BusStop) {
      _mapController.move(LatLng(result.latitude, result.longitude), 15);
      return;
    }
    if (result is BusRoute) {
      context.read<MapViewModel>().selectRoute(result);
      final firstPoint = result.routePath.firstOrNull;
      if (firstPoint != null) {
        _mapController.move(
          LatLng(firstPoint.latitude, firstPoint.longitude),
          13,
        );
      }
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final selected = context.watch<MapViewModel>().filter;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterOption(
                title: 'All routes / အားလုံး',
                selected: selected == MapRouteFilter.all,
                onTap: () => _setFilter(context, MapRouteFilter.all),
              ),
              _FilterOption(
                title: 'Air-con only / အဲကွန်း',
                selected: selected == MapRouteFilter.airCon,
                onTap: () => _setFilter(context, MapRouteFilter.airCon),
              ),
              _FilterOption(
                title: 'Regular only / ရိုးရိုး',
                selected: selected == MapRouteFilter.regular,
                onTap: () => _setFilter(context, MapRouteFilter.regular),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setFilter(BuildContext context, MapRouteFilter value) {
    context.read<MapViewModel>().setFilter(value);
    Navigator.of(context).pop();
  }

  Color _parseHexColor(String hex) {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(title),
    );
  }
}

class _SearchOverlay extends StatelessWidget {
  const _SearchOverlay({
    required this.controller,
    required this.onResultSelected,
  });

  final TextEditingController controller;
  final ValueChanged<Object> onResultSelected;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MapViewModel>();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Material(
            elevation: AppElevation.high,
            borderRadius: AppRadius.card,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Search stops or routes / ရှာဖွေမည်',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: viewModel.searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              controller.clear();
                              context.read<MapViewModel>().clearSearch();
                            },
                          ),
                  ),
                  onChanged: context.read<MapViewModel>().updateSearchQuery,
                ),
                if (viewModel.searchResults.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final result in viewModel.searchResults)
                          ListTile(
                            dense: true,
                            title: Text(_resultTitle(result)),
                            subtitle: Text(_resultSubtitle(result)),
                            onTap: () => onResultSelected(result),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _resultTitle(Object result) {
    return switch (result) {
      BusRoute route => route.routeNumber,
      BusStop stop => stop.name,
      _ => '',
    };
  }

  String _resultSubtitle(Object result) {
    return switch (result) {
      BusRoute route => route.name,
      BusStop stop => stop.landmark,
      _ => '',
    };
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCompass,
    required this.onLocation,
    required this.onFilter,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCompass;
  final VoidCallback onLocation;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: AppSpacing.md,
      top: 116,
      child: Column(
        children: [
          _MapButton(icon: Icons.add, onPressed: onZoomIn),
          _MapButton(icon: Icons.remove, onPressed: onZoomOut),
          _MapButton(icon: Icons.explore_outlined, onPressed: onCompass),
          _MapButton(icon: Icons.my_location, onPressed: onLocation),
          _MapButton(icon: Icons.filter_alt_outlined, onPressed: onFilter),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FloatingActionButton.small(
        heroTag: icon.codePoint,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}

class _NearbyStopsSheet extends StatelessWidget {
  const _NearbyStopsSheet({required this.stops});

  final List<BusStop> stops;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.18,
      minChildSize: 0.12,
      maxChildSize: 0.45,
      builder: (context, controller) {
        return Material(
          elevation: AppElevation.high,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Nearby Stops within 500m / ၅၀၀ မီတာအတွင်း မှတ်တိုင်များ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (stops.isEmpty)
                const Text('အနီးအနား မှတ်တိုင် မတွေ့ပါ။')
              else
                for (final stop in stops)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.directions_bus),
                    title: Text(stop.name),
                    subtitle: Text('Routes: ${stop.routes.join(', ')}'),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _BusStopMarker extends StatelessWidget {
  const _BusStopMarker();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.location_pin, color: AppColors.error, size: 38);
  }
}

class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppColors.primary,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoInternetBanner extends StatelessWidget {
  const _NoInternetBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 88),
          child: Material(
            color: AppColors.error,
            borderRadius: AppRadius.card,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'Map tiles may be offline. Cached tiles will be used when available.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
