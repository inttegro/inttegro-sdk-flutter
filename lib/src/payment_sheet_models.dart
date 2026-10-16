/// Restrained visual overrides applied to the native payment sheet.
///
/// Omit values to inherit platform and application defaults. Inttegro retains
/// native controls, layout, accessibility behavior, and payment-state semantics.
final class PaymentSheetAppearance {
  /// Creates optional native appearance overrides.
  const PaymentSheetAppearance({
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.cornerRadius,
  });

  /// Primary action color as `#RRGGBB` or `#RRGGBBAA`.
  final String? primaryColor;
  /// Sheet surface color as `#RRGGBB` or `#RRGGBBAA`.
  final String? backgroundColor;
  /// Primary foreground color as `#RRGGBB` or `#RRGGBBAA`.
  final String? textColor;
  /// Preferred sheet corner radius from 0 through 40 logical pixels.
  final double? cornerRadius;

  /// Validates and serializes appearance for the native bridge.
  Map<String, Object> toJson() {
    _validateColor('primaryColor', primaryColor);
    _validateColor('backgroundColor', backgroundColor);
    _validateColor('textColor', textColor);
    final radius = cornerRadius;
    if (radius != null && (!radius.isFinite || radius < 0 || radius > 40)) {
      throw ArgumentError.value(
        radius,
        'cornerRadius',
        'must be between 0 and 40',
      );
    }

    return {
      'primaryColor': ?primaryColor,
      'backgroundColor': ?backgroundColor,
      'textColor': ?textColor,
      'cornerRadius': ?radius,
    };
  }

  static void _validateColor(String name, String? value) {
    if (value != null &&
        !RegExp(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(value)) {
      throw ArgumentError.value(value, name, 'must be a 6 or 8 digit hex color');
    }
  }
}

/// Host-owned diagnostics and optional W3C trace context.
///
/// Inttegro installs no exporter. Disabling telemetry prevents diagnostic event
/// emission and trace-header propagation, but not Checkout lifecycle delivery.
final class PaymentSheetTelemetry {
  /// Creates telemetry and distributed-tracing options.
  const PaymentSheetTelemetry({
    this.enabled = true,
    this.traceparent,
    this.tracestate,
  });

  /// Whether diagnostic events and trace propagation are enabled.
  final bool enabled;
  /// Valid W3C `traceparent` supplied by the host application.
  final String? traceparent;
  /// Optional W3C `tracestate`, limited to 512 characters and no newlines.
  final String? tracestate;

  /// Validates and serializes telemetry options for the native bridge.
  Map<String, Object> toJson() {
    final parent = traceparent;
    if (parent != null &&
        !RegExp(
          r'^(?!ff)[0-9a-f]{2}-(?!0{32})[0-9a-f]{32}-(?!0{16})[0-9a-f]{16}-[0-9a-f]{2}$',
        )
            .hasMatch(parent)) {
      throw ArgumentError.value(
        parent,
        'traceparent',
        'must be a valid W3C trace parent',
      );
    }
    final state = tracestate;
    if (state != null &&
        (state.length > 512 || state.contains('\r') || state.contains('\n'))) {
      throw ArgumentError.value(
        state,
        'tracestate',
        'must be at most 512 characters without newlines',
      );
    }
    return {
      if (!enabled) 'enabled': false,
      'traceparent': ?parent,
      'tracestate': ?state,
    };
  }
}

/// Optional content and actions exposed by the native payment sheet.
///
/// These options affect presentation only. They cannot change the Order,
/// amount, currency, shipping address, or immutable customer relationship.
final class PaymentSheetFeatures {
  /// Creates optional content and post-payment actions.
  const PaymentSheetFeatures({
    this.showLineItems = false,
    this.showInvoiceDownload = false,
    this.showReceiptDownload = false,
    this.allowPaymentMethodChange = true,
  });

  /// Offers a collapsed, expandable Order summary. Opening it expands the
  /// native sheet before revealing Checkout-provided items. Defaults to `false`.
  final bool showLineItems;

  /// Offers the invoice after payment succeeds. Defaults to `false`.
  final bool showInvoiceDownload;

