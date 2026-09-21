# Scheduled Logger (Automation Task)

## Description
A scheduled inventory-sync task that calls an upstream inventory service, retries with
backoff, and logs each step with structured fields (`level`, `upstream`, `attempt`,
`error`).

By default the upstream URL points at `http://inventory-service.internal:8080`, a host that
does not resolve, so **every run fails the same way**: two `WARN` retries followed by an
`ERROR` and a non-zero exit. This gives observability and RCA tooling a realistic,
diagnosable failure: the root cause (`Could not resolve host:inventory-service.internal`) is
present in the logs of every failed execution.

## Configuration

| Configurable | Default | Purpose |
|---|---|---|
| `inventoryServiceUrl` | `http://inventory-service.internal:8080` | Upstream base URL. Set a reachable URL to make runs succeed. |
| `warehouseId` | `colombo-01` | Warehouse queried at `/api/v1/stock`. |
| `maxRetries` | `3` | Attempts before the run fails. |
| `requestTimeoutSeconds` | `5` | Per-request timeout. |

## Usage Instructions

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Automation** and give it a schedule.
2. Each run logs `Inventory sync run started`, then fails after 3 attempts with
   `Inventory sync failed: upstream inventory service unreachable after retries`.

## References

- [Schedule Your First Automation](https://wso2.com/devant/docs/quick-start-guides/schedule-your-first-automation)
