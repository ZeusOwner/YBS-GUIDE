import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/bus_stop.dart';
import '../../data/repositories/ybs_repository.dart';
import '../../data/services/assistant_service.dart';

enum AssistantMessageAuthor { assistant, user }

class AssistantMessage {
  const AssistantMessage({
    required this.author,
    required this.text,
    this.answer,
  });

  final AssistantMessageAuthor author;
  final String text;
  final AssistantAnswer? answer;

  AssistantMessage copyWith({String? text, AssistantAnswer? answer}) {
    return AssistantMessage(
      author: author,
      text: text ?? this.text,
      answer: answer ?? this.answer,
    );
  }
}

class AssistantViewModel extends ChangeNotifier {
  AssistantViewModel({
    required this.repository,
    required this.assistantService,
    AiAssistantClient? aiClient,
  }) : _aiClient = aiClient ?? AiAssistantClient() {
    messages = const [
      AssistantMessage(
        author: AssistantMessageAuthor.assistant,
        text:
            'Hello! I am your YBS Assistant. Where would you like to go today?',
      ),
    ];
  }

  final YbsRepository repository;
  final AssistantService assistantService;
  final AiAssistantClient _aiClient;

  List<AssistantMessage> messages = [];
  BusStop? currentStop;
  bool isLoading = false;
  bool isOnlineEnhancing = false;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isLoading) {
      return;
    }

    messages = [
      ...messages,
      AssistantMessage(author: AssistantMessageAuthor.user, text: trimmed),
    ];
    isLoading = true;
    notifyListeners();

    currentStop ??= await useCurrentLocationContext();
    final offlineAnswer = await assistantService.generateOfflineTripAnswer(
      trimmed,
      currentStop: currentStop,
    );
    messages = [
      ...messages,
      AssistantMessage(
        author: AssistantMessageAuthor.assistant,
        text: offlineAnswer.text,
        answer: offlineAnswer,
      ),
    ];
    isLoading = false;
    notifyListeners();

    await _enhanceLastAssistantMessage(trimmed, offlineAnswer);
  }

  Future<BusStop?> useCurrentLocationContext() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      final position = await _getPosition();
      if (position == null) {
        return null;
      }
      final stops = await repository.getStops();
      if (stops.isEmpty) {
        return null;
      }
      final distance = const Distance();
      final userPoint = LatLng(position.latitude, position.longitude);
      stops.sort(
        (left, right) =>
            distance(
              userPoint,
              LatLng(left.latitude, left.longitude),
            ).compareTo(
              distance(userPoint, LatLng(right.latitude, right.longitude)),
            ),
      );
      currentStop = stops.first;
      return currentStop;
    } catch (_) {
      return null;
    }
  }

  Future<void> _enhanceLastAssistantMessage(
    String question,
    AssistantAnswer offlineAnswer,
  ) async {
    if (!_aiClient.isConfigured) {
      return;
    }
    isOnlineEnhancing = true;
    notifyListeners();
    try {
      final enhanced = await _aiClient.enhanceAnswer(
        question: question,
        offlineAnswer: offlineAnswer,
        languageCode: 'en',
      );
      if (enhanced == null || enhanced.trim().isEmpty) {
        return;
      }
      final updatedMessages = [...messages];
      final index = updatedMessages.lastIndexWhere(
        (message) => message.author == AssistantMessageAuthor.assistant,
      );
      if (index >= 0) {
        updatedMessages[index] = updatedMessages[index].copyWith(
          text: enhanced.trim(),
        );
        messages = updatedMessages;
      }
    } catch (_) {
      // Offline answer remains the fallback.
    } finally {
      isOnlineEnhancing = false;
      notifyListeners();
    }
  }

  Future<Position?> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } on TimeoutException {
      return Geolocator.getLastKnownPosition();
    }
  }
}
