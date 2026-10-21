# Payment Reconciliation (Automation Task)

## Description
A scheduled task that reconciles a day's ledger against the payment gateway's settlement
file. It flags duplicate, unknown, mismatched and missing settlements, then checks that
the two totals agree.

The gateway settled `TXN-50013` twice (`SET-9004` and `SET-9007`), paying merchant
`MER-204` 249.99 too much, so **every run fails the same way**: an `INFO` start line, an
`ERROR` naming the duplicate settlement, an `ERROR` with the ledger total, settled total
and variance, and a non-zero exit. It makes no network calls, so each run fails within a
second. This gives observability and RCA tooling a realistic, diagnosable failure: the
logs carry the transaction, both settlement IDs and the amount at stake.

## Configuration

| Configurable | Default | Purpose |
|---|---|---|
| `toleranceAmount` | `0.01` | Largest total variance accepted as rounding. |

To make the runs succeed, remove the `SET-9007` settlement from `automation.bal`.

## Usage Instructions

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Automation** and give it a schedule.
2. Each run logs `Payment reconciliation run started`, then
   `Duplicate settlement: transaction was settled more than once` for `TXN-50013`, and
   fails with `Payment reconciliation failed: gateway settlements do not match the ledger`
   (`variance=249.99`).

## References

- [Schedule Your First Automation](https://wso2.com/devant/docs/quick-start-guides/schedule-your-first-automation)
