import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/data/delivery_workflow_repository.dart';
import '../../../shared/data/marketplace_repository.dart';
import '../models/delivery_order.dart';

class DeliveryExtrasData {
  Map<String, dynamic>? plan;
  final photos = <String, Uint8List>{};
  final attempts = <Map<String, dynamic>>[];
}

class DeliveryExtras extends StatefulWidget {
  const DeliveryExtras({
    super.key,
    required this.order,
    required this.demoData,
    required this.onHoldChanged,
    this.pickPhoto,
  });
  final DeliveryOrder order;
  final DeliveryExtrasData demoData;
  final ValueChanged<bool> onHoldChanged;
  final Future<Uint8List?> Function(ImageSource)? pickPhoto;
  @override
  State<DeliveryExtras> createState() => _DeliveryExtrasState();
}

class _DeliveryExtrasState extends State<DeliveryExtras> {
  DeliveryWorkflowRepository? _repository;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _planSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _proofSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _attemptSubscription;
  Map<String, dynamic>? _plan;
  List<Map<String, dynamic>> _attempts = [];
  final _proofs = <String, Future<Uint8List?>>{};
  final _proofVersions = <String, String>{};
  bool _loading = false;
  bool _busy = false;
  Timer? _retryTimer;
  String? _error;
  bool get _demo => !MarketplaceBackend.enabled;
  bool get _held =>
      _loading || _busy || (_plan != null && _plan!['outcome'] != 'active');

  @override
  void initState() {
    super.initState();
    if (_demo) {
      _plan = widget.demoData.plan;
      _attempts = widget.demoData.attempts;
      _scheduleRetry();
      _publishHold();
      return;
    }
    if (widget.order.status == DeliveryStatus.pending) {
      _publishHold();
      return;
    }
    _connect();
  }

