import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/assistant_service.dart';
import '../../viewmodels/assistant_view_model.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AssistantViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('YBS Assistant'),
        actions: [
          if (viewModel.isOnlineEnhancing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: viewModel.messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: viewModel.messages[index]);
              },
            ),
          ),
          _QuickPromptRow(onPrompt: _sendText),
          _AssistantInputBar(
            controller: _controller,
            isLoading: viewModel.isLoading,
            onSend: () {
              final value = _controller.text;
              _controller.clear();
              _sendText(value);
            },
          ),
        ],
      ),
    );
  }

  void _sendText(String text) {
    context.read<AssistantViewModel>().sendMessage(text);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.author == AssistantMessageAuthor.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const _AssistantAvatar(),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isUser ? colorScheme.surface : const Color(0xFFDDF4E5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      if (message.answer?.legs.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.md),
                        _RouteMiniCard(answer: message.answer!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFF118C7B),
      child: Image.asset(
        AppConstants.ybsLogoAsset,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _RouteMiniCard extends StatelessWidget {
  const _RouteMiniCard({required this.answer});

  final AssistantAnswer answer;

  @override
  Widget build(BuildContext context) {
    final routeText = answer.legs
        .map((leg) => leg.route.routeNumber)
        .toSet()
        .join(' -> ');
    final totalStops = answer.legs.fold<int>(
      0,
      (total, leg) => total + leg.estimatedStops,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF118C7B)),
                Expanded(child: Text(answer.origin?.name ?? 'Start')),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Container(
                width: 3,
                height: 34,
                color: const Color(0xFF118C7B),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.flag, color: Color(0xFFE0A800)),
                Expanded(
                  child: Text(answer.destination?.name ?? 'Destination'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$routeText · about $totalStops stops',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (answer.limitedData)
              const Text(
                'Limited data: route stops may be incomplete.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickPromptRow extends StatelessWidget {
  const _QuickPromptRow({required this.onPrompt});

  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final prompts = const [
      'Nearby Stops',
      'YBS 65 Route',
      'How much is the fare?',
      'To Sule',
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(prompts[index]),
            onPressed: () => onPrompt(prompts[index]),
          );
        },
      ),
    );
  }
}

class _AssistantInputBar extends StatelessWidget {
  const _AssistantInputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Ask me about routes, stops, or times...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.mic_none),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton.filled(
                tooltip: 'Send',
                onPressed: isLoading ? null : onSend,
                icon: const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
