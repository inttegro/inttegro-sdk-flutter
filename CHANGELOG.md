# Changelog

## 0.5.0 - 2026-10-16

- Align the Flutter bridge with the canonical web and native Checkout
  lifecycle, including flow IDs and monotonic event sequences.
- Return the exact terminal lifecycle event from `presentPaymentSheet()` and
  include the client-safe Order snapshot when Checkout completes.
- Add payment-action, processing, recoverable-attempt-failure, cancellation,
  and terminal-failure events with sanitized payloads.
- Update the native iOS and Android dependency to 0.4.0.

## 0.4.0 - 2026-10-03

- Honor server-directed retry delays for transient Checkout mutations.
- Expose request IDs and retry delays in failure results and telemetry.
- Support customer-selected amounts for Purchase Intents and editable line items
  in mixed-price Orders.
- Update the native iOS and Android dependency to 0.3.0.

## 0.3.0 - 2026-09-10

- Add the initial Flutter facade for the native Inttegro payment sheet.
