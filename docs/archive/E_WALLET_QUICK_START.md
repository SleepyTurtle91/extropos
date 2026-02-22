# E-Wallet (DuitNow) Quick Start

## What’s included

- E-Wallet payment method in Payment screen

- QR payment flow with on-screen QR

- Pending transaction recorded to local DB (e_wallet_transactions)

- Manual Mark-as-Paid button + 15s auto-simulate (demo)

- Final sale saved via existing card-like flow

## How to use

1. In POS, tap Checkout to open the Payment screen.
2. Select "E-Wallet" as the Payment Method.
3. Press Process Payment.
4. A QR screen appears; let the customer scan and pay.
5. Tap "Mark as Paid" (or wait 15s demo auto-complete).
6. Sale completes, receipt generated, and (if enabled) MyInvois submits.

## Notes

- QR payload uses placeholder "DNQR|MID=...|AMT=...|REF=..." for demo.

- Database tables used: e_wallet_transactions, e_wallet_settings (future).

- PaymentService stores the final sale with PaymentMethod(id: 'ewallet').

## Next steps (optional)

- Add real provider integration via DuitNow QR or aggregator.

- Add E-Wallet Settings screen for merchant IDs per provider.

- Replace auto-simulate with status polling/webhook.
