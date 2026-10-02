# Inttegro Flutter

[API reference](https://flutter.inttegro.dev/v0.3.0/) ·
[Studio guide](https://studio.inttegro.com/sdks/flutter)

Preview a native GHS checkout and Ghana Mobile Money payment sheet through
Inttegro's typed Flutter facade. This is an implementation spike and is not
ready to publish or use with live payments.
The current collection surface supports mobile money; card, Apple Pay, and
Google Pay are not exposed.

```dart
// Your backend must create and finalize the Order before this handoff.
final checkout = await merchantBackend.createCheckoutOrder(cart);
final orderId = checkout.orderId;

final lifecycleSubscription = Inttegro.instance.paymentSheetEvents.listen(
  (event) {
    switch (event.type) {
      case PaymentSheetEventType.presented:
        onPaymentFlowStarted();
      case PaymentSheetEventType.paymentAttemptStarted:
        onPaymentAttemptStarted();
      case PaymentSheetEventType.paymentAttemptFailed:
        // Recoverable: the customer can retry without leaving the native sheet.
        onPaymentAttemptFailed(category: event.errorType);
      default:
        break;
    }
  },
);

await Inttegro.instance.initializePaymentSheet(
  PaymentSheetConfiguration(
    orderId: orderId,
    returnUrl: Uri.parse('merchant-app://inttegro-return'),
    telemetry: activeTraceContext, // Optional traceparent and tracestate.
    features: const PaymentSheetFeatures(
      showLineItems: true,
      showInvoiceDownload: true,
      showReceiptDownload: true,
      allowPaymentMethodChange: false,
    ),
  ),
);

try {
  final result = await Inttegro.instance.presentPaymentSheet();

  switch (result) {
    case PaymentSheetCompleted(:final paymentId):
      onPaymentCompleted(paymentId: paymentId);
      await merchantBackend.verifyOrderPayment(orderId);
    case PaymentSheetCanceled():
      onPaymentCanceled();
    case PaymentSheetFailed(:final code, :final message, :final declineCode):
      onPaymentSheetFailed(
        code: code,
        message: message,
        declineCode: declineCode,
      );
  }
} finally {
  await lifecycleSubscription.cancel();
}
```

All feature flags are optional. Line items and post-payment downloads are off
by default; changing an attached payment method remains allowed by default.
Invoice and receipt actions appear only when Checkout returns the corresponding
document link after payment succeeds. Disabling payment-method changes does not
block collection when the Order has no attached method.

Finalizing an Order seals its amount and activates checkout; it does not mean
the payment has completed. Treat `PaymentSheetCompleted` as immediate client UI
state. Verify the owner-scoped Order from your backend before fulfillment.

The method channel maps directly to the shared native iOS and Android payment
artifacts. Those native implementations own presentation, accessibility,
authentication, payment collection, and lifecycle state; Dart only validates
the public input and decodes the result.

`paymentSheetEvents` provides typed application-facing lifecycle events. A
failed attempt is recoverable and does not resolve the presentation; the
terminal `PaymentSheetResult` drives completion, cancellation, and sheet-failure
behavior.

Use `paymentSheetTelemetryEvents` separately for ordered Checkout network
diagnostics. Inttegro does not install or own an exporter: the host decides
whether to translate them into spans, logs, or other signals. Events contain
bounded status and correlation metadata, never Order or Payment IDs, customer
or payer data, payment-method details, request or response bodies, redirect
URLs, or raw error messages. `flowId` and `requestId` should not be used as
metric labels. Subscribe before presenting the sheet so the first event is not
missed.

The package registers an Android and iOS plugin for each Flutter engine. The
plugins keep presentation state isolated per engine and delegate to the same
native `Inttegro` artifacts used by the React Native SDK. CocoaPods links the
iOS artifact through `inttegro_flutter.podspec`, while Gradle resolves
`com.inttegro:inttegro-android:0.2.0`.

## Requirements

- Flutter 3.44 or later and Dart 3.12 or later
- iOS 16 or later
- Android API 26 or later

Add the package, fetch dependencies, and rebuild the application so Flutter can
register the native plugin. Hot reload alone cannot add a newly installed
native plugin to a running application.
