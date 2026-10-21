# Order Pricing Service (Integration as API)

## Description
A REST API that prices a basket of line items and adds VAT:
`POST /pricing/quote` returns the subtotal, VAT and total.

The VAT rate defaults to `1800`, a value copied from a finance system that stores rates in
basis points (1800 = 18%). The service validates its configuration at startup and refuses
a rate above 100%, so **every pod exits before it serves a request**: one `ERROR` line,
`Startup aborted: VAT rate is outside the 0-100% range`, then a non-zero exit, and the
deployment goes into `CrashLoopBackOff`. This gives observability and RCA tooling a
realistic, diagnosable startup failure caused by configuration rather than code.

## Configuration

| Configurable | Default | Purpose |
|---|---|---|
| `vatRatePercent` | `1800` | VAT rate as a percentage. Set `18` to make the service start. |
| `currency` | `LKR` | Currency reported in each quote. |

## Usage Instructions

1. Run the integration locally using the **Run** button in Ballerina Integrator. It exits
   with `invalid configuration: vatRatePercent 1800 is outside 0-100`.
2. With `vatRatePercent = 18`, send a quote request:

   ```bash
   curl -X POST localhost:9090/pricing/quote -H 'Content-Type: application/json' \
     -d '{"items":[{"sku":"A1","quantity":2,"unitPrice":1000}]}'
   ```

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Integration as API**.
2. The deployment never becomes ready; its runtime logs show the startup error on every
   restart.
