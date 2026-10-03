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
      if (primaryColor case final value?) 'primaryColor': value,
      if (backgroundColor case final value?) 'backgroundColor': value,
      if (textColor case final value?) 'textColor': value,
      if (radius != null) 'cornerRadius': radius,
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
/// Inttegro installs no exporter. Disabling telemetry prevents both native
/// event emission and trace-header propagation for the presentation.
final class PaymentSheetTelemetry {
  /// Creates telemetry and distributed-tracing options.
  const PaymentSheetTelemetry({
    this.enabled = true,
    this.traceparent,
    this.tracestate,
  });

  /// Whether native events and trace propagation are enabled.
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
      if (parent != null) 'traceparent': parent,
      if (state != null) 'tracestate': state,
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

/// Application-facing payment-sheet lifecycle transitions.
enum PaymentSheetEventType {
  /// The native sheet became visible.
  presented,
  /// Checkout retrieval began.
  checkoutLoadStarted,
  /// Checkout retrieval succeeded.
  checkoutLoadSucceeded,
  /// Checkout retrieval failed and may be retried.
  checkoutLoadFailed,
  /// A payment attempt began.
  paymentAttemptStarted,
  /// A recoverable payment attempt failed.
  paymentAttemptFailed,
  /// The payer must enter a confirmation code.
  confirmationRequired,
  /// Provider or device authorization is outstanding.
  authorizationRequired,
  /// Checkout is being polled for authoritative state.
  paymentStatusPolling,
  /// The native flow reached its success state.
  completed,
  /// The payer dismissed the sheet.
  canceled,
  /// A terminal SDK failure stopped the flow.
  failed,
}

/// An application-facing stage in one payment-sheet presentation.
///
/// Recoverable failures leave the native sheet open so the customer can retry.
/// Terminal application behavior belongs in the [PaymentSheetResult] returned
/// by `presentPaymentSheet`.
final class PaymentSheetEvent {
  /// Creates one application-facing lifecycle event.
  const PaymentSheetEvent({
    required this.flowId,
    required this.sequence,
    required this.type,
    required this.timestamp,
    this.errorType,
  });

  /// Random identifier shared by events from one presentation.
  final String flowId;
  /// Monotonically increasing event order within the flow.
  final int sequence;
  /// Application-facing lifecycle transition.
  final PaymentSheetEventType type;
  /// Time at which the native SDK emitted the event.
  final DateTime timestamp;
  /// Privacy-safe failure category when the transition represents a failure.
  final String? errorType;

  /// Whether this event represents the end of the sheet presentation.
  bool get isTerminal => switch (type) {
    PaymentSheetEventType.completed ||
    PaymentSheetEventType.canceled ||
    PaymentSheetEventType.failed =>
      true,
    _ => false,
  };

  /// Whether the sheet remains open and permits the customer to retry.
  bool get isRecoverableFailure => switch (type) {
    PaymentSheetEventType.checkoutLoadFailed ||
    PaymentSheetEventType.paymentAttemptFailed =>
      true,
    _ => false,
  };
}

/// Terminal outcome of one native payment-sheet presentation.
///
/// Recoverable collection failures do not create a result; the native sheet
/// remains open. A completed result still requires backend verification of the
/// owner-scoped Order before fulfillment.
sealed class PaymentSheetResult {
  /// Creates a terminal result subtype returned by the native bridge.
  const PaymentSheetResult();

  /// Decodes the strict terminal payload returned by the native bridge.
  ///
  /// Throws [FormatException] for unknown states or malformed result fields.
  factory PaymentSheetResult.fromJson(Map<Object?, Object?> value) {
    switch (value['status']) {
      case 'completed':
        final paymentId = value['paymentId'];
        if (paymentId != null && paymentId is! String) {
          throw const FormatException('Invalid paymentId from native payment sheet');
        }
        return PaymentSheetCompleted(paymentId: paymentId as String?);
      case 'canceled':
        return const PaymentSheetCanceled();
      case 'failed':
        final error = value['error'];
        if (error is! Map) {
          throw const FormatException('Invalid error from native payment sheet');
        }
        final code = error['code'];
        final message = error['message'];
        final declineCode = error['declineCode'];
        final requestId = error['requestId'];
        final retryAfterSeconds = error['retryAfterSeconds'];
        if (code is! String ||
            message is! String ||
            (declineCode != null && declineCode is! String) ||
            (requestId != null &&
                (requestId is! String ||
                    requestId.isEmpty ||
                    requestId.length > 255)) ||
            (retryAfterSeconds != null &&
                (retryAfterSeconds is! int ||
                    retryAfterSeconds < 0 ||
                    retryAfterSeconds > 300))) {
          throw const FormatException('Invalid error from native payment sheet');
        }
        return PaymentSheetFailed(
          code: code,
          message: message,
          declineCode: declineCode as String?,
          requestId: requestId as String?,
          retryAfterSeconds: retryAfterSeconds as int?,
        );
      default:
        throw const FormatException('Unknown result from native payment sheet');
    }
  }
}

/// The payment sheet completed its client-side payment flow.
///
/// The merchant backend must still verify the authoritative Order state before
/// fulfillment.
final class PaymentSheetCompleted extends PaymentSheetResult {
  /// Creates a completed client result.
  const PaymentSheetCompleted({this.paymentId});

  /// Payment identifier returned by Checkout, when available.
  final String? paymentId;
}

/// The customer dismissed the payment sheet before completion.
final class PaymentSheetCanceled extends PaymentSheetResult {
  /// Creates the customer-canceled result.
  const PaymentSheetCanceled();
}

/// The payment sheet stopped because of a terminal error.
final class PaymentSheetFailed extends PaymentSheetResult {
  /// Creates a terminal failure returned by the native bridge.
  const PaymentSheetFailed({
    required this.code,
    required this.message,
    this.declineCode,
    this.requestId,
    this.retryAfterSeconds,
  });

  /// Stable machine-readable category suitable for application branching.
  final String code;
  /// Payer-safe or developer-facing description.
  final String message;
  /// Optional processor decline classification.
  final String? declineCode;
  /// Inttegro request identifier for support correlation.
  final String? requestId;
  /// Server-directed delay before retrying the operation.
  final int? retryAfterSeconds;
}
