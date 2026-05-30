import 'package:flutter/material.dart';

import '../../data/models/bus_route.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({required this.route, required this.onTap, super.key});

  final BusRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text(route.routeNumber)),
        title: Text(route.name),
        subtitle: Text(
          '${route.startStop} → ${route.endStop}\n${route.farePrice.toStringAsFixed(0)} MMK',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
