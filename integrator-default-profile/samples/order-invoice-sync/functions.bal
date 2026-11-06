import ballerina/log;

// Stands in for GET {storefrontApiUrl}/orders?financial_status=paid&created_at_min={since}.
// It returns the response captured from the store on 2026-11-05, so every run
// sees the same orders and the sample needs no network access or credentials.
function fetchPaidOrders(string since) returns json {
    return [
        {
            id: "gid://store/Order/5521041",
            orderNumber: "#1041",
            createdAt: "2026-11-05T08:14:22Z",
            currency: "USD",
            customerEmail: "maya.chen@example.com",
            billingAddress: {name: "Maya Chen", line1: "418 Alder St", city: "Portland", postalCode: "97205", country: "US"},
            shippingAddress: {name: "Maya Chen", line1: "418 Alder St", city: "Portland", postalCode: "97205", country: "US"},
            lineItems: [
                {sku: "NW-HD-204-M", title: "Ridge Fleece Hoodie (M)", quantity: 1, unitPrice: 68.00, requiresShipping: true}
            ],
            shippingFee: 6.50
        },
        {
            id: "gid://store/Order/5521042",
            orderNumber: "#1042",
            createdAt: "2026-11-05T09:02:47Z",
            currency: "EUR",
            customerEmail: "jonas.weber@example.de",
            billingAddress: {name: "Jonas Weber", line1: "Lindenstraße 12", city: "Berlin", postalCode: "10969", country: "DE"},
            shippingAddress: {name: "Jonas Weber", line1: "Lindenstraße 12", city: "Berlin", postalCode: "10969", country: "DE"},
            lineItems: [
                {sku: "NW-TR-110-L", title: "Trail Runner Tee (L)", quantity: 2, unitPrice: 24.00, requiresShipping: true},
                {sku: "NW-BT-031", title: "Canvas Belt", quantity: 1, unitPrice: 19.00, requiresShipping: true}
            ],
            shippingFee: 9.90
        },
        {
            // A digital gift card: nothing to ship, so the storefront sends no shipping address.
            id: "gid://store/Order/5521043",
            orderNumber: "#1043",
            createdAt: "2026-11-05T10:31:05Z",
            currency: "GBP",
            customerEmail: "priya.nair@example.co.uk",
            billingAddress: {name: "Priya Nair", line1: "27 Mill Lane", city: "Leeds", postalCode: "LS6 2AA", country: "GB"},
            shippingAddress: (),
            lineItems: [
                {sku: "NW-GC-050", title: "Digital Gift Card £50", quantity: 1, unitPrice: 50.00, requiresShipping: false}
            ],
            shippingFee: 0.00
        },
        {
            id: "gid://store/Order/5521044",
            orderNumber: "#1044",
            createdAt: "2026-11-05T11:48:39Z",
            currency: "USD",
            customerEmail: "kasun.perera@example.lk",
            billingAddress: {name: "Kasun Perera", line1: "55 Galle Road", city: "Colombo", postalCode: "00300", country: "LK"},
            shippingAddress: {name: "Kasun Perera", line1: "55 Galle Road", city: "Colombo", postalCode: "00300", country: "LK"},
            lineItems: [
                {sku: "NW-JK-502-S", title: "Storm Shell Jacket (S)", quantity: 1, unitPrice: 149.00, requiresShipping: true}
            ],
            shippingFee: 18.00
        }
    ];
}

// Maps a storefront order to an invoice: one line per item, plus a shipping
// line when the order was charged for shipping.
function toInvoice(Order storeOrder, string issueDate) returns Invoice {
    InvoiceLine[] lines = from LineItem item in storeOrder.lineItems
        select {description: string `${item.sku} ${item.title}`, quantity: item.quantity, unitAmount: item.unitPrice};
    if storeOrder.shippingFee > 0d {
        lines.push({description: "Shipping", quantity: 1, unitAmount: storeOrder.shippingFee});
    }
    decimal total = 0;
    foreach InvoiceLine line in lines {
        total += line.unitAmount * <decimal>line.quantity;
    }
    return {
        reference: storeOrder.orderNumber,
        customerEmail: storeOrder.customerEmail,
        currency: storeOrder.currency,
        // Sales tax is charged by the country the goods are shipped to.
        taxRegion: storeOrder.shippingAddress.country,
        issueDate,
        lines,
        total
    };
}

// Stands in for POST {accountingApiUrl}/invoices and returns the new invoice's id.
function createInvoice(Invoice invoice) returns string {
    string invoiceId = string `INV-2026-${invoice.reference.substring(1)}`;
    log:printInfo("Invoice created", invoiceId = invoiceId, orderNumber = invoice.reference,
            total = invoice.total, currency = invoice.currency, taxRegion = invoice.taxRegion);
    return invoiceId;
}
