import 'package:flutter/services.dart';

import 'payment_sheet_models.dart';

/// Entry point for configuring, presenting, and observing the native sheet.
///
/// The facade is process-wide because Flutter registers one platform channel per
/// engine. Native iOS and Android code owns Checkout retrieval, collection UI,
/// validation, confirmation, authorization, and terminal state.
///
/// Initialize immediately before presentation and subscribe to lifecycle or
/// telemetry streams before opening the sheet so the first event is not missed.
final class Inttegro {
  Inttegro._();

  /// The process-wide Flutter facade for the registered Inttegro plugin.
  static final Inttegro instance = Inttegro._();

  static const MethodChannel _channel = MethodChannel('com.inttegro/sdk');
  static const EventChannel _eventChannel = EventChannel('com.inttegro/sdk/events');
  static const EventChannel _telemetryChannel =
      EventChannel('com.inttegro/sdk/telemetry');

  /// Privacy-safe transport diagnostics for a host-owned telemetry pipeline.
  ///
  /// Events exclude Order and Payment IDs, customer and payer fields,
  /// payment-method details, addresses, bodies, redirect URLs, and raw error
  /// messages. They are not authoritative payment state.
  late final Stream<PaymentSheetTelemetryEvent> paymentSheetTelemetryEvents =
      _telemetryChannel.receiveBroadcastStream().map((value) {
        if (value is! Map) {
          throw const FormatException(
            'Native payment sheet returned an invalid telemetry event',
          );
        }
        return PaymentSheetTelemetryEvent.fromJson(
          Map<Object?, Object?>.from(value),
        );
      }).asBroadcastStream();

  /// Typed application-facing lifecycle events for the active payment sheet.
  ///
  /// Subscribe before presenting the sheet so the first event is not missed. A
  /// failed attempt is recoverable and does not complete
  /// [presentPaymentSheet].
  late final Stream<PaymentSheetEvent> paymentSheetEvents =
      _eventChannel.receiveBroadcastStream().map((value) {
        if (value is! Map) {
          throw const FormatException(
            'Native payment sheet returned an invalid lifecycle event',
          );
        }
        return PaymentSheetEvent.fromJson(Map<Object?, Object?>.from(value));
      }).asBroadcastStream();

  /// Validates and stores [configuration] for the next presentation.
  ///
  /// This method does not perform the Checkout network request. Call it again
  /// whenever the Order ID or presentation options change. Never include a
  /// merchant API key in a Flutter application.
  ///
  /// Throws [ArgumentError] for malformed client-owned configuration and
  /// [PlatformException] when the native SDK rejects initialization.
  Future<void> initializePaymentSheet(
    PaymentSheetConfiguration configuration,
  ) async {
    await _channel.invokeMethod<void>(
      'initializePaymentSheet',
      configuration.toJson(),
    );
  }

  /// Opens the native payment sheet and returns its terminal result.
  ///
  /// Recoverable payment-attempt failures are handled inside the sheet and do
  /// not complete this future. A completed result describes the client
  /// experience; retrieve the owner-scoped Order from the merchant backend
  /// before fulfillment.
  ///
  /// Throws [PlatformException] when the native plugin is unavailable or the
  /// sheet was not initialized.
  Future<PaymentSheetResult> presentPaymentSheet() async {
    final value = await _channel.invokeMapMethod<Object?, Object?>(
      'presentPaymentSheet',
    );
    if (value == null) {
      throw const FormatException('Native payment sheet returned no result');
    }
    return PaymentSheetResult.fromJson(value);
  }
}
