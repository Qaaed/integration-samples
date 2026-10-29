import ballerina/log;

type Order record {|
    string id;
    string amount;
|};

// Fixed batch to total. ORD-1003's amount has the letter O in place of a zero,
// so every run fails on it in the same diagnosable way: this sample exists to
// give observability and RCA tooling a failure to analyse. Correct that amount
// to make the runs succeed.
//cloud editor commit 
final Order[] & readonly batch = [
    {id: "ORD-1001", amount: "120.50"},
    {id: "ORD-1002", amount: "75.00"},
    {id: "ORD-1003", amount: "1O0.00"}
];

public function main() returns error? {
    log:printInfo("Order batch run started", orders = batch.length());

    decimal total = 0;
    foreach Order 'order in batch {
        decimal|error amount = decimal:fromString('order.amount);
        if amount is error {
            log:printError("Order batch failed: order amount is not a number", 'error = amount,
                    orderId = 'order.id, amount = 'order.amount);
            return error(string `order ${'order.id} has an invalid amount '${'order.amount}'`, amount);
        }
        total += amount;
    }

    log:printInfo("Order batch completed", orders = batch.length(), total = total);
}
