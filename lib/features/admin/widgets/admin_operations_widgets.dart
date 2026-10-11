import 'package:flutter/material.dart';

import '../../../shared/data/marketplace_repository.dart';
import '../../../shared/models/delivery_fee_policy.dart';
import '../models/admin_demo_store.dart';
import '../models/admin_operations.dart';
import 'admin_widgets.dart';

class AdminDeliveryFeePanel extends StatefulWidget {
  const AdminDeliveryFeePanel({super.key, required this.store});
  final AdminDemoStore store;
  @override
  State<AdminDeliveryFeePanel> createState() => _AdminDeliveryFeePanelState();
}

class _AdminDeliveryFeePanelState extends State<AdminDeliveryFeePanel> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _fee;
  late final TextEditingController _threshold;
  bool _dirty = false, _saving = false;
  @override
  void initState() {
    super.initState();
    _fee = TextEditingController();
    _threshold = TextEditingController();
    _sync();
    widget.store.addListener(_sync);
  }

  void _sync() {
    if (_dirty || _saving) return;
    _fee.text = widget.store.deliveryPolicy.fee.toStringAsFixed(2);
    _threshold.text = widget.store.deliveryPolicy.freeDeliveryThreshold
        .toStringAsFixed(2);
  }

  @override
  void dispose() {
    widget.store.removeListener(_sync);
    _fee.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.store.saveDeliveryPolicy(
        DeliveryFeePolicy(
          fee: double.parse(_fee.text.trim()),
          freeDeliveryThreshold: double.parse(_threshold.text.trim()),
        ),
      );
      if (!mounted) return;
      _dirty = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Delivery fee settings saved. Existing orders are unchanged.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(marketplaceError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _amount(
    String label,
    TextEditingController controller,
    double maximum,
  ) => TextFormField(
    controller: controller,
    enabled: !_saving,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, prefixText: 'LKR '),
    onChanged: (_) => _dirty = true,
    validator: (value) {
      final amount = double.tryParse(value?.trim() ?? '');
      return amount == null || !DeliveryFeePolicy.validAmount(amount, maximum)
          ? 'Enter 0–${maximum.toInt()} with up to two decimal places.'
          : null;
    },
  );
  @override
  Widget build(BuildContext context) => AdminPanel(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Delivery fee settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AdminStyle.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Applies to new LKR orders. Courier earnings and existing orders stay unchanged.',
            style: TextStyle(color: AdminStyle.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          _amount('Delivery fee', _fee, 100000),
          const SizedBox(height: 14),
          _amount('Free delivery from', _threshold, 10000000),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminStyle.clay),
            onPressed:
                widget.store.connected &&
                    widget.store.settingsLoaded &&
                    !_saving
                ? _save
                : null,
            child: Text(_saving ? 'Saving…' : 'Save delivery fees'),
          ),
        ],
      ),
    ),
  );
}

