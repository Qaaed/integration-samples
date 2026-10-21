import ballerina/log;

type StockLevel record {|
    string sku;
    int onHand;
    int unitsSold;
    int daysOnSale;
    int leadTimeDays;
|};

// Nightly snapshot from the warehouse system, with sales over the last 30
// days. SKU-7781 was listed today, so it has no sales history yet
// (daysOnSale = 0), and reorderQuantity divides by daysOnSale without
// guarding for new listings. Every run therefore raises reorders for the SKUs
// before it, then panics on SKU-7781 in the same diagnosable way: this sample
// exists to give observability and RCA tooling a failure to analyse. Treat a
// SKU with no sales history as needing no reorder to make the runs succeed.
final StockLevel[] & readonly snapshot = [
    {sku: "SKU-1042", onHand: 340, unitsSold: 1260, daysOnSale: 30, leadTimeDays: 7},
    {sku: "SKU-2210", onHand: 25, unitsSold: 450, daysOnSale: 30, leadTimeDays: 5},
    {sku: "SKU-3307", onHand: 0, unitsSold: 96, daysOnSale: 12, leadTimeDays: 10},
    {sku: "SKU-7781", onHand: 120, unitsSold: 0, daysOnSale: 0, leadTimeDays: 14},
    {sku: "SKU-8150", onHand: 60, unitsSold: 300, daysOnSale: 30, leadTimeDays: 3}
];

configurable int safetyStockDays = 3;

public function main() {
    log:printInfo("Inventory replenishment run started", skus = snapshot.length(),
            safetyStockDays = safetyStockDays);

    int reorders = 0;
    foreach StockLevel level in snapshot {
        int quantity = reorderQuantity(level);
        if quantity > 0 {
            log:printInfo("Reorder raised", sku = level.sku, quantity = quantity, onHand = level.onHand);
            reorders += 1;
        }
    }

    log:printInfo("Inventory replenishment completed", skus = snapshot.length(), reorders = reorders);
}

// Units to order so stock covers the supplier lead time plus the safety stock.
function reorderQuantity(StockLevel level) returns int {
    int dailySales = level.unitsSold / level.daysOnSale;
    int target = dailySales * (level.leadTimeDays + safetyStockDays);
    return target > level.onHand ? target - level.onHand : 0;
}
