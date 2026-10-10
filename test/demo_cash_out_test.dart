import 'dart:async';
import 'dart:io';

import 'package:artisan_marketplace/features/delivery/services/demo_cash_out_repository.dart';
import 'package:artisan_marketplace/features/delivery/services/mock_payout_api.dart';
import 'package:artisan_marketplace/features/delivery/widgets/demo_cash_out_dialog.dart';
import 'package:artisan_marketplace/shared/data/marketplace_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoCashOutRepository repository;
  setUp(() {
    repository = DemoCashOutRepository(api: const _HttpMockApi());
  });
  test('Test payout debits once and resets in a new demo session', () async {
    await repository.withdraw('test-one', 25000);
    await repository.withdraw('test-one', 25000);
    final wallet = await repository.load();
    expect(wallet.availableCents, 75000);
    expect(wallet.history, hasLength(1));
    final restored = DemoCashOutRepository();
    expect((await restored.load()).availableCents, 100000);
    expect((await restored.load()).history, isEmpty);
    await expectLater(
      repository.withdraw('test-one', 100),
      throwsA(isA<MarketplaceFailure>()),
    );
    await expectLater(
      repository.withdraw('too-large', 80000),
      throwsA(isA<MarketplaceFailure>()),
    );
    expect((await repository.load()).history, hasLength(1));
  });
  test('Amounts validate exact cents and reject invalid or negative input', () {
    expect(DemoCashOutRepository.parseAmount('12.50'), 1250);
    expect(DemoCashOutRepository.parseAmount('1.2'), 120);
    for (final value in ['-1', 'NaN', '1.234', '1001', '', '1e3']) {
      expect(DemoCashOutRepository.parseAmount(value), isNull);
    }
  });
  test(
    'Failed and unavailable HTTP responses preserve funds and allow retry',
    () async {
      for (final outcome in [
        MockPayoutOutcome.declined,
        MockPayoutOutcome.unavailable,
      ]) {
        await expectLater(
          repository.withdraw('retry', 25000, outcome: outcome),
          throwsA(isA<MarketplaceFailure>()),
        );
        expect((await repository.load()).availableCents, 100000);
        expect((await repository.load()).history, isEmpty);
      }
      await repository.withdraw('retry', 25000);
      expect((await repository.load()).availableCents, 75000);
      expect((await repository.load()).history, hasLength(1));
    },
  );
  test(
    'Concurrent requests cannot overspend or duplicate a pending payout',
    () async {
      final first = repository.withdraw('first', 75000);
      await expectLater(
        repository.withdraw('second', 75000),
        throwsA(isA<MarketplaceFailure>()),
      );
      await first;
      expect((await repository.load()).availableCents, 25000);
      expect((await repository.load()).history, hasLength(1));
    },
  );
  testWidgets(
    'Cash out is visibly a simulation and runs without admin approval',
    (tester) async {
      final api = _WidgetMockApi();
      repository = DemoCashOutRepository(api: api);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DemoCashOutDialog(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cash out'), findsNWidgets(2));
      expect(find.textContaining('no money is transferred'), findsOneWidget);
      await tester.ensureVisible(find.text('Cash out').last);
      await tester.tap(find.text('Cash out').last);
      await tester.pumpAndSettle();
      expect(find.text('Enter Account holder name.'), findsOneWidget);
      expect((await repository.load()).history, isEmpty);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Demo Courier');
      await tester.enterText(fields.at(1), 'Sample Bank');
      await tester.enterText(fields.at(2), 'Sample Branch');
      await tester.enterText(fields.at(3), '1234567890');
      await tester.enterText(fields.at(4), '250');
      await tester.ensureVisible(find.text('Cash out').last);
      await tester.tap(find.text('Cash out').last);
      await tester.pump();
      expect(find.textContaining('Processing'), findsOneWidget);
      expect((await repository.load()).availableCents, 100000);
      api.completion.complete();
      await tester.pumpAndSettle();
      expect(find.text('Available balance: LKR 750.00'), findsOneWidget);
      expect(find.text('LKR 250.00 · Demo completed'), findsOneWidget);
      expect(find.textContaining('Demo cash out completed'), findsOneWidget);
      expect(repository.bankAccount!.holder, 'Demo Courier');
      expect(repository.bankAccount!.maskedNumber, '•••• 7890');
      expect(
        (await repository.load()).history.single.destination,
        'Sample Bank · •••• 7890',
      );
      expect(find.text('Mock API result'), findsNothing);
      expect(find.textContaining('Test mode'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _WidgetMockApi extends MockPayoutApi {
  final completion = Completer<void>();
  @override
  Future<void> transfer(
    String requestId,
    int amountCents,
    MockPayoutOutcome outcome,
  ) => completion.future;
}

class _HttpMockApi extends MockPayoutApi {
  const _HttpMockApi() : super(delay: Duration.zero);
  @override
  Future<void> transfer(
    String requestId,
    int amountCents,
    MockPayoutOutcome outcome,
  ) => HttpOverrides.runWithHttpOverrides(
    () => super.transfer(requestId, amountCents, outcome),
    _RealHttpOverrides(),
  );
}

class _RealHttpOverrides extends HttpOverrides {}
