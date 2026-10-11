import 'dart:convert';
import 'dart:io';

enum MockPayoutOutcome { success, declined, unavailable }

/// An actual HTTP request to a temporary loopback server, using sample data only.
/// This does not contact a bank or an external service.
class MockPayoutApi {
  const MockPayoutApi({this.delay = const Duration(milliseconds: 900)});
  final Duration delay;

  Future<void> transfer(
    String requestId,
    int amountCents,
    MockPayoutOutcome outcome,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final subscription = server.listen((request) async {
      try {
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        if (request.method != 'POST' ||
            request.uri.path != '/payouts' ||
            body['requestId'] != requestId ||
            body['amountCents'] != amountCents ||
            body['currency'] != 'LKR') {
          request.response.statusCode = 400;
        } else {
          await Future<void>.delayed(delay);
          request.response.statusCode = outcome == MockPayoutOutcome.unavailable
              ? 503
              : 200;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'requestId': requestId,
              'status': outcome == MockPayoutOutcome.success
                  ? 'success'
                  : 'failed',
              'testMode': true,
            }),
          );
        }
        await request.response.close();
      } catch (_) {
        request.response.statusCode = 400;
        await request.response.close();
      }
    });
    try {
      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:${server.port}/payouts'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'requestId': requestId,
          'amountCents': amountCents,
          'currency': 'LKR',
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != 200) {
        throw const SocketException('Mock payout API unavailable.');
      }
      final result = jsonDecode(body);
      if (result['requestId'] != requestId || result['testMode'] != true) {
        throw const FormatException('Invalid mock payout response.');
      }
      if (result['status'] != 'success') {
        throw const MockPayoutDeclined();
      }
    } finally {
      client.close(force: true);
      await subscription.cancel();
      await server.close(force: true);
    }
  }
}

class MockPayoutDeclined implements Exception {
  const MockPayoutDeclined();
}
