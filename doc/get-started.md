# Get started with Checkout

Create and finalize an Order on your backend, hand its public ID to Flutter, and
present Inttegro's native payment sheet.

## Choose an import

Use the focused payment library for new payment screens:

```dart
import 'package:inttegro_flutter/payment_sheet.dart';
```

The original umbrella library remains available for compatibility:

```dart
import 'package:inttegro_flutter/inttegro_flutter.dart';
```

Both imports call the same native iOS or Android implementation. The focused
libraries only improve ownership, navigation, and generated API documentation;
they do not create competing payment flows.

## Create configuration

The application supplies a public Order ID and client-owned presentation
options. Merchant identity, amount, currency, line items, saved methods, and
shipping details come from Checkout and cannot be replaced by Flutter values.

```dart
final configuration = PaymentSheetConfiguration(
  orderId: checkout.orderId,
  returnUrl: Uri.parse('merchant-app://inttegro-return'),
  appearance: const PaymentSheetAppearance(
    primaryColor: '#0C4A3E',
  ),
  features: const PaymentSheetFeatures(
    showLineItems: true,
    showInvoiceDownload: true,
    showReceiptDownload: true,
  ),
);

await Inttegro.instance.initializePaymentSheet(configuration);
```

Initialization validates the bridge payload without retrieving Checkout or
starting payment. Call it again when the Order ID or presentation options
change. Never place an Inttegro merchant API key in a Flutter application.

### Let the payer choose the amount

If your backend returns a Buy link whose price type is
`customer_selected_amount`, pass its public Purchase Intent ID instead:

```dart
await Inttegro.instance.initializePaymentSheet(
  PaymentSheetConfiguration(
    purchaseIntentId: buyLink.purchaseIntentId,
    returnUrl: Uri.parse('merchant-app://inttegro-return'),
  ),
);
```

Do not also provide `orderId`. The sheet first shows the authoritative currency,
minimum, optional maximum, and suggested amounts from Checkout. Once the payer
continues, Inttegro creates the Order idempotently and the ordinary
payment-method flow begins. Suggested amounts are shortcuts, not an allow-list.

Enabling `showLineItems` offers an Order summary without opening it for the
payer. If they choose to view the items, the native sheet expands to its
full-height detent as the summary is revealed.

## Present and interpret the result

```dart
final result = await Inttegro.instance.presentPaymentSheet();

switch (result) {
  case PaymentSheetCompleted():
    await merchantBackend.verifyAndFulfillOrder(checkout.orderId);
  case PaymentSheetCanceled():
    restoreCheckoutControls();
  case PaymentSheetFailed(:final code):
    recordTerminalFailure(code);
    showPaymentUnavailable();
}
```

Recoverable collection failures remain inside the native sheet and do not
complete the Future. Even a completed result is client experience state: the
merchant backend must retrieve the owner-scoped Order and verify successful
payment before fulfillment.

## Rebuild the application

This package contains native plugins. Run dependency resolution and rebuild the
iOS or Android application after installation. Hot reload cannot add a newly
installed native plugin to an already running process.
