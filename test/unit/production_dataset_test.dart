import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ybs_guide/data/utils/route_validator.dart';

void main() {
  test('production route dataset validates every route', () {
    final file = File('assets/data/ybs_routes_production.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>;
    final invalidRoutes = <String, List<String>>{};

    for (final route in routes) {
      final routeJson = route as Map<String, dynamic>;
      final errors = RouteValidator.validate(routeJson);
      if (errors.isNotEmpty) {
        invalidRoutes[routeJson['routeNumber'] as String] = errors;
      }
    }

    debugPrint(
      'Valid routes: ${routes.length - invalidRoutes.length} / Total: ${routes.length}',
    );
    if (invalidRoutes.isNotEmpty) {
      for (final entry in invalidRoutes.entries) {
        debugPrint('${entry.key}: ${entry.value.join('; ')}');
      }
    }

    expect(invalidRoutes, isEmpty);
  });
}
