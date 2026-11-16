# Carrier Rate Sync (Automation Task)

## Description
A scheduled task that refreshes shipping rates from a parcel carrier for a set of lanes.

The carrier's rating platform is offline for planned maintenance, so **every run fails the
same way**: two `INFO` lines (start, successful authentication), one `ERROR` per attempt
with HTTP `503 Service Unavailable` and the carrier's maintenance message, a final `ERROR`
pointing at the carrier's status page and the last successful sync, and a non-zero exit.

Unlike the other RCA samples, nothing in this integration is wrong: the endpoint, account
and credentials are the ones that worked until the outage. It gives observability and RCA
tooling a failure that **no change to the integration's code or configuration can fix**,
so a triage step should decide a root cause analysis is not worth running.

The carrier's answer is simulated rather than fetched, so the run needs no network access
and fails within a second.

## Configuration

| Configurable | Default | Purpose |
|---|---|---|
| `carrierName` | `ParcelLink` | Carrier shown in the logs. |
| `ratesEndpoint` | `https://api.parcellink.example/v2/rates` | Carrier rating API. |
| `accountId` | `ACC-77120` | Carrier account the rates are requested for. |
| `maxAttempts` | `3` | Rate requests made before the run gives up. |

## Usage Instructions

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Automation** and give it a schedule,
   or run it once with **Test**.
2. Each run logs `Carrier rate sync started` and `Authenticated with carrier`, then three
   `Carrier rating API unavailable` errors (`status=503`), and fails with
   `Carrier rate sync aborted: the carrier's rating API is down for planned maintenance`.

## References

- [Schedule Your First Automation](https://wso2.com/devant/docs/quick-start-guides/schedule-your-first-automation)
