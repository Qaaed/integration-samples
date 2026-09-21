import ballerina/http;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/time;

// Upstream inventory service. The default points at a host that does not
// resolve, so every run fails in the same diagnosable way: this sample exists
// to give observability and RCA tooling a realistic failure to analyse.
// Override it with a reachable URL to make the runs succeed.
configurable string inventoryServiceUrl = "http://inventory-service.internal:8080";
configurable string warehouseId = "colombo-01";
configurable int maxRetries = 3;
configurable decimal requestTimeoutSeconds = 5;

public function main() returns error? {
    string runAt = time:utcToString(time:utcNow());
    log:printInfo("Inventory sync run started", runAt = runAt, upstream = inventoryServiceUrl,
            warehouse = warehouseId);

    http:Client inventory = check new (inventoryServiceUrl, timeout = requestTimeoutSeconds);
    string path = string `/api/v1/stock?warehouse=${warehouseId}`;

    int attempt = 1;
    while true {
        json|error stock = inventory->get(path);
        if stock is json {
            log:printInfo("Inventory sync completed", attempt = attempt, warehouse = warehouseId);
            return;
        }
        if attempt >= maxRetries {
            log:printError("Inventory sync failed: upstream inventory service unreachable after retries",
                    'error = stock, attempts = attempt, upstream = inventoryServiceUrl,
                    warehouse = warehouseId);
            return error(string `inventory sync failed after ${attempt} attempts`, stock);
        }
        decimal backoffSeconds = <decimal>attempt * 2;
        log:printWarn("Inventory service call failed, retrying", 'error = stock, attempt = attempt,
                maxRetries = maxRetries, backoffSeconds = backoffSeconds);
        runtime:sleep(backoffSeconds);
        attempt += 1;
    }
}
