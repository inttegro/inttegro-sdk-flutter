/// Configure and present Inttegro's native payment sheet from Flutter.
///
/// Pass only the public Checkout Order ID created by your backend. A completed
/// result describes the client experience; verify the authoritative Order from
/// your backend before fulfillment.
///
/// {@category get-started}
library;

export 'src/inttegro.dart' show Inttegro;
export 'src/payment_sheet_models.dart'
    show
        PaymentSheetAppearance,
        PaymentSheetCanceled,
        PaymentSheetCompleted,
        PaymentSheetConfiguration,
        PaymentSheetFailed,
        PaymentSheetFeatures,
        PaymentSheetResult;
