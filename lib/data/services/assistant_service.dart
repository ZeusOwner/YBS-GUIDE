import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../repositories/ybs_repository.dart';

class AssistantRouteLeg {
  const AssistantRouteLeg({
    required this.route,
    required this.fromStop,
    required this.toStop,
    required this.estimatedStops,
  });

  final BusRoute route;
  final BusStop fromStop;
  final BusStop toStop;
  final int estimatedStops;
}

class AssistantAnswer {
  const AssistantAnswer({
    required this.text,
    required this.origin,
    required this.destination,
    required this.legs,
    required this.limitedData,
  });

  final String text;
  final BusStop? origin;
  final BusStop? destination;
  final List<AssistantRouteLeg> legs;
  final bool limitedData;
}

class AssistantService {
  const AssistantService(this._repository);

  final YbsRepository _repository;

  Future<AssistantAnswer> generateOfflineTripAnswer(
    String question, {
    BusStop? currentStop,
  }) async {
    final routes = await _repository.getRoutes();
    final stops = await _repository.getStops();
    final infoAnswer = _routeInfoAnswer(question, routes);
    if (infoAnswer != null) {
      return infoAnswer;
    }
    final nearbyAnswer = _nearbyAnswer(question, currentStop, routes);
    if (nearbyAnswer != null) {
      return nearbyAnswer;
    }
    final origin = _findOrigin(question, stops) ?? currentStop;
    final destination = _findDestination(
      question,
      stops,
      routes: routes,
      origin: origin,
    );

    if (destination == null) {
      return const AssistantAnswer(
        text:
            'I could not find that destination in the YBS data. Try a stop, township, or route number.',
        origin: null,
        destination: null,
        legs: [],
        limitedData: false,
      );
    }
    if (origin == null) {
      return AssistantAnswer(
        text:
            'Please choose your starting stop first. I found destination: ${destination.name}.',
        origin: null,
        destination: destination,
        legs: const [],
        limitedData: false,
      );
    }

    final directLeg = _findDirectLeg(routes, origin, destination);
    if (directLeg != null) {
      final limitedData =
          directLeg.route.dataConfidence == DataConfidence.terminalOnly;
      return AssistantAnswer(
        text: _directText(directLeg, limitedData),
        origin: origin,
        destination: destination,
        legs: [directLeg],
        limitedData: limitedData,
      );
    }

    final transferLegs = _findTransferLegs(routes, origin, destination);
    if (transferLegs.isNotEmpty) {
      return AssistantAnswer(
        text: _transferText(transferLegs),
        origin: origin,
        destination: destination,
        legs: transferLegs,
        limitedData: false,
      );
    }

    return AssistantAnswer(
      text:
          'I could not find a reliable route from ${origin.name} to ${destination.name}. Some YBS routes still have terminal-only data.',
      origin: origin,
      destination: destination,
      legs: const [],
      limitedData: true,
    );
  }

  BusStop? _findOrigin(String question, List<BusStop> stops) {
    final match = RegExp(
      r'from\s+(.+?)(?:\s+to\s+|$)',
      caseSensitive: false,
    ).firstMatch(question);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return _findStop(value, stops);
  }

  AssistantAnswer? _routeInfoAnswer(String question, List<BusRoute> routes) {
    final match = RegExp(
      r'\b(?:ybs\s*)?(\d{1,3})\b',
      caseSensitive: false,
    ).firstMatch(question);
    if (match == null) {
      return null;
    }
    final routeNumber = 'YBS-${match.group(1)}';
    final route = routes
        .where((candidate) => candidate.routeNumber == routeNumber)
        .firstOrNull;
    if (route == null) {
      return null;
    }
    return AssistantAnswer(
      text:
          '${route.routeNumber}: ${route.startStop} to ${route.endStop}. Fare: ${route.farePrice.toStringAsFixed(0)} MMK. ${route.isAirCon ? 'Air-con route.' : 'Regular route.'}',
      origin: null,
      destination: null,
      legs: const [],
      limitedData: route.dataConfidence == DataConfidence.terminalOnly,
    );
  }

  AssistantAnswer? _nearbyAnswer(
    String question,
    BusStop? currentStop,
    List<BusRoute> routes,
  ) {
    if (!_normalize(question).contains('nearby') || currentStop == null) {
      return null;
    }
    final routeNumbers = routes
        .where(
          (route) =>
              currentStop.routes.contains(route.id) ||
              route.stops.any((stop) => stop.id == currentStop.id),
        )
        .map((route) => route.routeNumber)
        .toSet()
        .join(', ');
    return AssistantAnswer(
      text:
          'Your nearest known stop is ${currentStop.name}. Routes passing nearby: ${routeNumbers.isEmpty ? 'route data unavailable' : routeNumbers}.',
      origin: currentStop,
      destination: null,
      legs: const [],
      limitedData: false,
    );
  }

