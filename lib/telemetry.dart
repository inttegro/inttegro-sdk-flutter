/// Privacy-safe diagnostics from Inttegro's native payment flow.
///
/// Inttegro does not install an exporter. The host application chooses whether
/// to translate this ordered stream into logs, traces, or another diagnostics
/// system it owns.
///
/// {@category observability}
library;

export 'src/inttegro.dart' show Inttegro;
export 'src/payment_sheet_models.dart'
    show
        PaymentSheetTelemetry,
        PaymentSheetTelemetryEvent,
        PaymentSheetTelemetryEventName,
        PaymentSheetTelemetryOperation;
