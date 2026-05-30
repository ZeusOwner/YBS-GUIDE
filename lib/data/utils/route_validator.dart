class RouteValidator {
  static const double _minYangonLat = 16.6;
  static const double _maxYangonLat = 17.1;
  static const double _minYangonLng = 96.0;
  static const double _maxYangonLng = 96.4;

  static final RegExp _routeNumberPattern = RegExp(r'^YBS-[0-9]+$');
  static final RegExp _mojibakePattern = RegExp('[Ãâ]');

  static List<String> validate(Map<String, dynamic> route) {
    final errors = <String>[];

    _requireString(route, 'id', errors);
    _requireString(route, 'routeNumber', errors);
    _requireString(route, 'nameEn', errors);
    _requireString(route, 'nameMm', errors);
    _requireString(route, 'startStopEn', errors);
    _requireString(route, 'startStopMm', errors);
    _requireString(route, 'endStopEn', errors);
    _requireString(route, 'endStopMm', errors);
    _requireString(route, 'color', errors);
    _requireString(route, 'routeType', errors);
    _requireString(route, 'frequency', errors);

    final routeNumber = route['routeNumber'];
    if (routeNumber is String &&
        routeNumber.isNotEmpty &&
        !_routeNumberPattern.hasMatch(routeNumber)) {
      errors.add('routeNumber must match YBS-[0-9]+.');
    }

    final farePrice = route['farePrice'];
    if (farePrice is! num || farePrice <= 0) {
      errors.add('farePrice must be a positive number.');
    }

    if (route['isAirCon'] is! bool) {
      errors.add('isAirCon must be a boolean.');
    }

    _validateOperatingHours(route['operatingHours'], errors);
    _validateStops(route['stops'], errors);
    _validateSchedule(route['schedule'], errors);
    _validateRoutePath(route['routePath'], errors);
    _validateMojibake(route, errors);

    return errors;
  }

  static void _requireString(
    Map<String, dynamic> route,
    String field,
    List<String> errors,
  ) {
    final value = route[field];
    if (value is! String || value.trim().isEmpty) {
      errors.add('$field is required.');
    }
  }

  static void _validateOperatingHours(Object? value, List<String> errors) {
    if (value is! Map) {
      errors.add('operatingHours is required.');
      return;
    }

    final firstBus = value['firstBus'];
    final lastBus = value['lastBus'];
    if (firstBus is! String || firstBus.trim().isEmpty) {
      errors.add('operatingHours.firstBus is required.');
    }
    if (lastBus is! String || lastBus.trim().isEmpty) {
      errors.add('operatingHours.lastBus is required.');
    }
  }

  static void _validateStops(Object? value, List<String> errors) {
    if (value is! List) {
      errors.add('stops must be a list.');
      return;
    }
    if (value.length < 2) {
      errors.add('stops must contain at least 2 terminal stops.');
    }

    for (var index = 0; index < value.length; index++) {
      final stop = value[index];
      if (stop is! Map) {
        errors.add('stops[$index] must be an object.');
        continue;
      }

      _requireNestedString(stop, 'id', 'stops[$index].id', errors);
      _requireNestedString(stop, 'nameEn', 'stops[$index].nameEn', errors);
      _requireNestedString(stop, 'nameMm', 'stops[$index].nameMm', errors);

      final latitude = stop['latitude'];
      final longitude = stop['longitude'];
      if (latitude is! num || longitude is! num) {
        errors.add('stops[$index] latitude/longitude must be numbers.');
        continue;
      }
      if (!_isInYangon(latitude.toDouble(), longitude.toDouble())) {
        errors.add(
          'stops[$index] latitude/longitude is outside Yangon bounds.',
        );
      }

      final sequence = stop['sequence'];
      if (sequence is! int || sequence <= 0) {
        errors.add('stops[$index].sequence must be a positive integer.');
      }
    }
  }

  static void _validateSchedule(Object? value, List<String> errors) {
    if (value is! Map) {
      errors.add('schedule is required.');
      return;
    }
    _validateDepartures(value['forward'], 'schedule.forward', errors);
    _validateDepartures(value['return'], 'schedule.return', errors);
  }

  static void _validateDepartures(
    Object? value,
    String path,
    List<String> errors,
  ) {
    if (value is! Map) {
      errors.add('$path is required.');
      return;
    }
    final departureTimes = value['departureTimes'];
    if (departureTimes is! List || departureTimes.isEmpty) {
      errors.add('$path.departureTimes must be a non-empty list.');
    }
  }

  static void _validateRoutePath(Object? value, List<String> errors) {
    if (value is! List || value.length < 2) {
      errors.add('routePath must contain at least 2 coordinate points.');
      return;
    }

    for (var index = 0; index < value.length; index++) {
      final point = value[index];
      if (point is! List || point.length != 2) {
        errors.add('routePath[$index] must be [latitude, longitude].');
        continue;
      }
      final latitude = point[0];
      final longitude = point[1];
      if (latitude is! num || longitude is! num) {
        errors.add('routePath[$index] latitude/longitude must be numbers.');
        continue;
      }
      if (!_isInYangon(latitude.toDouble(), longitude.toDouble())) {
        errors.add('routePath[$index] is outside Yangon bounds.');
      }
    }
  }

  static void _requireNestedString(
    Map<dynamic, dynamic> map,
    String field,
    String path,
    List<String> errors,
  ) {
    final value = map[field];
    if (value is! String || value.trim().isEmpty) {
      errors.add('$path is required.');
    }
  }

  static bool _isInYangon(double latitude, double longitude) {
    return latitude >= _minYangonLat &&
        latitude <= _maxYangonLat &&
        longitude >= _minYangonLng &&
        longitude <= _maxYangonLng;
  }

  static void _validateMojibake(
    Object? value,
    List<String> errors, [
    String path = 'route',
  ]) {
    if (value is Map) {
      for (final entry in value.entries) {
        _validateMojibake(entry.value, errors, '$path.${entry.key}');
      }
      return;
    }
    if (value is List) {
      for (var index = 0; index < value.length; index++) {
        _validateMojibake(value[index], errors, '$path[$index]');
      }
      return;
    }
    if (value is String && _mojibakePattern.hasMatch(value)) {
      errors.add('$path contains mojibake characters.');
    }
  }
}
