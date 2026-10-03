/// Application-facing lifecycle events from Inttegro's native payment sheet.
///
/// Lifecycle events help a host coordinate product behavior while the sheet is
/// open. They are not authoritative payment state and must not trigger
/// fulfillment without a server-side Order check.
///
/// {@category lifecycle}
library;

export 'src/inttegro.dart' show Inttegro;
export 'src/payment_sheet_models.dart'
    show PaymentSheetEvent, PaymentSheetEventType;