  /// Offers the receipt after payment succeeds. Defaults to `false`.
  final bool showReceiptDownload;

  /// Lets the payer replace an attached payment method. Defaults to `true`.
  final bool allowPaymentMethodChange;

  /// Serializes the presentation flags for the versioned native bridge.
  Map<String, Object> toJson() => {
        if (showLineItems) 'showLineItems': true,
        if (showInvoiceDownload) 'showInvoiceDownload': true,
        if (showReceiptDownload) 'showReceiptDownload': true,
        if (!allowPaymentMethodChange) 'allowPaymentMethodChange': false,
      };
}

/// Configuration stored for the next native payment-sheet presentation.
///
/// [orderId] is the public identifier returned by a merchant backend after it
/// creates and finalizes an Order. Never put a merchant API key in Flutter.
final class PaymentSheetConfiguration {
  /// Creates client-owned Checkout and presentation configuration.
  const PaymentSheetConfiguration({
    this.orderId,
    this.purchaseIntentId,
    this.returnUrl,
    this.appearance = const PaymentSheetAppearance(),
    this.telemetry = const PaymentSheetTelemetry(),
    this.features = const PaymentSheetFeatures(),
  });

  /// Public ID of an Order created and finalized by the backend.
  final String? orderId;
  /// Public Purchase Intent whose amount the payer will choose.
  final String? purchaseIntentId;
  /// Absolute application URI used after an external provider handoff.
  final Uri? returnUrl;
  /// Restrained native appearance overrides.
  final PaymentSheetAppearance appearance;
  /// Host-owned diagnostics and trace-context options.
  final PaymentSheetTelemetry telemetry;
  /// Optional content and post-payment actions.
  final PaymentSheetFeatures features;

  /// Validates and serializes configuration for the native bridge.
  ///
  /// Throws [ArgumentError] before presentation when a client-owned value is
  /// malformed. It does not retrieve Checkout or initiate payment.
  Map<String, Object> toJson() {
    final normalizedOrderId = orderId?.trim();
    final normalizedPurchaseIntentId = purchaseIntentId?.trim();
    if ((normalizedOrderId?.isNotEmpty == true) ==
        (normalizedPurchaseIntentId?.isNotEmpty == true)) {
      throw ArgumentError(
        'Provide exactly one of orderId or purchaseIntentId',
      );
    }
    if (returnUrl case final value? when !value.isAbsolute) {
      throw ArgumentError.value(value, 'returnUrl', 'must be an absolute URI');
    }

    final appearanceJson = appearance.toJson();
    final telemetryJson = telemetry.toJson();
    final featuresJson = features.toJson();
    return {
      if (normalizedOrderId?.isNotEmpty == true) 'orderId': normalizedOrderId!,
      if (normalizedPurchaseIntentId?.isNotEmpty == true)
        'purchaseIntentId': normalizedPurchaseIntentId!,
      if (returnUrl case final value?) 'returnURL': value.toString(),
      if (appearanceJson.isNotEmpty) 'appearance': appearanceJson,
      if (telemetryJson.isNotEmpty) 'telemetry': telemetryJson,
      if (featuresJson.isNotEmpty) 'features': featuresJson,
    };
  }
}

/// Stable wire names emitted by the native SDK diagnostic stream.
enum PaymentSheetTelemetryEventName {
  /// The native sheet became visible.
  sheetPresented('inttegro.payment_sheet.presented'),
  /// Checkout retrieval began.
  checkoutLoadStarted('inttegro.checkout.load.started'),
  /// Checkout retrieval produced a valid client-safe session.
  checkoutLoadSucceeded('inttegro.checkout.load.succeeded'),
  /// Checkout retrieval failed.
  checkoutLoadFailed('inttegro.checkout.load.failed'),
  /// A payment mutation began.
  paymentAttemptStarted('inttegro.payment.attempt.started'),
  /// A recoverable payment attempt failed.
  paymentAttemptFailed('inttegro.payment.attempt.failed'),
  /// Checkout requires a confirmation code.
  confirmationRequired('inttegro.payment.confirmation.required'),
  /// Checkout is waiting for provider or device authorization.
  authorizationRequired('inttegro.payment.authorization.required'),
  /// The SDK is polling Checkout for authoritative state.
  statusPolling('inttegro.payment.status.polling'),
  /// The sheet reached its Checkout-confirmed success state.
  sheetCompleted('inttegro.payment_sheet.completed'),
  /// The payer dismissed the sheet.
  sheetCanceled('inttegro.payment_sheet.canceled'),
  /// A terminal SDK failure closed the flow.
  sheetFailed('inttegro.payment_sheet.failed'),
  /// The native Checkout transport prepared a request.
  requestPrepared('inttegro.request.prepared'),
  /// An HTTP attempt began, including a safe retry.
  httpAttemptStarted('inttegro.http.attempt.started'),
  /// A Checkout response arrived.
  responseReceived('inttegro.response.received'),
  /// A Checkout response passed structural decoding.
  responseDecoded('inttegro.response.decoded'),
  /// A Checkout transport or decoding operation failed.
  requestFailed('inttegro.request.failed');

