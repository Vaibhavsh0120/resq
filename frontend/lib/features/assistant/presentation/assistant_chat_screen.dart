import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/assistant_api.dart';
import 'assistant_voice_screen.dart';

class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key, this.conversationId});

  final String? conversationId;

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final _api = AssistantApi();
  final _controller = TextEditingController();
  final _messages = <({bool user, String text})>[
    (
      user: false,
      text: 'I can help with verified alerts, safety guidance, readiness, family check-ins, and nearby safe places.',
    ),
  ];
  String? _conversationId;
  bool _sending = false;

  bool get _hasText => _controller.text.trim().isNotEmpty;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AssistantVoiceScreen()),
      );
      return;
    }

    setState(() {
      _messages.add((user: true, text: text));
      _messages.add((user: false, text: ''));
      _controller.clear();
      _sending = true;
    });

    try {
      final conversationId =
          _conversationId ??
          widget.conversationId ??
          await _api.createConversation();
      _conversationId = conversationId;
      await for (final delta in _api.streamMessage(
        conversationId: conversationId,
        text: text,
      )) {
        if (!mounted) return;
        setState(() {
          final current = _messages.last;
          _messages[_messages.length - 1] = (
            user: false,
            text: current.text + delta,
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages[_messages.length - 1] = (
          user: false,
          text: 'I could not connect right now. Emergency calling and saved guidance are still available.',
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final history = _ConversationHistory(
      onSelected: () => Navigator.maybePop(context),
    );
    return Scaffold(
      drawer: wide ? null : Drawer(child: SafeArea(child: history)),
      appBar: AppBar(
        title: const Text('ResQ assistant'),
        actions: [
          IconButton(
            tooltip: 'Voice conversation',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AssistantVoiceScreen(),
              ),
            ),
            icon: const Icon(Icons.mic_rounded),
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide) ...[
            SizedBox(width: 300, child: history),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.user
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 680),
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: message.user
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.base),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.user
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !_sending,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) {
                              if (!_sending) _send();
                            },
                            decoration: const InputDecoration(
                              hintText: 'Message ResQ',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filled(
                          tooltip: _hasText
                              ? 'Send message'
                              : 'Start voice assistant',
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _hasText
                                      ? Icons.send_rounded
                                      : Icons.mic_rounded,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationHistory extends StatelessWidget {
  const _ConversationHistory({required this.onSelected});
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Conversations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          onPressed: onSelected,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New conversation'),
        ),
        const SizedBox(height: AppSpacing.md),
        const ListTile(
          leading: Icon(Icons.chat_bubble_outline_rounded),
          title: Text('Flood readiness'),
          subtitle: Text('Today'),
        ),
        const ListTile(
          leading: Icon(Icons.mic_none_rounded),
          title: Text('Family check-in'),
          subtitle: Text('Yesterday'),
        ),
      ],
    );
  }
}
