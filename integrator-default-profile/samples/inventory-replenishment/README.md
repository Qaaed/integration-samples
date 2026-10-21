# Inventory Replenishment (Automation Task)

## Description
A scheduled task that reads a nightly warehouse stock snapshot and raises a reorder for
every SKU whose stock will not cover the supplier lead time plus a safety stock, based on
average daily sales.

`SKU-7781` was listed today, so it has no sales history (`daysOnSale = 0`), and the reorder
calculation divides by `daysOnSale` without guarding for new listings. **Every run fails
the same way**: an `INFO` start line, `Reorder raised` for `SKU-1042`, `SKU-2210` and
`SKU-3307`, then an unhandled panic, `{ballerina}DivisionByZero`, with a stack trace
pointing at `reorderQuantity (automation.bal:46)`, and a non-zero exit. `SKU-8150` is never
processed. It makes no network calls, so each run fails within a second. This gives
observability and RCA tooling a realistic, diagnosable code bug: unlike a logged error, the
cause must be traced from the panic and the stack trace to the SKU being processed, and the
run leaves partial work behind.

## Configuration

| Configurable | Default | Purpose |
|---|---|---|
| `safetyStockDays` | `3` | Days of sales kept in stock on top of the lead time. |

To make the runs succeed, return `0` from `reorderQuantity` when `daysOnSale` is `0`.

## Usage Instructions

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Automation** and give it a schedule.
2. Each run logs `Inventory replenishment run started` and three `Reorder raised` lines,
   then fails with `error: {ballerina}DivisionByZero {"message":" / by zero"}`.

## References

- [Schedule Your First Automation](https://wso2.com/devant/docs/quick-start-guides/schedule-your-first-automation)
