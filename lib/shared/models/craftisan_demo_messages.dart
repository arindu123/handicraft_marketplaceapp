import 'package:flutter/foundation.dart';

/// Shared, in-memory conversation used by the Buyer and Artisan UI demos.
enum DemoMessageAuthor { buyer, artisan }

class DemoMessage {
  const DemoMessage({
    required this.author,
    required this.text,
    required this.time,
  });

  final DemoMessageAuthor author;
  final String text;
  final String time;
}

class CraftisanDemoMessages extends ChangeNotifier {
  final List<DemoMessage> messages = [
    const DemoMessage(
      author: DemoMessageAuthor.buyer,
      text: 'Hello Elena, is the vase suitable for fresh flowers?',
      time: '10:24 AM',
    ),
    const DemoMessage(
      author: DemoMessageAuthor.artisan,
      text: 'Yes, it is glazed inside and made for everyday use.',
      time: '10:31 AM',
    ),
  ];

  void send(DemoMessageAuthor author, String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    messages.add(DemoMessage(author: author, text: clean, time: 'Now'));
    notifyListeners();
  }
}

final craftisanDemoMessages = CraftisanDemoMessages();
