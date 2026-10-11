import 'package:flutter/material.dart';

import '../../../shared/data/marketplace_repository.dart';
import '../services/demo_cash_out_repository.dart';
import 'delivery_widgets.dart';

class DemoCashOutDialog extends StatefulWidget {
  const DemoCashOutDialog({super.key, required this.repository});
  final DemoCashOutRepository repository;
  @override
  State<DemoCashOutDialog> createState() => _DemoCashOutDialogState();
}

class _DemoCashOutDialogState extends State<DemoCashOutDialog> {
  final _amount = TextEditingController();
  final _form = GlobalKey<FormState>();
  DemoWallet? _wallet;
  String? _requestId, _error, _result;
  bool _busy = false;
  final _holder = TextEditingController();
  final _bank = TextEditingController();
  final _branch = TextEditingController();
  final _account = TextEditingController();
  @override
  void initState() {
    super.initState();
    final account = widget.repository.bankAccount;
    if (account != null) {
      _holder.text = account.holder;
      _bank.text = account.bank;
      _branch.text = account.branch;
      _account.text = account.number;
    }
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _holder.dispose();
    _bank.dispose();
    _branch.dispose();
    _account.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final wallet = await widget.repository.load();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = marketplaceError(error));
    }
  }

  Future<void> _withdraw() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final cents = DemoCashOutRepository.parseAmount(_amount.text)!;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      _requestId ??= widget.repository.newRequestId();
      widget.repository.saveBankAccount(
        DemoBankAccount(
          holder: _holder.text.trim(),
          bank: _bank.text.trim(),
          branch: _branch.text.trim(),
          number: _account.text.trim(),
        ),
      );
      await widget.repository.withdraw(_requestId!, cents);
      if (!mounted) return;
      final reference = _requestId!;
      _requestId = null;
      _amount.clear();
      setState(() {
        _wallet = null;
        _result = 'Demo cash out completed. Reference: $reference';
      });
      await _load();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = '${marketplaceError(error)} Reference: $_requestId',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _bankField(
    TextEditingController controller,
    String label, {
    bool accountNumber = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      keyboardType: accountNumber ? TextInputType.number : TextInputType.text,
      maxLength: accountNumber ? 24 : 100,
      decoration: InputDecoration(labelText: label, counterText: ''),
      onChanged: (_) => _requestId = null,
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return 'Enter $label.';
        if (accountNumber && !RegExp(r'^\d{6,24}$').hasMatch(text)) {
          return 'Enter 6 to 24 digits.';
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Cash out'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Demo: no money is transferred. Use sample bank details. Balance and account details stay in this session only.',
              ),
              const SizedBox(height: 16),
              if (_wallet == null && _error == null)
                const Center(child: CircularProgressIndicator()),
              if (_wallet != null) ...[
                Text(
                  'Available balance: ${DemoCashOutRepository.money(_wallet!.availableCents)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      _bankField(_holder, 'Account holder name'),
                      _bankField(_bank, 'Bank name'),
                      _bankField(_branch, 'Branch'),
                      _bankField(
                        _account,
                        'Account number',
                        accountNumber: true,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amount,
                        enabled: !_busy,
                        maxLength: 12,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cash out amount',
                          prefixText: 'LKR ',
                        ),
                        onChanged: (_) {
                          _requestId = null;
                        },
                        validator: (value) {
                          final cents = DemoCashOutRepository.parseAmount(
                            value ?? '',
                          );
                          if (cents == null || cents <= 0) {
                            return 'Enter a positive amount with up to two decimals.';
                          }
                          return cents > _wallet!.availableCents
                              ? 'Insufficient balance.'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy || _wallet!.availableCents == 0
                      ? null
                      : _withdraw,
                  style: FilledButton.styleFrom(
                    backgroundColor: DeliveryStyle.orange,
                  ),
                  child: Text(_busy ? 'Processing...' : 'Cash out'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Transaction history',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (_wallet!.history.isEmpty) const Text('No cash outs yet.'),
                for (final payout in _wallet!.history)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DemoCashOutRepository.money(payout.amountCents)} · Demo completed',
                        ),
                        Text(
                          payout.createdAt
                              .toLocal()
                              .toString()
                              .split('.')
                              .first,
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (payout.destination != null)
                          Text(payout.destination!),
                        SelectableText(
                          payout.id,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
              if (_result != null)
                Text(
                  _result!,
                  style: const TextStyle(color: DeliveryStyle.orange),
                ),
              if (_error != null) ...[
                Text(_error!),
                TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Reload balance'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
