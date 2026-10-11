import '../../../shared/data/marketplace_repository.dart';
import 'mock_payout_api.dart';

class DemoBankAccount {
  const DemoBankAccount({
    required this.holder,
    required this.bank,
    required this.branch,
    required this.number,
  });
  final String holder, bank, branch, number;
  String get maskedNumber => '•••• ${number.substring(number.length - 4)}';
}

class DemoPayout {
  const DemoPayout(
    this.id,
    this.amountCents,
    this.createdAt, {
    this.destination,
  });
  final String id;
  final int amountCents;
  final DateTime createdAt;
  final String? destination;
}

class DemoWallet {
  const DemoWallet(this.availableCents, this.history);
  final int availableCents;
  final List<DemoPayout> history;
}

/// Session-only sample funds. Has no bank, Firebase, or real-earnings connection.
class DemoCashOutRepository {
  DemoCashOutRepository({this.api = const MockPayoutApi()});
  final MockPayoutApi api;
  bool _processing = false;
  DemoBankAccount? bankAccount;
  void saveBankAccount(DemoBankAccount account) {
    if (account.holder.trim().isEmpty ||
        account.bank.trim().isEmpty ||
        account.branch.trim().isEmpty ||
        !RegExp(r'^\d{6,24}$').hasMatch(account.number)) {
      throw const MarketplaceFailure('Enter complete bank account details.');
    }
    bankAccount = account;
  }

  static const initialCents = 100000;
  int _availableCents = initialCents;
  int _sequence = 0;
  final _history = <DemoPayout>[];
  String newRequestId() =>
      'DEMO-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}';
  static String money(int cents) => 'LKR ${(cents / 100).toStringAsFixed(2)}';
  static int? parseAmount(String value) {
    final text = value.trim();
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null || whole > initialCents ~/ 100) return null;
    return whole * 100 +
        (parts.length == 1 ? 0 : int.parse(parts.last.padRight(2, '0')));
  }

  Future<DemoWallet> load() async =>
      DemoWallet(_availableCents, List.unmodifiable(_history));

  Future<void> withdraw(
    String requestId,
    int amountCents, {
    MockPayoutOutcome outcome = MockPayoutOutcome.success,
  }) async {
    if (amountCents <= 0 || amountCents > initialCents) {
      throw const MarketplaceFailure('Enter a valid cash out amount.');
    }
    final prior = _history.where((payout) => payout.id == requestId);
    if (prior.isNotEmpty) {
      if (prior.first.amountCents != amountCents) {
        throw const MarketplaceFailure('This payout reference already exists.');
      }
      return;
    }
    if (amountCents > _availableCents) {
      throw const MarketplaceFailure('Insufficient balance.');
    }
    if (_processing) {
      throw const MarketplaceFailure('A cash out is already processing.');
    }
    _processing = true;
    try {
      await api.transfer(requestId, amountCents, outcome);
      _availableCents -= amountCents;
      _history.insert(
        0,
        DemoPayout(
          requestId,
          amountCents,
          DateTime.now(),
          destination: bankAccount == null
              ? null
              : '${bankAccount!.bank} · ${bankAccount!.maskedNumber}',
        ),
      );
    } on MockPayoutDeclined {
      throw const MarketplaceFailure('Cash out failed. Balance unchanged.');
    } catch (error) {
      throw const MarketplaceFailure(
        'Cash out unavailable. Balance unchanged. Try again.',
      );
    } finally {
      _processing = false;
    }
  }
}
