import 'package:flutter_test/flutter_test.dart';
import 'package:inttegro_flutter/events.dart' as events;
import 'package:inttegro_flutter/payment_sheet.dart' as payment_sheet;
import 'package:inttegro_flutter/telemetry.dart' as telemetry;

void main() {
  test('focused libraries expose their responsibility-based contracts', () {
    const configuration = payment_sheet.PaymentSheetConfiguration(
      orderId: 'order_public_123',
    );

    expect(configuration.orderId, 'order_public_123');
    expect(events.PaymentSheetEventType.values, isNotEmpty);
    expect(telemetry.PaymentSheetTelemetryEventName.values, isNotEmpty);
    expect(telemetry.PaymentSheetTelemetryOperation.values, isNotEmpty);
  });
}
