import 'dart:convert';

class AdminNotice {
  const AdminNotice({
    required this.category,
    required this.targetId,
    required this.title,
    required this.body,
    required this.revision,
    this.date,
  });
  final String category, targetId, title, body, revision;
  final DateTime? date;
  String get id => base64Url
      .encode(utf8.encode('$category:$targetId:$revision'))
      .replaceAll('=', '');
}