  BusStop? _findDestination(
    String question,
    List<BusStop> stops, {
    required List<BusRoute> routes,
    required BusStop? origin,
  }) {
    final toMatch = RegExp(
      r'\bto\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(question);
    final destinationText = toMatch?.group(1) ?? question;
    final candidates = _findStops(_stripIntentWords(destinationText), stops);
    if (origin != null) {
      for (final candidate in candidates) {
        if (_findDirectLeg(routes, origin, candidate) != null) {
          return candidate;
        }
      }
    }
    return candidates.firstOrNull;
  }

  BusStop? _findStop(String text, List<BusStop> stops) {
    return _findStops(text, stops).firstOrNull;
  }

  List<BusStop> _findStops(String text, List<BusStop> stops) {
    final query = _normalize(text);
    if (query.isEmpty) {
      return const [];
    }
    final matches = <BusStop>[];
    for (final stop in stops) {
      final haystack = _normalize('${stop.name} ${stop.landmark}');
      if (haystack.contains(query) || query.contains(_normalize(stop.nameEn))) {
        matches.add(stop);
      }
    }
    return matches;
  }

  AssistantRouteLeg? _findDirectLeg(
    List<BusRoute> routes,
    BusStop origin,
    BusStop destination,
  ) {
    for (final route in routes) {
      if (_routeContainsStop(route, origin.id) &&
          _routeContainsStop(route, destination.id)) {
        return AssistantRouteLeg(
          route: route,
          fromStop: origin,
          toStop: destination,
          estimatedStops: _stopDistance(route, origin.id, destination.id),
        );
      }
    }
    return null;
  }

  List<AssistantRouteLeg> _findTransferLegs(
    List<BusRoute> routes,
    BusStop origin,
    BusStop destination,
  ) {
    final usableRoutes = routes
        .where((route) => route.dataConfidence != DataConfidence.terminalOnly)
        .toList();
    final originRoutes = usableRoutes.where(
      (route) => _routeContainsStop(route, origin.id),
    );
    final destinationRoutes = usableRoutes.where(
      (route) => _routeContainsStop(route, destination.id),
    );

    for (final firstRoute in originRoutes) {
      for (final secondRoute in destinationRoutes) {
        if (firstRoute.id == secondRoute.id) {
          continue;
        }
        final transferStop = _sharedStop(firstRoute, secondRoute);
        if (transferStop == null) {
          continue;
        }
        return [
          AssistantRouteLeg(
            route: firstRoute,
            fromStop: origin,
            toStop: transferStop,
            estimatedStops: _stopDistance(
              firstRoute,
              origin.id,
              transferStop.id,
            ),
          ),
          AssistantRouteLeg(
            route: secondRoute,
            fromStop: transferStop,
            toStop: destination,
            estimatedStops: _stopDistance(
              secondRoute,
              transferStop.id,
              destination.id,
            ),
          ),
        ];
      }
    }
    return const [];
  }

  bool _routeContainsStop(BusRoute route, String stopId) {
    return route.stops.any((stop) => stop.id == stopId);
  }

  int _stopDistance(BusRoute route, String fromId, String toId) {
    final fromIndex = route.stops.indexWhere((stop) => stop.id == fromId);
    final toIndex = route.stops.indexWhere((stop) => stop.id == toId);
    if (fromIndex == -1 || toIndex == -1) {
      return 0;
    }
    return (toIndex - fromIndex).abs();
  }

  BusStop? _sharedStop(BusRoute firstRoute, BusRoute secondRoute) {
    for (final stop in firstRoute.stops) {
      if (secondRoute.stops.any((candidate) => candidate.id == stop.id)) {
        return stop;
      }
    }
    return null;
  }

  String _directText(AssistantRouteLeg leg, bool limitedData) {
    final warning = limitedData
        ? '\nNote: this route has terminal-only data, so intermediate stops may be incomplete.'
        : '';
    return 'Board ${leg.route.routeNumber} at ${leg.fromStop.name}. '
        'Ride for about ${leg.estimatedStops} stops and get off at ${leg.toStop.name}. '
        'Fare: ${leg.route.farePrice.toStringAsFixed(0)} MMK.$warning';
  }

  String _transferText(List<AssistantRouteLeg> legs) {
    final first = legs.first;
    final second = legs.last;
    final fare = first.route.farePrice + second.route.farePrice;
    return 'Take ${first.route.routeNumber} from ${first.fromStop.name} to ${first.toStop.name}. '
        'Then transfer to ${second.route.routeNumber} and get off at ${second.toStop.name}. '
        'Estimated total stops: ${first.estimatedStops + second.estimatedStops}. '
        'Fare: ${fare.toStringAsFixed(0)} MMK.';
  }

  String _stripIntentWords(String value) {
    return value
        .replaceAll(
          RegExp(r'\b(go|want|need|get|there|pagoda)\b', caseSensitive: false),
          ' ',
        )
        .replaceAll('သွားချင်တယ်', ' ')
        .replaceAll('သွားမယ်', ' ')
        .trim();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u1000-\u109f-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class AiAssistantClient {
  AiAssistantClient({
    http.Client? httpClient,
    this.endpoint = const String.fromEnvironment(
      'YBS_ASSISTANT_WORKER_URL',
      defaultValue: 'https://ybs-guide-assistant.myanmarkk479.workers.dev',
    ),
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String endpoint;

  bool get isConfigured => endpoint.trim().isNotEmpty;

  Future<String?> enhanceAnswer({
    required String question,
    required AssistantAnswer offlineAnswer,
    required String languageCode,
  }) async {
    if (!isConfigured || offlineAnswer.text.isEmpty) {
      return null;
    }
    final response = await _httpClient
        .post(
          Uri.parse(endpoint),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'question': question,
            'languageCode': languageCode,
            'nearestStop': offlineAnswer.origin?.name,
            'destination': offlineAnswer.destination?.name,
            'candidateRoutes': offlineAnswer.legs
                .map(
                  (leg) => {
                    'routeNumber': leg.route.routeNumber,
                    'fromStop': leg.fromStop.name,
                    'toStop': leg.toStop.name,
                    'estimatedStops': leg.estimatedStops,
                    'farePrice': leg.route.farePrice,
                    'dataConfidence': leg.route.dataConfidence.name,
                  },
                )
                .toList(),
            'offlineAnswer': offlineAnswer.text,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['answer'] as String?;
  }
}
