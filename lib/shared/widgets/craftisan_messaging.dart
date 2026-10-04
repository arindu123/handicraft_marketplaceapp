import 'dart:async';

import '../data/community_repository.dart';
import '../data/marketplace_repository.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/craftisan_demo_messages.dart';

void _openConversation(BuildContext context, DemoMessageAuthor viewer) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CraftisanConversationScreen(viewer: viewer),
    ),
  );
}

class CraftisanMessagesInbox extends StatelessWidget {
  const CraftisanMessagesInbox({super.key, required this.viewer});
  final DemoMessageAuthor viewer;

  String get _participant =>
      viewer == DemoMessageAuthor.buyer ? 'Elena Rostova' : 'Clara Lindqvist';
  String get _subtitle => viewer == DemoMessageAuthor.buyer
      ? 'Oaxaca Traditional Atelier'
      : 'Craftisan collector';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'Messages',
        style: Theme.of(context).textTheme.headlineLarge
            ?.copyWith(fontSize: 25),
      ),
      backgroundColor: AppColors.background,
    ),
    body: MarketplaceBackend.enabled
        ? StreamBuilder(
            stream: CommunityRepository().inbox(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(marketplaceError(snapshot.error!)));
              }
              final rows = snapshot.data?.docs ?? [];
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (rows.isEmpty) const Text('No conversations yet.'),
                  for (final row in rows)
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.surface,
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(
                          row.data()[viewer == DemoMessageAuthor.buyer
                                  ? 'artisanId'
                                  : 'buyerId']
                              as String,
                        ),
                        subtitle: Text(
                          row.data()['lastMessage'] as String? ?? '',
                        ),
                        isThreeLine: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => CraftisanConversationScreen(
                              viewer: viewer,
                              conversationId: row.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        : AnimatedBuilder(
            animation: craftisanDemoMessages,
            builder: (context, _) {
              final latest = craftisanDemoMessages.messages.last;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: Text(_participant.substring(0, 1)),
                      ),
                      title: Text(_participant),
                      subtitle: Text('$_subtitle\n${latest.text}'),
                      isThreeLine: true,
                      trailing: Text(
                        latest.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      onTap: () => _openConversation(context, viewer),
                    ),
                  ),
                ],
              );
            },
          ),
  );
}

class CraftisanConversationScreen extends StatefulWidget {
  const CraftisanConversationScreen({
    super.key,
    required this.viewer,
    this.conversationId,
    this.artisanId,
  });
  final String? conversationId, artisanId;
  final DemoMessageAuthor viewer;

  @override
  State<CraftisanConversationScreen> createState() =>
      _CraftisanConversationScreenState();
}

class _CraftisanConversationScreenState
    extends State<CraftisanConversationScreen> {
  final controller = TextEditingController();
  StreamSubscription? subscription;
  String? conversationId;
  String? error;
  bool sending = false;
  List<({String text, String time, bool mine})> messages = [];
  @override
  void initState() {
    super.initState();
    if (MarketplaceBackend.enabled) _load();
  }

  Future<void> _load() async {
    try {
      final repo = CommunityRepository();
      conversationId =
          widget.conversationId ??
          (widget.artisanId == null
              ? null
              : await repo.conversation(widget.artisanId!));
      if (!mounted) return;
      if (conversationId == null) {
        setState(() => error = 'Select an artisan or a conversation first.');
        return;
      }
      subscription = repo
          .messages(conversationId!)
          .listen(
            (snapshot) {
              if (!mounted) return;
              setState(
                () => messages = snapshot.docs
                    .map(
                      (d) => (
                        text: d.data()['text'] as String,
                        time: '',
                        mine: d.data()['senderId'] == repo.uid,
                      ),
                    )
                    .toList(),
              );
            },
            onError: (Object e) {
              if (mounted) setState(() => error = marketplaceError(e));
            },
          );
    } catch (e) {
      if (mounted) setState(() => error = marketplaceError(e));
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (MarketplaceBackend.enabled) {
      if (sending || conversationId == null) return;
      sending = true;
      try {
        await CommunityRepository().send(conversationId!, controller.text);
        if (mounted) controller.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(marketplaceError(e))));
        }
      } finally {
        sending = false;
      }
      return;
    }
    craftisanDemoMessages.send(widget.viewer, controller.text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final participant = MarketplaceBackend.enabled
        ? (widget.artisanId ?? 'Conversation')
        : widget.viewer == DemoMessageAuthor.buyer
        ? 'Elena Rostova'
        : 'Clara Lindqvist';
    final subtitle = MarketplaceBackend.enabled
        ? 'Craftisan'
        : widget.viewer == DemoMessageAuthor.buyer
        ? 'Oaxaca Traditional Atelier'
        : 'Craftisan collector';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(participant),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (error != null) Text(error!),
          Expanded(
            child: AnimatedBuilder(
              animation: craftisanDemoMessages,
              builder: (context, _) => ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: MarketplaceBackend.enabled
                    ? messages.length
                    : craftisanDemoMessages.messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = MarketplaceBackend.enabled
                      ? messages[index]
                      : (
                          text: craftisanDemoMessages.messages[index].text,
                          time: craftisanDemoMessages.messages[index].time,
                          mine:
                              craftisanDemoMessages.messages[index].author ==
                              widget.viewer,
                        );
                  final mine = message.mine;
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 290),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: mine ? AppColors.terracotta : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: mine ? Colors.white : AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mine
                                      ? Colors.white70
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
