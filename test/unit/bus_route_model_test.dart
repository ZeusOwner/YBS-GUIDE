import 'package:flutter_test/flutter_test.dart';
import 'package:ybs_guide/data/models/bus_route.dart';

void main() {
  test('BusRoute serializes from and to JSON', () {
    final json = {
      'id': 'ybs-1',
      'routeNumber': 'YBS-1',
      'name': 'Insein - Shwedagon / အင်းစိန် - ရွှေတိဂုံ',
      'startStop': 'Insein',
      'endStop': 'Shwedagon',
      'farePrice': 400,
      'isAirCon': false,
      'color': '#1B5E20',
      'stops': [
        {
          'id': 'insein',
          'name': 'Insein / အင်းစိန်',
          'latitude': 16.89,
          'longitude': 96.10,
          'routes': ['ybs-1'],
          'landmark': 'Insein Market',
        },
      ],
      'schedule': [
        {
          'routeId': 'ybs-1',
          'direction': 'forward',
          'departureTimes': ['05:30', '06:00'],
          'operatingDays': ['Mon'],
          'firstBus': '05:30',
          'lastBus': '21:30',
        },
      ],
      'routePath': [
        {'latitude': 16.89, 'longitude': 96.10},
      ],
    };

    final route = BusRoute.fromJson(json);

    expect(route.id, 'ybs-1');
    expect(route.routeNumber, 'YBS-1');
    expect(route.stops.single.name, contains('Insein'));
    expect(route.schedule.single.departureTimes, ['05:30', '06:00']);
    expect(route.toJson()['routePath'], isA<List<dynamic>>());
  });
}
