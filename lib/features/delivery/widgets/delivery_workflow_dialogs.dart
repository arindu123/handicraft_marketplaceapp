import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/data/delivery_workflow_repository.dart';
import '../../../shared/data/marketplace_repository.dart';

Future<String?> requestDeliveryCode(
  BuildContext context, {
  required bool demo,
}) => showDialog<String>(
  context: context,
  builder: (_) => _CodeDialog(demo: demo),
);

class _CodeDialog extends StatefulWidget {
  const _CodeDialog({required this.demo});
  final bool demo;
  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _code = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Confirm delivery'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.demo ? 'Demo code: 123456' : 'Ask the customer for the six-digit code on their Order Details page after handing over the parcel.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Delivery code'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) {
                if (!RegExp(r'^\d{6}$').hasMatch(value ?? '')) {
                  return 'Enter all six digits.';
                }
                if (widget.demo && value != '123456') {
                  return 'Incorrect code. Try 123456.';
                }
                return null;
              },
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
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _code.text);
          }
        },
        child: const Text('Confirm delivery'),
      ),
    ],
  );
}

Future<bool?> reportDeliveryIssue(
  BuildContext context, {
  required Future<void> Function(String reason, String notes) save,
  required bool demo,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _IssueDialog(save: save, demo: demo),
);

class _IssueDialog extends StatefulWidget {
  const _IssueDialog({required this.save, required this.demo});
  final Future<void> Function(String, String) save;
  final bool demo;
  @override
  State<_IssueDialog> createState() => _IssueDialogState();
}

class _IssueDialogState extends State<_IssueDialog> {
  final _notes = TextEditingController();
  final _form = GlobalKey<FormState>();
  String _reason = deliveryIssueReasons.first;
  String? _error;
  bool _saving = false;
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.save(_reason, _notes.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = marketplaceError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Report delivery issue'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.demo)
                const Text('Demo reports are saved for this session only.'),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: [
                  for (final reason in deliveryIssueReasons)
                    DropdownMenuItem(value: reason, child: Text(reason)),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _reason = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                enabled: !_saving,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Details'),
                validator: (value) =>
                    _reason == 'Other' && (value ?? '').trim().isEmpty
                    ? 'Describe the issue.'
                    : null,
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
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving…' : 'Submit report'),
        ),
      ],
    ),
  );
}
