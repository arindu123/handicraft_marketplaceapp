import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../shared/data/marketplace_repository.dart';
import '../../shared/models/domain_models.dart' as domain;
import '../admin/models/admin_operations.dart';

class BuyerProblemsRepository {
  BuyerProblemsRepository(this.marketplace);
  final MarketplaceRepository marketplace;
  static const reasons = ['Wrong item', 'Damaged item', 'Delivery delay'];

  Stream<List<AdminReport>> reports(String orderId) => marketplace.db
      .collection('marketplaceReports')
      .where('submittedBy', isEqualTo: marketplace.uid)
      .where('reporterId', isEqualTo: marketplace.uid)
      .where('targetId', isEqualTo: orderId)
      .snapshots()
      .map((snapshot) {
        final reports = snapshot.docs
            .map((doc) => AdminReport.fromMap(doc.reference.path, doc.data()))
            .toList();
        reports.sort(
          (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
            a.createdAt ?? DateTime(1970),
          ),
        );
        return reports;
      });

  Stream<DocumentSnapshot<Map<String, dynamic>>> resolution(
    AdminReport report,
  ) => marketplace.db
      .collection('reportResolutions')
      .doc(report.resolutionId)
      .snapshots();

  Future<void> submit(
    String orderId,
    String requestId,
    String reason,
    String notes,
  ) async {
    await marketplace.requireRole(domain.UserRole.buyer);
    if (!reasons.contains(reason) ||
        notes.trim().isEmpty ||
        notes.length > 2000) {
      throw const MarketplaceFailure(
        'Choose a problem and enter notes (up to 2,000 characters).',
      );
    }
    final uid = marketplace.uid;
    final order = marketplace.db.collection('orders').doc(orderId);
    final report = marketplace.db
        .collection('marketplaceReports')
        .doc(requestId);
    await marketplace.db.runTransaction((transaction) async {
      final source = await transaction.get(order);
      final previous = await transaction.get(report);
      if (!source.exists || source.data()?['buyerId'] != uid) {
        throw const MarketplaceFailure(
          'You can only report a problem with your own order.',
        );
      }
      if (previous.exists) {
        final data = previous.data()!;
        if (data['submittedBy'] == uid &&
            data['targetId'] == orderId &&
            data['reason'] == reason &&
            data['notes'] == notes.trim()) {
          return;
        }
        throw const MarketplaceFailure('This report reference already exists.');
      }
      transaction.set(report, {
        'kind': 'Order',
        'targetId': orderId,
        'reporterId': uid,
        'reason': reason,
        'notes': notes.trim(),
        'submittedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

class BuyerOrderProblems extends StatefulWidget {
  const BuyerOrderProblems({
    super.key,
    required this.repository,
    required this.orderId,
  });
  final BuyerProblemsRepository repository;
  final String orderId;
  @override
  State<BuyerOrderProblems> createState() => _BuyerOrderProblemsState();
}

class _BuyerOrderProblemsState extends State<BuyerOrderProblems> {
  late Stream<List<AdminReport>> _reports;
  @override
  void initState() {
    super.initState();
    _reports = widget.repository.reports(widget.orderId);
  }

  @override
  void didUpdateWidget(covariant BuyerOrderProblems oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.repository.marketplace != widget.repository.marketplace) {
      _reports = widget.repository.reports(widget.orderId);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        icon: const Icon(Icons.report_problem_outlined),
        label: const Text('Report a problem'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _ProblemDialog(
            repository: widget.repository,
            orderId: widget.orderId,
          ),
        ),
      ),
      StreamBuilder<List<AdminReport>>(
        stream: _reports,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              'Unable to load reports. Please reopen this order to try again.',
            );
          }
          return Column(
            children: [
              for (final report in snapshot.data ?? <AdminReport>[])
                _ProblemStatus(
                  key: ValueKey(report.sourcePath),
                  repository: widget.repository,
                  report: report,
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _ProblemStatus extends StatefulWidget {
  const _ProblemStatus({
    super.key,
    required this.repository,
    required this.report,
  });
  final BuyerProblemsRepository repository;
  final AdminReport report;
  @override
  State<_ProblemStatus> createState() => _ProblemStatusState();
}

class _ProblemStatusState extends State<_ProblemStatus> {
  late final _resolution = widget.repository.resolution(widget.report);
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _resolution,
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.report.reason,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(widget.report.notes),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.hasError
                        ? 'Status unavailable. Please reopen this order to try again.'
                        : 'Status: ${data?['status'] ?? 'Open'}',
                  ),
                  if (data?['notes'] != null)
                    Text('Resolution: ${data!['notes']}'),
                ],
              ),
            ),
          );
        },
      );
}

class _ProblemDialog extends StatefulWidget {
  const _ProblemDialog({required this.repository, required this.orderId});
  final BuyerProblemsRepository repository;
  final String orderId;
  @override
  State<_ProblemDialog> createState() => _ProblemDialogState();
}

class _ProblemDialogState extends State<_ProblemDialog> {
  final _notes = TextEditingController();
  final _form = GlobalKey<FormState>();
  String _reason = BuyerProblemsRepository.reasons.first;
  late final _requestId = widget.repository.marketplace.db
      .collection('marketplaceReports')
      .doc()
      .id;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.submit(
        widget.orderId,
        _requestId,
        _reason,
        _notes.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Report sent to admin.')));
    } catch (error) {
      if (mounted) setState(() => _error = marketplaceError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Report a problem'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'Problem'),
                items: [
                  for (final reason in BuyerProblemsRepository.reasons)
                    DropdownMenuItem(value: reason, child: Text(reason)),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) setState(() => _reason = value);
                      },
              ),
              TextFormField(
                controller: _notes,
                enabled: !_busy,
                maxLength: 2000,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Notes'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Describe the problem.'
                    : null,
              ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Sending...' : 'Send report'),
        ),
      ],
    ),
  );
}
