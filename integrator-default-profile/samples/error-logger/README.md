# Error Logger (Automation Task)

## Description
A scheduled task that totals a fixed batch of orders and logs each step.

One order, `ORD-1003`, has the amount `1O0.00` (a letter O where a zero belongs), so
**every run fails the same way**: an `INFO` start line, then an `ERROR` naming the order
and the bad amount, and a non-zero exit. It needs no configuration and makes no network
calls, so each run fails within a second. This gives observability and RCA tooling a
realistic, diagnosable failure whose fix is a one-character code change.

## Usage Instructions

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Automation** and give it a schedule.
2. Each run logs `Order batch run started`, then fails with
   `Order batch failed: order amount is not a number` for `ORD-1003`.

## References

- [Schedule Your First Automation](https://wso2.com/devant/docs/quick-start-guides/schedule-your-first-automation)