  const PaymentSheetTelemetryEventName(this.wireValue);

  /// The exact name emitted across the platform channel.
  final String wireValue;

  /// Resolves a native wire value, or returns `null` when it is unknown.
  static PaymentSheetTelemetryEventName? fromWireValue(String value) {
    for (final name in values) {
      if (name.wireValue == value) return name;
    }
    return null;
  }
}

/// Checkout operations that may appear in diagnostic events.
enum PaymentSheetTelemetryOperation {
  /// Retrieve the client-safe Checkout projection.
  checkoutLookup('checkout.lookup'),
  /// Finalize a customer-selected amount into an Order.
  checkoutSelectAmount('checkout.select_amount'),
  /// Start or retry payment.
  checkoutPay('checkout.pay'),
  /// Request a replacement confirmation code.
  checkoutRequestConfirmation('checkout.request_confirmation'),
  /// Submit a confirmation token.
  checkoutConfirmPayment('checkout.confirm_payment');

  const PaymentSheetTelemetryOperation(this.wireValue);

  /// The exact operation name emitted across the platform channel.
  final String wireValue;

  /// Resolves a native operation value, or returns `null` when unknown.
  static PaymentSheetTelemetryOperation? fromWireValue(String value) {
    for (final operation in values) {
      if (operation.wireValue == value) return operation;
    }
    return null;
  }
}

const _paymentSheetTelemetryEventFields = {
  'flowId',
  'sequence',
  'name',
  'timestamp',
  'operation',
  'httpStatusCode',
  'requestId',
  'retryAfterSeconds',
  'errorType',
};

/// Privacy-safe diagnostic metadata from one payment-sheet presentation.
///
/// Events exclude Order and Payment IDs, payer data, payment-method details,
/// addresses, bodies, redirect URLs, and raw error messages. Treat [flowId] and
/// [requestId] as correlation values rather than metric dimensions.
final class PaymentSheetTelemetryEvent {
  /// Creates a validated in-memory diagnostic event.
  const PaymentSheetTelemetryEvent({
    required this.flowId,
    required this.sequence,
    required this.name,
    required this.timestamp,
    this.operation,
    this.httpStatusCode,
    this.requestId,
    this.retryAfterSeconds,
    this.errorType,
  });

