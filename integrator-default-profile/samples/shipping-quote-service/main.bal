import ballerina/http;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/time;

type QuoteRequest record {|
    string origin;
    string destination;
    decimal weightKg;
|};

type CarrierRate record {|
    string carrier;
    decimal price;
    int etaDays;
|};

// The carrier rate API. The default points at this service's own simulated
// carrier, which answers after carrierLatencySeconds (8s) while the client
// gives up after carrierTimeoutSeconds (3s), so every quote fails with a 504
// in the same diagnosable way: this sample exists to give observability and
// RCA tooling a failure to analyse. Lower the latency or raise the timeout
// above it to make the quotes succeed.
configurable string carrierApiUrl = "http://localhost:9090";
configurable decimal carrierTimeoutSeconds = 3;
configurable decimal carrierLatencySeconds = 8;

final http:Client carrier = check new (carrierApiUrl, timeout = carrierTimeoutSeconds);

service / on new http:Listener(9090) {

    // Quotes a shipment by asking the carrier for a rate.
    resource function post shipping/quote(QuoteRequest request)
            returns CarrierRate|http:GatewayTimeout|http:BadGateway {
        time:Utc startedAt = time:utcNow();
        CarrierRate|error rate = carrier->post("/carrier/rates", request);
        decimal elapsedSeconds = time:utcDiffSeconds(time:utcNow(), startedAt);

        if rate is http:IdleTimeoutError {
            log:printError("Shipping quote failed: carrier rate API timed out", 'error = rate,
                    timeoutSeconds = carrierTimeoutSeconds, elapsedSeconds = elapsedSeconds,
                    upstream = carrierApiUrl, origin = request.origin, destination = request.destination);
            return http:GATEWAY_TIMEOUT;
        }
        if rate is error {
            log:printError("Shipping quote failed: carrier rate API call failed", 'error = rate,
                    elapsedSeconds = elapsedSeconds, upstream = carrierApiUrl);
            return http:BAD_GATEWAY;
        }
        log:printInfo("Shipping quote served", carrier = rate.carrier, price = rate.price,
                elapsedSeconds = elapsedSeconds);
        return rate;
    }

    // Simulated carrier rate API, standing in for the carrier's real endpoint.
    resource function post carrier/rates(QuoteRequest request) returns CarrierRate {
        runtime:sleep(carrierLatencySeconds);
        return {carrier: "LankaExpress", price: 450 + request.weightKg * 120, etaDays: 2};
    }
}