class AdminReportsPanel extends StatefulWidget {
  const AdminReportsPanel({super.key, required this.store});
  final AdminDemoStore store;
  @override
  State<AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends State<AdminReportsPanel> {
  String _filter = 'Open';
  void _open([AdminReport? report]) => showDialog<void>(
    context: context,
    builder: (_) => _ComplaintDialog(store: widget.store, report: report),
  );
  @override
  Widget build(BuildContext context) {
    final reports = widget.store.reports.where(
      (report) => _filter == 'All' || report.status == _filter,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.store.connected ? () => _open() : null,
            icon: const Icon(Icons.add),
            label: const Text('Record complaint'),
            style: TextButton.styleFrom(foregroundColor: AdminStyle.clay),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final filter in ['Open', 'Resolved', 'All'])
              ChoiceChip(
                label: Text(filter),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (reports.isEmpty) const AdminEmptyState('No matching complaints.'),
        for (final report in reports)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        report.kind,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      AdminStatus(report.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText('Reference: ${report.targetId}'),
                  Text(
                    report.reason,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (report.notes.isNotEmpty) Text(report.notes),
                  Text(
                    'Reported by: ${report.reporterId}',
                    style: const TextStyle(color: AdminStyle.muted),
                  ),
                  if (report.createdAt != null)
                    Text(
                      report.createdAt!.toLocal().toString().split('.').first,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AdminStyle.muted,
                      ),
                    ),
                  if (report.status == 'Resolved') ...[
                    const Divider(),
                    Text('Resolution: ${report.resolution}'),
                    Text(
                      'Resolved by: ${report.resolvedBy}',
                      style: const TextStyle(color: AdminStyle.muted),
                    ),
                  ] else
                    TextButton(
                      onPressed: () => _open(report),
                      child: const Text(
                        'Resolve complaint',
                        style: TextStyle(color: AdminStyle.clay),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ComplaintDialog extends StatefulWidget {
  const _ComplaintDialog({required this.store, this.report});
  final AdminDemoStore store;
  final AdminReport? report;
  @override
  State<_ComplaintDialog> createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends State<_ComplaintDialog> {
  final _form = GlobalKey<FormState>();
  final _reference = TextEditingController(),
      _reporter = TextEditingController();
  final _reason = TextEditingController(), _notes = TextEditingController();
  String _kind = 'Product';
  String? _error;
  bool _saving = false;
  @override
  void dispose() {
    _reference.dispose();
    _reporter.dispose();
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller,
    int maximum, {
    bool required = true,
    int lines = 1,
  }) => TextFormField(
    controller: controller,
    enabled: !_saving,
    maxLength: maximum,
    maxLines: lines,
    decoration: InputDecoration(labelText: label),
    validator: (value) =>
        required && (value?.trim().isEmpty ?? true) ? 'Enter $label.' : null,
  );
  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.report != null) {
        await widget.store.operations.resolveReport(
          widget.report!,
          _notes.text,
        );
      } else {
        await widget.store.operations.createReport(
          kind: _kind,
          targetId: _reference.text,
          reporterId: _reporter.text,
          reason: _reason.text,
          notes: _notes.text,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = marketplaceError(error);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        widget.report == null ? 'Record complaint' : 'Resolve complaint',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.report == null) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _kind,
                    decoration: const InputDecoration(
                      labelText: 'Complaint type',
                    ),
                    items: [
                      for (final kind in ['Product', 'Delivery', 'Order'])
                        DropdownMenuItem(value: kind, child: Text(kind)),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _kind = value!),
                  ),
                  _field('Product / order ID', _reference, 128),
                  _field('Reporter name / ID', _reporter, 200),
                  _field('Complaint', _reason, 200),
                ] else
                  Text(widget.report!.reason),
                _field(
                  widget.report == null ? 'Details' : 'Resolution note',
                  _notes,
                  2000,
                  required: widget.report != null,
                  lines: 3,
                ),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: AdminStyle.clay)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AdminStyle.clay),
          child: Text(
            _saving
                ? 'Saving…'
                : widget.report == null
                ? 'Save complaint'
                : 'Mark resolved',
          ),
        ),
      ],
    ),
  );
}

class AdminActivityPanel extends StatelessWidget {
  const AdminActivityPanel({super.key, required this.store});
  final AdminDemoStore store;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Latest 100 admin actions',
        style: TextStyle(color: AdminStyle.muted),
      ),
      const SizedBox(height: 12),
      if (store.activity.isEmpty)
        const AdminEmptyState('No recorded admin activity yet.'),
      for (final activity in store.activity)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AdminStyle.navy,
                  ),
                ),
                SelectableText('Admin: ${activity.actorId}'),
                SelectableText('${activity.collection} / ${activity.targetId}'),
                if (activity.createdAt != null)
                  Text(
                    activity.createdAt!.toLocal().toString().split('.').first,
                    style: const TextStyle(
                      color: AdminStyle.muted,
                      fontSize: 12,
                    ),
                  ),
                for (final field in activity.changedFields.where(
                  (field) => ![
                    'updatedAt',
                    'createdAt',
                    'updatedBy',
                    'resolvedBy',
                    'submittedBy',
                  ].contains(field),
                ))
                  Text(
                    '$field: ${activity.before[field] ?? '—'} → ${activity.after[field]}',
                  ),
              ],
            ),
          ),
        ),
    ],
  );
}