  /// Decodes the strict, versioned payload emitted by the native SDK.
  ///
  /// Throws [FormatException] for unknown names, unexpected fields, malformed
  /// identifiers, invalid status codes, or unbounded values.
  factory PaymentSheetTelemetryEvent.fromJson(Map<Object?, Object?> value) {
    final flowId = value['flowId'];
    final sequence = value['sequence'];
    final rawName = value['name'];
    final timestamp = value['timestamp'];
    final rawOperation = value['operation'];
    final httpStatusCode = value['httpStatusCode'];
    final requestId = value['requestId'];
    final retryAfterSeconds = value['retryAfterSeconds'];
    final errorType = value['errorType'];
    if (value.keys.any(
          (key) =>
              key is! String || !_paymentSheetTelemetryEventFields.contains(key),
        ) ||
        flowId is! String ||
        !RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        ).hasMatch(flowId) ||
        sequence is! int ||
        sequence < 1 ||
        rawName is! String ||
        timestamp is! String ||
        DateTime.tryParse(timestamp) == null ||
        (rawOperation != null && rawOperation is! String) ||
        (httpStatusCode != null &&
            (httpStatusCode is! int ||
                httpStatusCode < 100 ||
                httpStatusCode > 599)) ||
        (requestId != null &&
            (requestId is! String ||
                requestId.isEmpty ||
                requestId.length > 255)) ||
        (retryAfterSeconds != null &&
            (retryAfterSeconds is! int ||
                retryAfterSeconds < 0 ||
                retryAfterSeconds > 300)) ||
        (errorType != null &&
            (errorType is! String || errorType.isEmpty || errorType.length > 64))) {
      throw const FormatException(
        'Native payment sheet returned an invalid telemetry event',
      );
    }
    final name = PaymentSheetTelemetryEventName.fromWireValue(rawName);
    final operation = rawOperation == null
        ? null
        : PaymentSheetTelemetryOperation.fromWireValue(rawOperation as String);
    if (name == null || (rawOperation != null && operation == null)) {
      throw const FormatException(
        'Native payment sheet returned an unknown telemetry event',
      );
    }
    return PaymentSheetTelemetryEvent(
      flowId: flowId,
      sequence: sequence,
      name: name,
      timestamp: DateTime.parse(timestamp),
      operation: operation,
      httpStatusCode: httpStatusCode as int?,
      requestId: requestId as String?,
      retryAfterSeconds: retryAfterSeconds as int?,
      errorType: errorType as String?,
    );
  }

  /// Random identifier shared by events from one presentation.
  final String flowId;
  /// Monotonically increasing event order within the flow.
  final int sequence;
  /// Stable lifecycle or transport event name.
  final PaymentSheetTelemetryEventName name;
  /// Time at which the native SDK emitted the event.
  final DateTime timestamp;
  /// Fixed Checkout operation for a network event.
  final PaymentSheetTelemetryOperation? operation;
  /// HTTP status code when a response was received.
  final int? httpStatusCode;
  /// Bounded Inttegro request identifier for support correlation.
  final String? requestId;
  /// Bounded server-directed delay before retrying the operation.
  final int? retryAfterSeconds;
  /// Privacy-safe error category rather than a raw message.
  final String? errorType;
}

/// Money in an ISO 4217 currency's minor unit.
final class CheckoutMoney {
  /// Creates a client-safe Checkout amount.
  const CheckoutMoney({required this.value, required this.currency});

  /// Parses and validates a Checkout amount from the native bridge.
  factory CheckoutMoney.fromJson(Map<Object?, Object?> value) {
    _expectFields(value, const {'value', 'currency'});
    final amount = value['value'];
    final currency = value['currency'];
    if (amount is! int ||
        currency is! String ||
        !RegExp(r'^[A-Za-z]{3}$').hasMatch(currency)) {
      throw const FormatException('Invalid Checkout money');
    }
    return CheckoutMoney(value: amount, currency: currency);
  }

  /// Amount in the currency's minor unit.
  final int value;
  /// Three-letter ISO 4217 currency code.
  final String currency;
}

/// Order states exposed by the Checkout lifecycle.
enum CheckoutOrderStatus {
  /// The Order is ready for a payment method.
  requiresPayment('requires_payment'),
  /// The payment requires customer confirmation or authorization.
  requiresAction('requires_action'),
  /// Inttegro is processing the payment.
  processing('processing'),
  /// The payment completed successfully.
  paid('paid'),
  /// The payment failed.
  failed('failed'),
  /// The Order expired before payment completed.
  expired('expired'),
  /// The Order was canceled.
  canceled('canceled');

  /// Creates an Order status with its stable bridge value.
  const CheckoutOrderStatus(this.wireValue);

  /// Stable value transported across the native bridge.
  final String wireValue;

  /// Returns the status represented by [value], or `null` when unsupported.
  static CheckoutOrderStatus? fromWireValue(String value) {
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    return null;
  }
}

/// Merchant identity safe to display in Checkout.
final class CheckoutMerchant {
  /// Creates a display-safe merchant identity.
  const CheckoutMerchant({required this.displayName});

