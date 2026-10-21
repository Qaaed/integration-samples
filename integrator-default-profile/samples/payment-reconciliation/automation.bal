import ballerina/log;

type LedgerEntry record {|
    string txnId;
    string merchantId;
    decimal amount;
|};

type Settlement record {|
    string settlementId;
    string txnId;
    string merchantId;
    decimal amount;
|};

// Yesterday's ledger and the payment gateway's settlement file for the same
// day. The gateway settled TXN-50013 twice (SET-9004 and SET-9007), paying the
// merchant 249.99 too much, so every run fails reconciliation in the same
// diagnosable way: this sample exists to give observability and RCA tooling a
// failure to analyse. Remove SET-9007 to make the runs succeed.
final LedgerEntry[] & readonly ledger = [
    {txnId: "TXN-50011", merchantId: "MER-204", amount: 1200.00},
    {txnId: "TXN-50012", merchantId: "MER-117", amount: 89.50},
    {txnId: "TXN-50013", merchantId: "MER-204", amount: 249.99},
    {txnId: "TXN-50014", merchantId: "MER-388", amount: 3150.00},
    {txnId: "TXN-50015", merchantId: "MER-117", amount: 42.75}
];

final Settlement[] & readonly settlements = [
    {settlementId: "SET-9001", txnId: "TXN-50011", merchantId: "MER-204", amount: 1200.00},
    {settlementId: "SET-9002", txnId: "TXN-50012", merchantId: "MER-117", amount: 89.50},
    {settlementId: "SET-9004", txnId: "TXN-50013", merchantId: "MER-204", amount: 249.99},
    {settlementId: "SET-9005", txnId: "TXN-50014", merchantId: "MER-388", amount: 3150.00},
    {settlementId: "SET-9006", txnId: "TXN-50015", merchantId: "MER-117", amount: 42.75},
    {settlementId: "SET-9007", txnId: "TXN-50013", merchantId: "MER-204", amount: 249.99}
];

configurable decimal toleranceAmount = 0.01;

public function main() returns error? {
    log:printInfo("Payment reconciliation run started", ledgerEntries = ledger.length(),
            settlements = settlements.length());

    map<LedgerEntry> ledgerByTxn = {};
    decimal ledgerTotal = 0;
    foreach LedgerEntry entry in ledger {
        ledgerByTxn[entry.txnId] = entry;
        ledgerTotal += entry.amount;
    }

    map<string> settledBy = {};
    decimal settledTotal = 0;
    int discrepancies = 0;
    foreach Settlement settlement in settlements {
        settledTotal += settlement.amount;

        string? firstSettlement = settledBy[settlement.txnId];
        if firstSettlement is string {
            log:printError("Duplicate settlement: transaction was settled more than once",
                    txnId = settlement.txnId, merchantId = settlement.merchantId,
                    firstSettlement = firstSettlement, duplicateSettlement = settlement.settlementId,
                    amount = settlement.amount);
            discrepancies += 1;
            continue;
        }
        settledBy[settlement.txnId] = settlement.settlementId;

        LedgerEntry? entry = ledgerByTxn[settlement.txnId];
        if entry is () {
            log:printError("Unknown settlement: transaction is not in the ledger",
                    txnId = settlement.txnId, settlementId = settlement.settlementId,
                    amount = settlement.amount);
            discrepancies += 1;
        } else if entry.amount != settlement.amount {
            log:printError("Amount mismatch: settlement differs from the ledger",
                    txnId = settlement.txnId, settlementId = settlement.settlementId,
                    ledgerAmount = entry.amount, settledAmount = settlement.amount);
            discrepancies += 1;
        }
    }

    foreach LedgerEntry entry in ledger {
        if !settledBy.hasKey(entry.txnId) {
            log:printError("Missing settlement: ledger transaction was never settled",
                    txnId = entry.txnId, merchantId = entry.merchantId, amount = entry.amount);
            discrepancies += 1;
        }
    }

    decimal variance = settledTotal - ledgerTotal;
    if discrepancies > 0 || variance.abs() > toleranceAmount {
        log:printError("Payment reconciliation failed: gateway settlements do not match the ledger",
                ledgerTotal = ledgerTotal, settledTotal = settledTotal, variance = variance,
                discrepancies = discrepancies);
        return error(string `reconciliation failed: ${discrepancies} discrepancies, variance ${variance}`);
    }

    log:printInfo("Payment reconciliation completed", transactions = ledger.length(), total = ledgerTotal);
}
