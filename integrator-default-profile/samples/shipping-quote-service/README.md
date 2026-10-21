# Shipping Quote Service (Integration as API)

## Description
A REST API that quotes a shipment by calling a carrier's rate API:
`POST /shipping/quote` returns the carrier, price and delivery estimate.

The carrier API is simulated by the service itself (`POST /carrier/rates`) and answers
after 8 seconds, while the client gives up after 3. **Every quote fails the same way**:
about 3 seconds after the request, the caller gets a `504` and the service logs an `ERROR`,
`Shipping quote failed: carrier rate API timed out`, with the timeout, the elapsed time and
the upstream URL. This gives observability and RCA tooling a realistic, diagnosable
latency failure caused by a slow dependency.

## Configuration

| Configurable | Default | Purpose |
|---|---|---|
| `carrierApiUrl` | `http://localhost:9090` | Base URL of the carrier rate API. |
| `carrierTimeoutSeconds` | `3` | Client timeout for carrier calls. |
| `carrierLatencySeconds` | `8` | Delay of the simulated carrier. Set it below the timeout to make quotes succeed. |

## Usage Instructions

1. Run the integration locally using the **Run** button in Ballerina Integrator.
2. Request a quote:

   ```bash
   curl -i -X POST localhost:9090/shipping/quote -H 'Content-Type: application/json' \
     -d '{"origin":"Colombo","destination":"Kandy","weightKg":2.5}'
   ```

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Integration as API**.
2. Once deployed, click on **"Test"** and call `POST /shipping/quote` to produce the
   timeouts.