  /// Parses and validates a merchant identity from the native bridge.
  factory CheckoutMerchant.fromJson(Map<Object?, Object?> value) {
    _expectFields(value, const {'displayName'});
    final displayName = value['displayName'];
    if (displayName is! String || displayName.isEmpty) {
      throw const FormatException('Invalid Checkout merchant');
    }
    return CheckoutMerchant(displayName: displayName);
  }

  /// Merchant name suitable for customer-facing Checkout UI.
  final String displayName;
}

/// One client-safe line in the Checkout Order snapshot.
final class CheckoutLineItem {
  /// Creates one line in a client-safe Order snapshot.
  const CheckoutLineItem({
    required this.id,
    required this.name,
    required this.total,
    this.quantity,
  });

  /// Parses and validates a line item from the native bridge.
  factory CheckoutLineItem.fromJson(Map<Object?, Object?> value) {
    _expectFields(value, const {'id', 'name', 'quantity', 'total'});
    final id = value['id'];
    final name = value['name'];
    final quantity = value['quantity'];
    final total = value['total'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        (quantity != null && (quantity is! int || quantity < 0)) ||
        total is! Map) {
      throw const FormatException('Invalid Checkout line item');
    }
    return CheckoutLineItem(
      id: id,
      name: name,
      quantity: quantity as int?,
      total: CheckoutMoney.fromJson(Map<Object?, Object?>.from(total)),
    );
  }

  /// Public line-item identifier.
  final String id;

  /// Customer-facing line-item name.
  final String name;

  /// Item quantity when the Order supplies one.
  final int? quantity;

  /// Total amount for this line.
  final CheckoutMoney total;
}

/// Secure documents available for the Order.
final class CheckoutDocuments {
  /// Creates the set of secure Order document links.
  const CheckoutDocuments({this.invoiceUrl, this.receiptUrl});

  /// Parses and validates document links from the native bridge.
  factory CheckoutDocuments.fromJson(Map<Object?, Object?> value) {
    _expectFields(value, const {'invoiceUrl', 'receiptUrl'});
    final invoiceUrl = _optionalAbsoluteUri(value['invoiceUrl']);
    final receiptUrl = _optionalAbsoluteUri(value['receiptUrl']);
    return CheckoutDocuments(invoiceUrl: invoiceUrl, receiptUrl: receiptUrl);
  }

  /// Secure invoice download URL when available.
  final Uri? invoiceUrl;

  /// Secure receipt download URL when available.
  final Uri? receiptUrl;
}

/// Client-safe Order snapshot attached to Checkout lifecycle events.
final class CheckoutOrder {
  /// Creates a client-safe Order snapshot.
  const CheckoutOrder({
    required this.id,
    required this.status,
    required this.merchant,
    required this.amount,
    required this.lineItems,
    required this.documents,
    this.expiresAt,
  });

  /// Parses and validates an Order snapshot from the native bridge.
  factory CheckoutOrder.fromJson(Map<Object?, Object?> value) {
    _expectFields(
      value,
      const {
        'id',
        'status',
        'merchant',
        'amount',
        'expiresAt',
        'lineItems',
        'documents',
      },
    );
    final id = value['id'];
    final rawStatus = value['status'];
    final merchant = value['merchant'];
    final amount = value['amount'];
    final rawExpiresAt = value['expiresAt'];
    final lineItems = value['lineItems'];
    final documents = value['documents'];
    final status = rawStatus is String
        ? CheckoutOrderStatus.fromWireValue(rawStatus)
        : null;
    final expiresAt = rawExpiresAt == null
        ? null
        : rawExpiresAt is String
            ? DateTime.tryParse(rawExpiresAt)
            : null;
    if (id is! String ||
        id.isEmpty ||
        status == null ||
        merchant is! Map ||
        amount is! Map ||
        (rawExpiresAt != null && expiresAt == null) ||
        lineItems is! List ||
        documents is! Map ||
        lineItems.any((item) => item is! Map)) {
      throw const FormatException('Invalid Checkout Order');
    }
    return CheckoutOrder(
      id: id,
      status: status,
      merchant: CheckoutMerchant.fromJson(Map<Object?, Object?>.from(merchant)),
      amount: CheckoutMoney.fromJson(Map<Object?, Object?>.from(amount)),
      expiresAt: expiresAt,
      lineItems: lineItems
          .map(
            (item) => CheckoutLineItem.fromJson(
              Map<Object?, Object?>.from(item as Map),
            ),
          )
          .toList(growable: false),
      documents: CheckoutDocuments.fromJson(
        Map<Object?, Object?>.from(documents),
      ),
    );
  }

