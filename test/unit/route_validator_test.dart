import 'package:flutter_test/flutter_test.dart';
import 'package:ybs_guide/data/utils/route_validator.dart';

void main() {
  test('valid route returns no errors', () {
    final errors = RouteValidator.validate(_validRoute());

    expect(errors, isEmpty);
  });

  test('missing required field returns error', () {
    final route = _validRoute()..remove('nameMm');

    final errors = RouteValidator.validate(route);

    expect(errors, contains('nameMm is required.'));
  });

  test('invalid route number format returns error', () {
    final route = _validRoute()..['routeNumber'] = '36';

    final errors = RouteValidator.validate(route);

    expect(errors, contains('routeNumber must match YBS-[0-9]+.'));
  });

  test('stop outside Yangon bounds returns error', () {
    final route = _validRoute();
    (route['stops'] as List<dynamic>)[0]['latitude'] = 15.0;

    final errors = RouteValidator.validate(route);

    expect(
      errors,
      contains('stops[0] latitude/longitude is outside Yangon bounds.'),
    );
  });

  test('mojibake detected returns error', () {
    final route = _validRoute()..['nameMm'] = 'Ã¡â‚¬ corrupted';

    final errors = RouteValidator.validate(route);

    expect(errors, contains('route.nameMm contains mojibake characters.'));
  });
}

Map<String, dynamic> _validRoute() {
  return {
    'id': 'ybs-36',
    'routeNumber': 'YBS-36',
    'nameEn': 'Hlaing to Insein via Downtown',
    'nameMm': 'လည်းတန်း မှ အင်းစိန် မြို့လယ်ဖြတ်',
    'startStopEn': 'Hlaing',
    'startStopMm': 'လည်းတန်း',
    'endStopEn': 'Insein',
    'endStopMm': 'အင်းစိန်',
    'farePrice': 300,
    'isAirCon': false,
    'color': '#1B5E20',
    'routeType': 'regular',
    'operatingHours': {'firstBus': '05:30', 'lastBus': '21:00'},
    'frequency': 'every 15-20 min',
    'stops': [
      {
        'id': 'stop-hlaing-001',
        'nameEn': 'Hlaing Terminal',
        'nameMm': 'လည်းတန်းဂိတ်',
        'latitude': 16.8312,
        'longitude': 96.1123,
        'landmark': 'Hlaing Market',
        'isTerminal': true,
        'sequence': 1,
      },
      {
        'id': 'stop-insein-001',
        'nameEn': 'Insein Terminal',
        'nameMm': 'အင်းစိန်ဂိတ်',
        'latitude': 16.8904,
        'longitude': 96.0999,
        'landmark': 'Insein Market',
        'isTerminal': true,
        'sequence': 2,
      },
    ],
    'schedule': {
      'forward': {
        'departureTimes': ['05:30', '05:50', '06:10'],
      },
      'return': {
        'departureTimes': ['05:45', '06:05', '06:25'],
      },
    },
    'routePath': [
      [16.8312, 96.1123],
      [16.8355, 96.1145],
    ],
  };
}
