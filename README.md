# Inttegro Flutter

[API reference](https://flutter.inttegro.dev/v0.5.1/) ·
[Studio guide](https://studio.inttegro.com/sdks/flutter)

Typed Flutter facade for Inttegro's native payment sheet. The current collection
surface supports mobile money; card, Apple Pay, and Google Pay are not exposed
in this version.

```dart
import 'package:inttegro_flutter/events.dart';
import 'package:inttegro_flutter/payment_sheet.dart';

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
        onPaymentAttemptFailed(
          order: event.order!,
          failure: event.failure!,
        );
      case PaymentSheetEventType.paymentActionRequired:
        onPaymentActionRequired(
          order: event.order!,
          action: event.action!,
        );
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
    case PaymentSheetCompleted(:final order):
      onPaymentCompleted(order: order);
      await merchantBackend.verifyOrderPayment(order.id);
    case PaymentSheetCanceled(:final order):
      onPaymentCanceled();
      if (order != null) preserveCheckoutContext(order.id);
    case PaymentSheetFailed(:final failure):
      onPaymentSheetFailed(
        code: failure.code,
        message: failure.message,
      );
  }
} finally {
  await lifecycleSubscription.cancel();
}
```

For a Buy link, initialize with the client-safe Purchase Intent instead of a
finalized Order:

```dart
await Inttegro.instance.initializePaymentSheet(
  PaymentSheetConfiguration(purchaseIntentId: buyLink.purchaseIntentId),
);
```

The native sheet retrieves the Buy-link choices and lets the payer choose the
product variant, quantity, customer details, and—when supported—amount. It
creates the finalized Order and starts payment together only when the payer
presses Pay. Supply
exactly one of `orderId` or `purchaseIntentId`.

The umbrella `inttegro_flutter.dart` library remains supported. Applications
that prefer responsibility-based API pages can use focused libraries:

```dart
import 'package:inttegro_flutter/payment_sheet.dart';
import 'package:inttegro_flutter/events.dart';
import 'package:inttegro_flutter/telemetry.dart';
```

These are libraries in one pub package, not separate native implementations.
They stay on one version and delegate to the same iOS or Android state machine.

All feature flags are optional. Line items and post-payment downloads are off
by default; changing an attached payment method remains allowed by default.
When line items are enabled, the Order summary still starts collapsed. Opening
it expands the native sheet as the items are revealed.
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

The native transport retries an idempotent Checkout mutation once when the
server supplies a valid `Retry-After` delay. Transport-only request identifiers
and retry timing remain in `paymentSheetTelemetryEvents`; public lifecycle
failures carry only a stable code, safe message, and recoverability flag.

The package registers an Android and iOS plugin for each Flutter engine. The
plugins keep presentation state isolated per engine and delegate to the same
native `Inttegro` artifacts used by the React Native SDK. CocoaPods links the
iOS artifact through `inttegro_flutter.podspec`, while Gradle resolves
`com.inttegro:inttegro-android:0.4.2`.

## Requirements

- Flutter 3.44 or later and Dart 3.12 or later
- iOS 16 or later
- Android API 26 or later

Add the package, fetch dependencies, and rebuild the application so Flutter can
register the native plugin. Hot reload alone cannot add a newly installed
native plugin to a running application.