  @override
  void didUpdateWidget(covariant DeliveryExtras oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_demo &&
        _repository == null &&
        widget.order.status != DeliveryStatus.pending) {
      _connect();
      _publishHold();
    }
  }

  void _connect() {
    _loading = true;
    _repository = DeliveryWorkflowRepository(MarketplaceRepository());
    _planSubscription = _repository!
        .plan(widget.order.id)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _plan = snap.data();
              _loading = false;
            });
            _scheduleRetry();
            _publishHold();
          },
          onError: (Object e) {
            _showError(e);
          },
        );
    final ref = _repository!.marketplace.db
        .collection('orders')
        .doc(widget.order.id);
    _proofSubscription = ref
        .collection('deliveryProofs')
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              for (final doc in snap.docs) {
                final data = doc.data();
                final path = data['path'] as String;
                final version = '$path/${data['createdAt']}';
                if (_proofVersions[doc.id] != version) {
                  _proofVersions[doc.id] = version;
                  _proofs[doc.id] = FirebaseStorage.instance
                      .ref(path)
                      .getData(10 * 1024 * 1024);
                }
              }
            });
          },
          onError: (Object e) {
            _showError(e);
          },
        );
    _attemptSubscription = ref
        .collection('deliveryAttempts')
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _attempts = snap.docs.map((doc) => doc.data()).toList()
                ..sort(
                  (a, b) =>
                      ((b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                              0)
                          .compareTo(
                            (a['createdAt'] as Timestamp?)
                                    ?.millisecondsSinceEpoch ??
                                0,
                          ),
                );
            });
          },
          onError: (Object e) {
            _showError(e);
          },
        );
  }

  void _publishHold() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onHoldChanged(_held);
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final retry = (_plan?['retryAt'] as Timestamp?)?.toDate();
    if (retry != null && retry.isAfter(DateTime.now())) {
      _retryTimer = Timer(
        retry.difference(DateTime.now()) + const Duration(seconds: 1),
        () {
          if (mounted) setState(() {});
        },
      );
    }
  }

  void _showError(Object e) {
    if (mounted) setState(() => _error = marketplaceError(e));
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _planSubscription?.cancel();
    _proofSubscription?.cancel();
    _attemptSubscription?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _publishHold();
    try {
      await action();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scheduleRetry();
        _publishHold();
      }
    }
  }

  Future<void> _photo(String stage) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add proof photo'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('Take photo'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('Choose from gallery'),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;
    await _run(() async {
      Uint8List? bytes;
      if (widget.pickPhoto != null) {
        bytes = await widget.pickPhoto!(source);
      } else {
        final image = await ImagePicker().pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        bytes = await image?.readAsBytes();
      }
      if (bytes == null) return;
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw const MarketplaceFailure('Choose a photo smaller than 10 MB.');
      }
      if (_demo) {
        widget.demoData.photos[stage] = bytes;
      } else {
        await _repository!.uploadProof(widget.order.id, stage, bytes);
      }
    });
  }

  Future<void> _attempt() async {
    final attempt = await showDialog<DeliveryAttemptInput>(
      context: context,
      builder: (_) => const _AttemptDialog(),
    );
    if (attempt == null || !mounted) return;
    await _run(() async {
      if (_demo) {
        final plan = <String, dynamic>{
          'outcome': attempt.outcome,
          'reason': attempt.reason,
          'notes': attempt.notes,
          'retryAt': attempt.retryAt == null
              ? null
              : Timestamp.fromDate(attempt.retryAt!),
          'createdAt': Timestamp.now(),
        };
        widget.demoData.plan = plan;
        widget.demoData.attempts.insert(0, Map.of(plan));
        _plan = plan;
      } else {
        await _repository!.saveAttempt(
          widget.order.id,
          attempt.outcome,
          attempt.reason,
          attempt.notes,
          retryAt: attempt.retryAt,
        );
        _plan = {
          'outcome': attempt.outcome,
          'reason': attempt.reason,
          'notes': attempt.notes,
          'retryAt': attempt.retryAt == null
              ? null
              : Timestamp.fromDate(attempt.retryAt!),
        };
      }
    });
  }

  Future<void> _resume() => _run(() async {
    if (_demo) {
      final retry = _plan?['retryAt'] as Timestamp?;
      if (retry != null && retry.toDate().isAfter(DateTime.now())) {
        throw const MarketplaceFailure('Wait until the scheduled retry time.');
      }
      _plan = {..._plan!, 'outcome': 'active'};
      widget.demoData.plan = _plan;
    } else {
      await _repository!.resumeDelivery(widget.order.id);
      _plan = {..._plan!, 'outcome': 'active'};
    }
  });

  Widget _photoPreview(String stage) {
    if (_demo) {
      final bytes = widget.demoData.photos[stage];
      return bytes == null ? const SizedBox.shrink() : _thumbnail(bytes);
    }
    final future = _proofs[stage];
    return future == null
        ? const SizedBox.shrink()
        : FutureBuilder<Uint8List?>(
            future: future,
            builder: (_, snap) {
              if (snap.hasError) {
                return const Text(
                  'Photo could not be loaded. Reopen the order to retry.',
                );
              }
              if (!snap.hasData) return const LinearProgressIndicator();
              return _thumbnail(snap.data!);
            },
          );
  }

  Widget _thumbnail(Uint8List bytes) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Image.memory(
      bytes,
      height: 120,
      fit: BoxFit.contain,
      errorBuilder: (_, error, stack) =>
          const Text('Photo preview unavailable.'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final status = widget.order.status;
    final active = status != DeliveryStatus.pending && !widget.order.delivered;
    final retry = (_plan?['retryAt'] as Timestamp?)?.toDate().toLocal();
    final canResume = ['failed', 'rescheduled'].contains(_plan?['outcome']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_demo && (active || widget.demoData.photos.isNotEmpty))
          const Text(
            'Demo photos and retry details are saved for this session only.',
          ),
        if (status != DeliveryStatus.pending) ...[
          const Text(
            'Photo proof',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          _photoPreview('pickup'),
          if (active)
            OutlinedButton.icon(
              onPressed: _busy || _loading ? null : () => _photo('pickup'),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add pickup photo'),
            ),
          _photoPreview('dropoff'),
          if (status == DeliveryStatus.onTheWay || widget.order.delivered)
            OutlinedButton.icon(
              onPressed: _busy || _loading ? null : () => _photo('dropoff'),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add delivery photo'),
            ),
        ],
        if (_loading) const LinearProgressIndicator(),
        if (_plan != null && _plan!['outcome'] != 'active') ...[
          Text(
            _outcomeLabel(_plan!['outcome'] as String),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${_plan!['reason']}${(_plan!['notes'] as String? ?? '').isEmpty ? '' : ': ${_plan!['notes']}'}',
          ),
          if (retry != null)
            Text(
              'Retry: ${MaterialLocalizations.of(context).formatMediumDate(retry)} '
              '${TimeOfDay.fromDateTime(retry).format(context)}',
            ),
          if (_plan!['outcome'] == 'returnRequested')
            const Text('Contact support to arrange the parcel return.'),
          if (active && canResume)
            TextButton(
              onPressed:
                  _busy || (retry != null && retry.isAfter(DateTime.now()))
                  ? null
                  : _resume,
              child: const Text('Resume delivery'),
            ),
        ],
        if (active && _plan?['outcome'] != 'returnRequested')
          TextButton.icon(
            onPressed: _busy || _loading ? null : _attempt,
            icon: const Icon(Icons.event_repeat),
            label: const Text('Failed delivery / reschedule'),
          ),
        for (final attempt in _attempts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(_outcomeLabel(attempt['outcome'] as String)),
            subtitle: Text(
              '${attempt['reason']}${(attempt['notes'] as String? ?? '').isEmpty ? '' : ': ${attempt['notes']}'}'
              '${attempt['retryAt'] == null ? '' : '\nRetry: ${(attempt['retryAt'] as Timestamp).toDate().toLocal()}'}',
            ),
          ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

String _outcomeLabel(String outcome) => switch (outcome) {
  'failed' => 'Delivery failed',
  'rescheduled' => 'Delivery rescheduled',
  'returnRequested' => 'Return requested',
  _ => 'Delivery resumed',
};

class DeliveryAttemptInput {
  const DeliveryAttemptInput(
    this.outcome,
    this.reason,
    this.notes,
    this.retryAt,
  );
  final String outcome, reason, notes;
  final DateTime? retryAt;
}

class _AttemptDialog extends StatefulWidget {
  const _AttemptDialog();
  @override
  State<_AttemptDialog> createState() => _AttemptDialogState();
}

class _AttemptDialogState extends State<_AttemptDialog> {
  final _form = GlobalKey<FormState>();
  final _notes = TextEditingController();
  String _outcome = 'failed';
  String _reason = deliveryIssueReasons.first;
  DateTime? _retryAt;
  String? _error;
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _chooseTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _retryAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _retryAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _retryAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Failed delivery / reschedule'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _outcome,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Next step'),
              items: [
                for (final outcome in [
                  'failed',
                  'rescheduled',
                  'returnRequested',
                ])
                  DropdownMenuItem(
                    value: outcome,
                    child: Text(_outcomeLabel(outcome)),
                  ),
              ],
              onChanged: (value) => setState(() => _outcome = value!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: [
                for (final reason in deliveryIssueReasons)
                  DropdownMenuItem(value: reason, child: Text(reason)),
              ],
              onChanged: (value) => setState(() => _reason = value!),
            ),
            TextFormField(
              controller: _notes,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Details'),
              validator: (value) =>
                  _reason == 'Other' && (value ?? '').trim().isEmpty
                  ? 'Describe the issue.'
                  : null,
            ),
            if (_outcome == 'rescheduled')
              TextButton.icon(
                onPressed: _chooseTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  _retryAt == null
                      ? 'Choose retry date and time'
                      : '${MaterialLocalizations.of(context).formatMediumDate(_retryAt!)} ${TimeOfDay.fromDateTime(_retryAt!).format(context)}',
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          if (_outcome == 'rescheduled' &&
              (_retryAt == null || !_retryAt!.isAfter(DateTime.now()))) {
            setState(() => _error = 'Choose a future retry date and time.');
            return;
          }
          Navigator.pop(
            context,
            DeliveryAttemptInput(
              _outcome,
              _reason,
              _notes.text.trim(),
              _retryAt,
            ),
          );
        },
        child: const Text('Save delivery attempt'),
      ),
    ],
  );
}
