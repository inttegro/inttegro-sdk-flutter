# Payment lifecycle

Use lifecycle events for host coordination, terminal results for presentation
behavior, and the backend Order for fulfillment authority.

## Subscribe before presentation

```dart
import 'package:inttegro_flutter/events.dart';

final subscription = Inttegro.instance.paymentSheetEvents.listen((event) {
  switch (event.type) {
    case PaymentSheetEventType.presented:
      checkoutAnalytics.started();
    case PaymentSheetEventType.paymentAttemptFailed:
      checkoutAnalytics.retryAvailable(
        orderId: event.order!.id,
        category: event.failure!.code,
      );
    case PaymentSheetEventType.paymentActionRequired:
      showReturnToPaymentHint();
    default:
      break;
  }
});

try {
  await Inttegro.instance.presentPaymentSheet();
} finally {
  await subscription.cancel();
}
```

Subscribe before presentation so the first event is not missed. Sequence values
increase within a flow and allow deterministic ordering even if the host batches
analytics work.

## Separate recoverable and terminal state

Payment-attempt failures can be recoverable. The native sheet displays safe
guidance and gives the payer another attempt without resolving
`presentPaymentSheet`.

Confirmation-code entry, provider redirects, device authorization, and Checkout
status polling are also native intermediate states. Terminal results are limited
to completion, cancellation, and an unrecoverable SDK failure. After Checkout
has prepared an Order, each event carries the same client-safe Order shape used
by the web SDK. Request correlation and retry timing remain telemetry-only.

## Reconcile on the backend

Send the Order ID to the merchant backend after client completion. Retrieve the
owner-scoped Order with server credentials, verify the expected amount and
successful payment state, and make fulfillment idempotent. Webhooks may update
the same backend state for delayed methods; Flutter should render that
server-owned result instead of resolving competing client and webhook timelines.
