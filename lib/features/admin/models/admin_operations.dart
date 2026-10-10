import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReport {
  const AdminReport({
    required this.sourcePath,
    required this.kind,
    required this.targetId,
    required this.reporterId,
    required this.reason,
    required this.notes,
    this.createdAt,
    this.status = 'Open',
    this.resolution = '',
    this.resolvedBy = '',
  });

  final String sourcePath, kind, targetId, reporterId, reason, notes;
  final String status, resolution, resolvedBy;
  final DateTime? createdAt;
  String get resolutionId =>
      base64Url.encode(utf8.encode(sourcePath)).replaceAll('=', '');

  factory AdminReport.fromMap(
    String path,
    Map<String, dynamic> data, [
    Map<String, dynamic>? resolution,
  ]) => AdminReport(
    sourcePath: path,
    kind: data['kind'] as String? ?? 'Delivery',
    targetId: data['targetId'] as String? ?? path.split('/')[1],
    reporterId:
        data['reporterId'] as String? ?? data['courierId'] as String? ?? '',
    reason: data['reason'] as String? ?? '',
    notes: data['notes'] as String? ?? '',
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    status: resolution?['status'] as String? ?? 'Open',
    resolution: resolution?['notes'] as String? ?? '',
    resolvedBy: resolution?['resolvedBy'] as String? ?? '',
  );
}

class AdminActivity {
  const AdminActivity({
    required this.actorId,
    required this.action,
    required this.collection,
    required this.targetId,
    required this.before,
    required this.after,
    this.createdAt,
  });
  final String actorId, action, collection, targetId;
  final Map<String, dynamic> before, after;
  final DateTime? createdAt;
  factory AdminActivity.fromMap(Map<String, dynamic> data) => AdminActivity(
    actorId: data['actorId'] as String,
    action: data['action'] as String,
    collection: data['collection'] as String,
    targetId: data['targetId'] as String,
    before: Map<String, dynamic>.from(data['before'] as Map),
    after: Map<String, dynamic>.from(data['after'] as Map),
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
  );
  Iterable<String> get changedFields =>
      after.keys.where((key) => before[key] != after[key]);
}
