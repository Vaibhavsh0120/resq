import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/assistant_api.dart';

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
  final _citationsByMessage = <int, List<AssistantCitation>>{};
  String? _conversationId;
  bool _sending = false;
  bool _loadingConversation = false;
  bool _loadingHistory = true;
  AssistantCapabilities? _capabilities;
  List<AssistantConversation> _conversations = const [];

  bool get _hasText => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _loadHistory();
    _loadCapabilities();
    if (widget.conversationId != null) {
      _loadConversation(widget.conversationId!);
    }
  }

  Future<void> _loadCapabilities() async {
    try {
      final capabilities = await _api.capabilities();
      if (mounted) setState(() => _capabilities = capabilities);
    } catch (_) {
      if (mounted) setState(() => _capabilities = null);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final conversations = await _api.listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loadingHistory = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadConversation(String id) async {
    setState(() => _loadingConversation = true);
    try {
      final conversation = await _api.getConversation(id);
      if (!mounted) return;
      setState(() {
        _conversationId = conversation.id;
        _citationsByMessage.clear();
        _messages
          ..clear()
          ..addAll(
            conversation.messages.map(
              (message) => (user: message.isUser, text: message.text),
            ),
          );
        for (var index = 0; index < conversation.messages.length; index++) {
          final citations = conversation.messages[index].citations;
          if (citations.isNotEmpty) {
            _citationsByMessage[index] = citations;
          }
        }
        if (_messages.isEmpty) {
          _messages.add((
            user: false,
            text: 'How can I help you prepare or respond safely?',
          ));
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This conversation could not be loaded.')),
      );
    } finally {
      if (mounted) setState(() => _loadingConversation = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      final id = _conversationId ?? widget.conversationId;
      context.replace(
        Uri(
          path: '/assistant/voice',
          queryParameters: id == null ? null : {'conversationId': id},
        ).toString(),
      );
      return;
    }

    final history = _messages
        .where((message) => message.text.trim().isNotEmpty)
        .map(
          (message) => AssistantPromptMessage(
            role: message.user ? 'user' : 'assistant',
            text: message.text,
          ),
        )
        .toList(growable: false);

    late int responseIndex;
    setState(() {
      _messages.add((user: true, text: text));
      _messages.add((user: false, text: ''));
      responseIndex = _messages.length - 1;
      _controller.clear();
      _sending = true;
    });

    try {
      final conversationId =
          _conversationId ??
          widget.conversationId ??
          await _api.createConversation(
            language: Localizations.localeOf(context).languageCode,
          );
      _conversationId = conversationId;
      await for (final delta in _api.streamMessage(
        conversationId: conversationId,
        text: text,
        history: history,
        onCitation: (citation) {
          if (!mounted || citation.url.isEmpty) return;
          setState(() {
            (_citationsByMessage[responseIndex] ??= []).add(citation);
          });
        },
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
      await _loadHistory();
    } catch (error) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      final status = error is AssistantApiException ? error.statusCode : null;
      final message = status == 429
          ? strings.assistantDailyLimit
          : status == 503
          ? strings.assistantUnavailable
          : strings.assistantConnectionFailure;
      setState(() {
        final partial = _messages[responseIndex].text.trim();
        _messages[responseIndex] = (
          user: false,
          text: partial.isEmpty ? message : '$partial\n\n$message',
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _loadCapabilities();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final history = _ConversationHistory(
      conversations: _conversations,
      selectedId: _conversationId,
      loading: _loadingHistory,
      onSelect: (id) {
        _loadConversation(id);
        if (!wide) Navigator.maybePop(context);
      },
      onNewConversation: () {
        setState(() {
          _conversationId = null;
          _citationsByMessage.clear();
          _messages
            ..clear()
            ..add((
              user: false,
              text: 'How can I help you prepare or respond safely?',
            ));
        });
        if (!wide) Navigator.maybePop(context);
      },
    );
    return Scaffold(
      drawer: wide ? null : Drawer(child: SafeArea(child: history)),
      appBar: AppBar(
        title: Text(strings.resqAssistant),
        actions: [
          IconButton(
            tooltip: strings.startVoiceAssistant,
            onPressed: () {
              final id = _conversationId ?? widget.conversationId;
              context.replace(
                Uri(
                  path: '/assistant/voice',
                  queryParameters: id == null ? null : {'conversationId': id},
                ).toString(),
              );
            },
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
                if (_capabilities case final capabilities?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      0,
                    ),
                    child: Text(
                      !capabilities.available
                          ? strings.assistantUnavailable
                          : capabilities.dailyRemaining == 0
                          ? strings.assistantDailyLimit
                          : '${capabilities.dailyRemaining} ${strings.assistantTurnsLeft}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Expanded(
                  child: _loadingConversation
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return Align(
                              alignment: message.user
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 680,
                                ),
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: message.user
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.base,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!message.user) ...[
                                      Text(
                                        strings.aiResponseLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                    ],
                                    Text(
                                      message.text,
                                      style: TextStyle(
                                        color: message.user
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                            : null,
                                      ),
                                    ),
                                    if ((_citationsByMessage[index] ?? const [])
                                        .isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        strings.sourcesProvided,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      Wrap(
                                        spacing: AppSpacing.xs,
                                        runSpacing: AppSpacing.xs,
                                        children: _citationsByMessage[index]!
                                            .map(
                                              (citation) => ActionChip(
                                                avatar: const Icon(
                                                  Icons.open_in_new_rounded,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  citation.title,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                onPressed: () => launchUrl(
                                                  Uri.parse(citation.url),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                                    ],
                                  ],
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
                            decoration: InputDecoration(
                              hintText: strings.messageResq,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filled(
                          tooltip: _hasText
                              ? strings.sendMessage
                              : strings.startVoiceAssistant,
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
  const _ConversationHistory({
    required this.onNewConversation,
    required this.conversations,
    required this.selectedId,
    required this.loading,
    required this.onSelect,
  });
  final VoidCallback onNewConversation;
  final List<AssistantConversation> conversations;
  final String? selectedId;
  final bool loading;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Conversations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          onPressed: onNewConversation,
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.newConversation),
        ),
        const SizedBox(height: AppSpacing.md),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (conversations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              strings.noSavedConversations,
              textAlign: TextAlign.center,
            ),
          )
        else
          ...conversations.map(
            (conversation) => ListTile(
              selected: conversation.id == selectedId,
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: Text(
                conversation.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSelect(conversation.id),
            ),
          ),
      ],
    );
  }
}
