import 'package:flutter_test/flutter_test.dart';
import 'package:inttegro_flutter/inttegro_flutter.dart';

void main() {
  group('PaymentSheetConfiguration', () {
    test('normalizes its bridge payload', () {
      final value = PaymentSheetConfiguration(
        orderId: '  or_test  ',
        returnUrl: Uri.parse('merchant-app://inttegro-return'),
      ).toJson();

      expect(value['orderId'], 'or_test');
      expect(value['returnURL'], 'merchant-app://inttegro-return');
    });

    test('serializes a customer-selected amount Purchase Intent', () {
      final value = const PaymentSheetConfiguration(
        purchaseIntentId: '  sale_test  ',
      ).toJson();

      expect(value, {'purchaseIntentId': 'sale_test'});
    });

    test('requires exactly one checkout reference', () {
      expect(
        () => const PaymentSheetConfiguration().toJson(),
        throwsArgumentError,
      );
      expect(
        () => const PaymentSheetConfiguration(
          orderId: 'or_test',
          purchaseIntentId: 'sale_test',
        ).toJson(),
        throwsArgumentError,
      );
    });

    test('rejects invalid appearance values', () {
      expect(
        () => const PaymentSheetConfiguration(
          orderId: 'or_test',
          appearance: PaymentSheetAppearance(primaryColor: '#xyz'),
        ).toJson(),
        throwsArgumentError,
      );
    });

    test('validates W3C trace context', () {
      const traceparent =
          '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';
      final value = const PaymentSheetConfiguration(
        orderId: 'or_test',
        telemetry: PaymentSheetTelemetry(traceparent: traceparent),
      ).toJson();

      expect(
        (value['telemetry']! as Map<String, Object>)['traceparent'],
        traceparent,
      );
      expect(
        () => const PaymentSheetConfiguration(
          orderId: 'or_test',
          telemetry: PaymentSheetTelemetry(
            traceparent:
                '00-00000000000000000000000000000000-00f067aa0ba902b7-01',
          ),
        ).toJson(),
        throwsArgumentError,
      );
    });

    test('serializes only payment-sheet feature overrides', () {
      final value = const PaymentSheetConfiguration(
        orderId: 'or_test',
        features: PaymentSheetFeatures(
          showLineItems: true,
          showReceiptDownload: true,
          allowPaymentMethodChange: false,
        ),
      ).toJson();

      expect(value['features'], {
        'showLineItems': true,
        'showReceiptDownload': true,
        'allowPaymentMethodChange': false,
      });
    });
  });

  test('decodes the shared result union', () {
    final result = PaymentSheetResult.fromJson({
      'status': 'failed',
      'error': {
        'code': 'declined',
        'message': 'Payment declined',
        'requestId': 'req_test',
        'retryAfterSeconds': 30,
      },
    });

    expect(result, isA<PaymentSheetFailed>());
    expect((result as PaymentSheetFailed).code, 'declined');
    expect(result.requestId, 'req_test');
    expect(result.retryAfterSeconds, 30);
  });

  test('decodes privacy-safe telemetry events', () {
    final event = PaymentSheetTelemetryEvent.fromJson({
      'flowId': '550e8400-e29b-41d4-a716-446655440000',
      'sequence': 1,
      'name': 'inttegro.checkout.load.started',
      'timestamp': '2026-09-04T12:00:00.000Z',
      'retryAfterSeconds': 30,
    });

    expect(event.sequence, 1);
    expect(
      event.name,
      PaymentSheetTelemetryEventName.checkoutLoadStarted,
    );
    expect(event.retryAfterSeconds, 30);
    final lifecycleEvent = PaymentSheetEvent(
      flowId: '550e8400-e29b-41d4-a716-446655440000',
      sequence: 1,
      type: PaymentSheetEventType.checkoutLoadStarted,
      timestamp: DateTime.utc(2026, 9, 4, 12),
    );
    expect(lifecycleEvent.type, PaymentSheetEventType.checkoutLoadStarted);
    expect(lifecycleEvent.isRecoverableFailure, isFalse);
    expect(
      () => PaymentSheetTelemetryEvent.fromJson({
        'flowId': '550e8400-e29b-41d4-a716-446655440000',
        'sequence': 1,
        'name': 'inttegro.checkout.load.started',
        'timestamp': '2026-09-04T12:00:00.000Z',
        'orderId': 'or_private',
      }),
      throwsFormatException,
    );

    final diagnostic = PaymentSheetTelemetryEvent.fromJson({
      'flowId': '550e8400-e29b-41d4-a716-446655440000',
      'sequence': 2,
      'name': 'inttegro.request.prepared',
      'timestamp': '2026-09-04T12:00:00.000Z',
      'operation': 'checkout.lookup',
    });
    expect(diagnostic.operation, PaymentSheetTelemetryOperation.checkoutLookup);
    expect(diagnostic.name, PaymentSheetTelemetryEventName.requestPrepared);
  });
}
