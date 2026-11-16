import ballerina/log;

type RateResponse record {|
    int statusCode;
    string reason;
    string body;
    int retryAfterSeconds;
|};

// The carrier whose shipping rates this task refreshes. The endpoint, account
// and credentials are correct: the same configuration synced successfully on
// every run up to the carrier's planned maintenance window.
configurable string carrierName = "ParcelLink";
configurable string ratesEndpoint = "https://api.parcellink.example/v2/rates";
configurable string accountId = "ACC-77120";
configurable int maxAttempts = 3;

const string LAST_SUCCESSFUL_SYNC = "2026-11-04T22:00:00Z";
const string STATUS_PAGE = "https://status.parcellink.example";

final string[] & readonly lanes = ["CMB-SIN", "CMB-DXB", "CMB-LHR", "CMB-JFK"];

// The carrier's rating platform is offline for planned maintenance, so every
// rate request is answered 503 by its gateway. The answer is simulated rather
// than fetched, so the run fails the same way every time with no network
// access: this sample exists to give observability and RCA tooling a failure
// that no change to the integration can fix.
function requestRates(string lane, int attempt) returns RateResponse {
    return {
        statusCode: 503,
        reason: "Service Unavailable",
        body: "Planned maintenance: the rating platform is offline until 06:00 UTC",
        retryAfterSeconds: 1800
    };
}

public function main() returns error? {
    log:printInfo("Carrier rate sync started", carrier = carrierName, endpoint = ratesEndpoint,
            accountId = accountId, lanes = lanes.length());
    log:printInfo("Authenticated with carrier", carrier = carrierName, accountId = accountId,
            tokenExpiresInSeconds = 3600);

    string lane = lanes[0];
    RateResponse? last = ();
    foreach int attempt in 1 ... maxAttempts {
        RateResponse response = requestRates(lane, attempt);
        last = response;
        log:printError("Carrier rating API unavailable",
                carrier = carrierName, endpoint = ratesEndpoint, lane = lane, attempt = attempt,
                maxAttempts = maxAttempts, status = response.statusCode, reason = response.reason,
                carrierMessage = response.body, retryAfterSeconds = response.retryAfterSeconds);
    }

    log:printError("Carrier rate sync aborted: the carrier's rating API is down for planned maintenance",
            carrier = carrierName, endpoint = ratesEndpoint, statusPage = STATUS_PAGE,
            statusPageReport = "Rating API: major outage (planned maintenance until 06:00 UTC)",
            lastSuccessfulSync = LAST_SUCCESSFUL_SYNC,
            note = "same endpoint, account and credentials as the last successful sync");
    return error(string `${carrierName} rating API unavailable after ${maxAttempts} attempts: ${
        last is RateResponse ? last.reason : "no response"}`);
}
