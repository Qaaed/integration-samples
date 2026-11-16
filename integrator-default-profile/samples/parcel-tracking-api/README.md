# Parcel Tracking API (Integration as API)

## Description
A REST API behind a store's order page that shows where a customer's parcel is:
`GET /tracking/parcels/{trackingNumber}` reads the parcel from the carrier's tracking API and
returns its latest status, in words a customer understands, with its last location and time.

The project follows the usual layout: `config.bal` holds the configurables, `types.bal` the
carrier's tracking payload and the API's response, `functions.bal` the carrier call and the
mapping, and `main.bal` the service itself.

## Failing on purpose (RCA testing)

The service starts and serves normally; domestic parcels return `200`. The carrier's
response for the international parcel `SWL-48213003` has a status the integration doesn't
know: `HELD_AT_CUSTOMS`, which the carrier reports while a parcel clears customs in the
destination country. **Every request for that parcel fails the same way:**
- the caller gets a `500`, `Tracking is unavailable for this parcel right now`;
- the service logs one `ERROR`, `Could not read the carrier's tracking response; the
  parcel's status is unavailable`, whose `reason` names the failing field: `field
  'events[2].status' in record 'CarrierEvent' should be of type 'CarrierStatus', found
  '"HELD_AT_CUSTOMS"'`.

Customers with an international parcel at customs see no tracking at all, while those with
domestic parcels are unaffected. The fix belongs in the integration's code: the carrier's
data is valid, and retrying or changing the configuration doesn't help.

The carrier's responses are the ones captured on 2026-11-12, so the service needs no network
access or credentials.

| Tracking number | Parcel | Result |
|---|---|---|
| `SWL-48213001` | Ground, Portland → Seattle | `200`, `DELIVERED` |
| `SWL-48213002` | Express, Portland → Denver | `200`, `OUT_FOR_DELIVERY` |
| `SWL-48213003` | International, Portland → Leeds | `500` and an `ERROR` log |
| anything else | – | `404` |

## Configuration

| Configurable | Default | Purpose |
|---|---|---|
| `carrierName` | `Swiftline Parcel` | Carrier shown in the logs. |
| `carrierApiUrl` | `https://api.swiftline.example/track/v2` | Carrier tracking API the parcels are read from. |

## Usage Instructions

### Run locally

1. Run the integration with the **Run** button in Ballerina Integrator, or `bal run`.
2. Look up a parcel:

   ```bash
   curl localhost:9090/tracking/parcels/SWL-48213001   # 200
   curl localhost:9090/tracking/parcels/SWL-48213003   # 500, logs the ERROR
   ```

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Integration as API**. The endpoint
   (port `9090`, base path `/tracking`) comes from `.choreo/component.yaml`.
2. Once it's running, call `GET /tracking/parcels/SWL-48213003` a few times. Each call logs
   the `ERROR` above.
3. Once fixed, the same call returns `200` with the parcel's customs status, and no `ERROR`
   is logged.
