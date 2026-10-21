import ballerina/http;
import ballerina/log;

type Customer record {|
    string id;
    string name;
    string email;
    string tier;
|};

// Rows as exported from the CRM. C-1004 was migrated from the legacy system
// without an email (null), which the Customer type does not allow, so every
// request that touches it fails with a 500 in the same diagnosable way while
// the other customers load fine: this sample exists to give observability and
// RCA tooling a failure to analyse. Give C-1004 an email to make it succeed.
final map<json>[] & readonly crmExport = [
    {id: "C-1001", name: "Nimal Perera", email: "nimal.perera@example.com", tier: "gold"},
    {id: "C-1002", name: "Ayesha Fernando", email: "ayesha.f@example.com", tier: "silver"},
    {id: "C-1003", name: "Kasun Silva", email: "kasun.silva@example.com", tier: "bronze"},
    {id: "C-1004", name: "Dilini Jayawardena", email: null, tier: "gold"},
    {id: "C-1005", name: "Ravi Kumar", email: "ravi.kumar@example.com", tier: "silver"}
];

service /crm on new http:Listener(9090) {

    // Lists every customer. Fails while any row is invalid.
    resource function get customers() returns Customer[]|http:InternalServerError {
        Customer[]|error customers = crmExport.cloneWithType();
        if customers is error {
            log:printError("Failed to load customers: CRM record does not match the Customer schema",
                    'error = customers);
            return http:INTERNAL_SERVER_ERROR;
        }
        return customers;
    }

    // Fetches one customer. Fails only for the invalid row.
    resource function get customers/[string id]() returns Customer|http:NotFound|http:InternalServerError {
        foreach map<json> row in crmExport {
            if row["id"] != id {
                continue;
            }
            Customer|error customer = row.cloneWithType();
            if customer is error {
                log:printError("Failed to load customer: CRM record does not match the Customer schema",
                        'error = customer, customerId = id);
                return http:INTERNAL_SERVER_ERROR;
            }
            return customer;
        }
        return http:NOT_FOUND;
    }
}
