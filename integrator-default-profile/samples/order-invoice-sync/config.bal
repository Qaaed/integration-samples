// The store whose paid orders are invoiced, and the accounting system the
// invoices are created in.
configurable string storeName = "Northwind Outfitters";
configurable string storefrontApiUrl = "https://northwind-outfitters.example/admin/api/2024-10";
configurable string accountingApiUrl = "https://books.northwind.example/api/v1";

// How far back each run looks for paid orders. The task runs hourly; the
// overlap is safe because invoices are keyed by order number.
configurable int lookbackHours = 24;
