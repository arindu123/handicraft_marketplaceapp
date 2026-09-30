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
    body: AnimatedBuilder(
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
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
  const CraftisanConversationScreen({super.key, required this.viewer});
  final DemoMessageAuthor viewer;

  @override
  State<CraftisanConversationScreen> createState() =>
      _CraftisanConversationScreenState();
}

class _CraftisanConversationScreenState
    extends State<CraftisanConversationScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _send() {
    craftisanDemoMessages.send(widget.viewer, controller.text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final participant = widget.viewer == DemoMessageAuthor.buyer
        ? 'Elena Rostova'
        : 'Clara Lindqvist';
    final subtitle = widget.viewer == DemoMessageAuthor.buyer
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
          Expanded(
            child: AnimatedBuilder(
              animation: craftisanDemoMessages,
              builder: (context, _) => ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: craftisanDemoMessages.messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = craftisanDemoMessages.messages[index];
                  final mine = message.author == widget.viewer;
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
