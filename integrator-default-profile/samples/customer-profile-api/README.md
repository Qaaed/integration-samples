# Customer Profile API (Integration as API)

## Description
A REST API that serves customer profiles from a CRM export:
`GET /crm/customers` lists them and `GET /crm/customers/{id}` fetches one.

Customer `C-1004` was migrated from a legacy system without an email (`null`), which the
`Customer` type does not allow. The service stays healthy, but **every request that touches
that record fails the same way**: `GET /crm/customers` and `GET /crm/customers/C-1004`
return `500`, while the other customers return `200`. Each failure logs an `ERROR`,
`CRM record does not match the Customer schema`, with the conversion error naming the
field (`email`, or `[3].email` for the list). This gives observability and RCA tooling a
realistic, diagnosable partial failure: an elevated error rate on one endpoint rather than
an outage.

To make every request succeed, give `C-1004` an email in `main.bal`.

## Usage Instructions

1. Run the integration locally using the **Run** button in Ballerina Integrator.
2. Send requests:

   ```bash
   curl -i localhost:9090/crm/customers/C-1001   # 200
   curl -i localhost:9090/crm/customers/C-1004   # 500
   curl -i localhost:9090/crm/customers          # 500
   ```

### Deploy on **WSO2 Cloud**

1. Deploy this integration on **WSO2 Cloud** as an **Integration as API**.
2. Once deployed, click on **"Test"** and call `GET /crm/customers` or
   `GET /crm/customers/C-1004` to produce the errors.
