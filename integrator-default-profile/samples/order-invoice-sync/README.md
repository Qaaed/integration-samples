# Order Invoice Sync (Automation Task)

## Description
A scheduled task that creates an invoice in the accounting system for every order paid in
an online store. Each run reads the paid orders from the storefront's Admin API for the last
`lookbackHours`, maps each order to an invoice (one line per item, plus a shipping line when
shipping was charged, with sales tax set by the ship-to country) and creates it.

The project follows the usual layout: `config.bal` holds the configurables, `types.bal` the
storefront and accounting payloads, `functions.bal` the API calls and the order-to-invoice
mapping, and `automation.bal` the run itself.

## Failing on purpose (RCA testing)

The storefront's response includes order `#1043`, a digital gift card. It has nothing to
ship, so the storefront sends it with `shippingAddress: null`. **Every run fails the same
way:**
- two `INFO` lines: the run starting, and the four order numbers fetched;
- one `ERROR`, `Could not read the storefront's orders; no invoices were created`, whose
  `reason` names the failing field: `field '[2].shippingAddress' in record 'Order' should be
  of type 'Address', found '()'`;
- a non-zero exit.

No invoices are created for any order, not just `#1043`, so every paid order in the window
goes uninvoiced until the integration is fixed. The fix belongs in the integration's code:
the storefront's data is valid, and retrying or changing the configuration doesn't help.

The storefront's response is the one captured on 2026-11-05 and the invoice API call is
simulated, so the run needs no network access or credentials and fails within a second.

## Configuration

| Configurable | Default | Purpose |
|---|---|---|
| `storeName` | `Northwind Outfitters` | Store shown in the logs. |
| `storefrontApiUrl` | `https://northwind-outfitters.example/admin/api/2024-10` | Storefront Admin API the orders are read from. |
| `accountingApiUrl` | `https://books.northwind.example/api/v1` | Accounting API the invoices are created in. |
| `lookbackHours` | `24` | How far back each run looks for paid orders. |

## Usage Instructions

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Automation** and give it a schedule,
   or run it once with **Test**.
2. Each run logs `Order invoice sync started` and `Fetched paid orders from the storefront`
   (`orderNumbers="#1041, #1042, #1043, #1044"`), then fails with
   `Could not read the storefront's orders; no invoices were created`.
3. Once fixed, each run logs `Invoice created` for all four orders and
   `Order invoice sync completed` (`invoices=4`).

## References

- [Schedule Your First Automation](https://wso2.com/devant/docs/quick-start-guides/schedule-your-first-automation)
