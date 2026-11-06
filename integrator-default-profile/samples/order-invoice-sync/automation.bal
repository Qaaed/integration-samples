import ballerina/lang.value;
import ballerina/log;
import ballerina/time;

// Creates an invoice in the accounting system for every order paid in the
// store over the last `lookbackHours`.
public function main() returns error? {
    time:Utc now = time:utcNow();
    string since = time:utcToString(time:utcAddSeconds(now, -<decimal>(lookbackHours * 3600)));
    log:printInfo("Order invoice sync started", store = storeName, since = since,
            storefrontApi = storefrontApiUrl, accountingApi = accountingApiUrl);

    json response = fetchPaidOrders(since);
    string[] orderNumbers = response is json[]
        ? from json item in response select (check item.orderNumber).toString()
        : [];
    log:printInfo("Fetched paid orders from the storefront", store = storeName,
            orders = orderNumbers.length(), orderNumbers = string:'join(", ", ...orderNumbers));

    Order[]|error orders = response.fromJsonWithType();
    if orders is error {
        value:Cloneable detail = orders.detail()["message"];
        string reason = re `\s+`.replaceAll(detail is string ? detail : orders.message(), " ");
        log:printError("Could not read the storefront's orders; no invoices were created",
                store = storeName, orders = orderNumbers.length(), reason = reason);
        return error(string `order invoice sync failed: ${reason}`);
    }

    string issueDate = time:utcToString(now).substring(0, 10);
    foreach Order storeOrder in orders {
        _ = createInvoice(toInvoice(storeOrder, issueDate));
    }
    log:printInfo("Order invoice sync completed", store = storeName, invoices = orders.length());
}