  /// Public Order identifier.
  final String id;

  /// Current Order state.
  final CheckoutOrderStatus status;

  /// Merchant identity safe to display to the customer.
  final CheckoutMerchant merchant;

  /// Total amount payable for the Order.
  final CheckoutMoney amount;

  /// Time after which the Order can no longer be paid.
  final DateTime? expiresAt;

  /// Client-safe summary of the Order contents.
  final List<CheckoutLineItem> lineItems;

  /// Secure invoice and receipt links available for the Order.
  final CheckoutDocuments documents;
}

/// Additional customer action required before Checkout can complete.
enum CheckoutActionType {
  /// The customer must confirm the payment.
  confirmation,
  /// The customer must authorize the payment.
  authorization,
  /// The customer must complete a redirect flow.
  redirect;

  /// Returns the action represented by [value], or `null` when unsupported.
  static CheckoutActionType? fromWireValue(String value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

/// Safe description of the next action required from the customer.
final class CheckoutAction {
  /// Creates a customer action required by Checkout.
  const CheckoutAction({required this.type, this.expiresAt});

  /// Parses and validates a required action from the native bridge.
  factory CheckoutAction.fromJson(Map<Object?, Object?> value) {
    _expectFields(value, const {'type', 'expiresAt'});
    final rawType = value['type'];
    final rawExpiresAt = value['expiresAt'];
    final type = rawType is String
        ? CheckoutActionType.fromWireValue(rawType)
        : null;
    final expiresAt = rawExpiresAt == null
        ? null
        : rawExpiresAt is String
            ? DateTime.tryParse(rawExpiresAt)
            : null;
    if (type == null || (rawExpiresAt != null && expiresAt == null)) {
      throw const FormatException('Invalid Checkout action');
    }
    return CheckoutAction(type: type, expiresAt: expiresAt);
  }

  /// Kind of action the customer must complete.
  final CheckoutActionType type;

  /// Time after which the action is no longer valid.
  final DateTime? expiresAt;
}

/// Sanitized reason a Checkout lifecycle operation failed.
final class CheckoutFailure {
  /// Creates a sanitized Checkout failure.
  const CheckoutFailure({
    required this.code,
    required this.message,
    required this.recoverable,
  });

  /// Parses and validates a safe failure from the native bridge.
  factory CheckoutFailure.fromJson(Map<Object?, Object?> value) {
    _expectFields(value, const {'code', 'message', 'recoverable'});
    final code = value['code'];
    final message = value['message'];
    final recoverable = value['recoverable'];
    if (code is! String ||
        code.isEmpty ||
        message is! String ||
        message.isEmpty ||
        recoverable is! bool) {
      throw const FormatException('Invalid Checkout failure');
    }
    return CheckoutFailure(
      code: code,
      message: message,
      recoverable: recoverable,
    );
  }

  /// Stable machine-readable failure code.
  final String code;

  /// Customer-safe description of the failure.
  final String message;

  /// Whether the customer can retry within the current presentation.
  final bool recoverable;
}

/// Application-facing payment-sheet lifecycle transitions.
enum PaymentSheetEventType {
  /// The native sheet became visible.
  presented('presented'),
  /// Checkout is ready for customer interaction.
  ready('ready'),
  /// Customer input changed the form completion state.
  change('change'),
  /// Checkout prepared the Order for payment.
  orderPrepared('orderPrepared'),
  /// A payment attempt began.
  paymentAttemptStarted('paymentAttemptStarted'),
  /// The payment requires customer action.
  paymentActionRequired('paymentActionRequired'),
  /// Inttegro is processing the payment.
  paymentProcessing('paymentProcessing'),
  /// A recoverable payment attempt failed.
  paymentAttemptFailed('paymentAttemptFailed'),
  /// Checkout completed successfully.
  completed('completed'),
  /// The customer canceled the presentation.
  canceled('canceled'),
  /// Checkout ended with a terminal failure.
  failed('failed');

  /// Creates an event type with its stable bridge value.
  const PaymentSheetEventType(this.wireValue);

  /// Stable value transported across the native bridge.
  final String wireValue;

  /// Returns the event type represented by [value], or `null` if unsupported.
  static PaymentSheetEventType? fromWireValue(String value) {
    for (final type in values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}

/// One ordered application-facing transition from a Checkout presentation.
final class PaymentSheetEvent {
  /// Creates one ordered Checkout lifecycle event.
  const PaymentSheetEvent({
    required this.flowId,
    required this.sequence,
    required this.type,
    required this.occurredAt,
    this.order,
    this.action,
    this.failure,
    this.complete,
    this.paymentMethod,
  });

  /// Parses and validates a lifecycle event from the native bridge.
  factory PaymentSheetEvent.fromJson(Map<Object?, Object?> value) {
    const baseFields = {'type', 'occurredAt', 'flowId', 'sequence'};
    final rawType = value['type'];
    final rawOccurredAt = value['occurredAt'];
    final flowId = value['flowId'];
    final sequence = value['sequence'];
    final type = rawType is String
        ? PaymentSheetEventType.fromWireValue(rawType)
        : null;
    final occurredAt = rawOccurredAt is String
        ? DateTime.tryParse(rawOccurredAt)
        : null;
    if (type == null ||
        occurredAt == null ||
        flowId is! String ||
        !_uuidPattern.hasMatch(flowId) ||
        sequence is! int ||
        sequence < 1) {
      throw const FormatException('Invalid payment sheet lifecycle event');
    }

    final extraFields = switch (type) {
      PaymentSheetEventType.presented || PaymentSheetEventType.ready =>
        const <String>{},
      PaymentSheetEventType.change => const {'complete', 'paymentMethod'},
      PaymentSheetEventType.orderPrepared ||
      PaymentSheetEventType.paymentAttemptStarted ||
      PaymentSheetEventType.paymentProcessing ||
      PaymentSheetEventType.completed =>
        const {'order'},
      PaymentSheetEventType.paymentActionRequired => const {'order', 'action'},
      PaymentSheetEventType.paymentAttemptFailed => const {'order', 'failure'},
      PaymentSheetEventType.canceled => const {'order'},
      PaymentSheetEventType.failed => const {'order', 'failure'},
    };
    _expectFields(value, {...baseFields, ...extraFields});

    final rawOrder = value['order'];
    final rawAction = value['action'];
    final rawFailure = value['failure'];
    final complete = value['complete'];
    final paymentMethod = value['paymentMethod'];
    final order = rawOrder is Map
        ? CheckoutOrder.fromJson(Map<Object?, Object?>.from(rawOrder))
        : null;
    final action = rawAction is Map
        ? CheckoutAction.fromJson(Map<Object?, Object?>.from(rawAction))
        : null;
    final failure = rawFailure is Map
        ? CheckoutFailure.fromJson(Map<Object?, Object?>.from(rawFailure))
        : null;

    final valid = switch (type) {
      PaymentSheetEventType.presented || PaymentSheetEventType.ready => true,
      PaymentSheetEventType.change =>
        complete is bool &&
            (paymentMethod == null || paymentMethod == 'mobile_money'),
      PaymentSheetEventType.orderPrepared ||
      PaymentSheetEventType.paymentAttemptStarted ||
      PaymentSheetEventType.paymentProcessing ||
      PaymentSheetEventType.completed =>
        order != null,
      PaymentSheetEventType.paymentActionRequired =>
        order != null && action != null,
      PaymentSheetEventType.paymentAttemptFailed =>
        order != null && failure != null,
      PaymentSheetEventType.canceled => rawOrder == null || order != null,
      PaymentSheetEventType.failed => failure != null,
    };
    if (!valid ||
        (rawOrder != null && order == null) ||
        (rawAction != null && action == null) ||
        (rawFailure != null && failure == null)) {
      throw const FormatException('Invalid payment sheet lifecycle event');
    }

    return PaymentSheetEvent(
      flowId: flowId,
      sequence: sequence,
      type: type,
      occurredAt: occurredAt,
      order: order,
      action: action,
      failure: failure,
      complete: complete as bool?,
      paymentMethod: paymentMethod as String?,
    );
  }

  /// Random identifier shared by events from one sheet presentation.
  final String flowId;

  /// Monotonically increasing event order within the flow.
  final int sequence;

  /// Lifecycle transition represented by this event.
  final PaymentSheetEventType type;

  /// Time at which the native SDK emitted the event.
  final DateTime occurredAt;

  /// Client-safe Order snapshot for Order-backed events.
  final CheckoutOrder? order;

  /// Customer action required by `paymentActionRequired`.
  final CheckoutAction? action;

  /// Sanitized failure attached to failure events.
  final CheckoutFailure? failure;

  /// Whether required payer input is complete for a `change` event.
  final bool? complete;

  /// Selected payment method for a `change` event, when known.
  final String? paymentMethod;

  /// Whether this event closes the current sheet presentation.
  bool get isTerminal => switch (type) {
    PaymentSheetEventType.completed ||
    PaymentSheetEventType.canceled ||
    PaymentSheetEventType.failed =>
      true,
    _ => false,
  };

  /// Whether this event describes a retryable payment attempt.
  bool get isRecoverableFailure =>
      type == PaymentSheetEventType.paymentAttemptFailed;
}

/// Terminal outcome of one native payment-sheet presentation.
sealed class PaymentSheetResult {
  /// Creates a terminal result around its exact lifecycle [event].
  const PaymentSheetResult(this.event);

  /// Parses a terminal lifecycle event returned by the native bridge.
  factory PaymentSheetResult.fromJson(Map<Object?, Object?> value) {
    final event = PaymentSheetEvent.fromJson(value);
    return switch (event.type) {
      PaymentSheetEventType.completed => PaymentSheetCompleted(event),
      PaymentSheetEventType.canceled => PaymentSheetCanceled(event),
      PaymentSheetEventType.failed => PaymentSheetFailed(event),
      _ => throw const FormatException(
          'Native payment sheet returned a non-terminal result',
        ),
    };
  }

  /// The exact terminal lifecycle event returned by the native bridge.
  final PaymentSheetEvent event;

  /// Presentation identifier shared with all lifecycle events in the flow.
  String get flowId => event.flowId;

  /// Final sequence number in the presentation flow.
  int get sequence => event.sequence;

  /// Time at which the terminal event occurred.
  DateTime get occurredAt => event.occurredAt;

  /// Final client-safe Order snapshot when one was prepared.
  CheckoutOrder? get order => event.order;
}

/// The payment sheet completed its client-side payment flow.
final class PaymentSheetCompleted extends PaymentSheetResult {
  /// Creates a successful terminal result.
  const PaymentSheetCompleted(super.event);

  @override
  /// Final paid Order snapshot.
  CheckoutOrder get order => event.order!;
}

/// The customer dismissed the payment sheet before completion.
final class PaymentSheetCanceled extends PaymentSheetResult {
  /// Creates a customer-canceled terminal result.
  const PaymentSheetCanceled(super.event);
}

/// The payment sheet stopped because of a terminal failure.
final class PaymentSheetFailed extends PaymentSheetResult {
  /// Creates a terminal failure result.
  const PaymentSheetFailed(super.event);

  /// Sanitized reason Checkout could not continue.
  CheckoutFailure get failure => event.failure!;
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

void _expectFields(Map<Object?, Object?> value, Set<String> allowed) {
  if (value.keys.any((key) => key is! String || !allowed.contains(key))) {
    throw const FormatException('Unexpected field in native payment sheet payload');
  }
}

Uri? _optionalAbsoluteUri(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Invalid Checkout document URL');
  }
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.isAbsolute) {
    throw const FormatException('Invalid Checkout document URL');
  }
  return uri;
}
