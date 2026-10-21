import ballerina/http;
import ballerina/log;

type LineItem record {|
    string sku;
    int quantity;
    decimal unitPrice;
|};

type PriceRequest record {|
    LineItem[] items;
|};

type PriceQuote record {|
    decimal subtotal;
    decimal vat;
    decimal total;
    string currency;
|};

// VAT rate applied to every quote, as a percentage. The default 1800 was
// copied from the finance system, which stores rates in basis points (1800 =
// 18%). The service refuses to start with a rate above 100%, so every pod
// exits at startup and crash-loops in the same diagnosable way: this sample
// exists to give observability and RCA tooling a failure to analyse. Set it
// to 18 to make the service start.
configurable decimal vatRatePercent = 1800;
configurable string currency = "LKR";

function init() returns error? {
    if vatRatePercent < 0d || vatRatePercent > 100d {
        log:printError("Startup aborted: VAT rate is outside the 0-100% range",
                vatRatePercent = vatRatePercent);
        return error(string `invalid configuration: vatRatePercent ${vatRatePercent} is outside 0-100`);
    }
    log:printInfo("Order pricing service started", vatRatePercent = vatRatePercent, currency = currency);
}

service /pricing on new http:Listener(9090) {

    // Prices a basket: subtotal of the line items plus VAT.
    resource function post quote(PriceRequest request) returns PriceQuote {
        decimal subtotal = 0;
        foreach LineItem item in request.items {
            subtotal += item.unitPrice * <decimal>item.quantity;
        }
        decimal vat = (subtotal * vatRatePercent / 100).round(2);
        return {subtotal, vat, total: subtotal + vat, currency};
    }
}
