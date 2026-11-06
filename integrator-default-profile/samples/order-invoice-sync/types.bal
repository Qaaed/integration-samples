// An order as the storefront's Admin API returns it from
// GET /orders?financial_status=paid. The records are open because the API
// sends many more fields than the sync uses.
type Address record {
    string name;
    string line1;
    string city;
    string postalCode;
    string country;
};

type LineItem record {
    string sku;
    string title;
    int quantity;
    decimal unitPrice;
    boolean requiresShipping;
};

type Order record {
    string id;
    string orderNumber;
    string createdAt;
    string currency;
    string customerEmail;
    Address billingAddress;
    Address shippingAddress;
    LineItem[] lineItems;
    decimal shippingFee;
};

// An invoice as the accounting system's API takes it.
type InvoiceLine record {|
    string description;
    int quantity;
    decimal unitAmount;
|};

type Invoice record {|
    string reference;
    string customerEmail;
    string currency;
    string taxRegion;
    string issueDate;
    InvoiceLine[] lines;
    decimal total;
|};
