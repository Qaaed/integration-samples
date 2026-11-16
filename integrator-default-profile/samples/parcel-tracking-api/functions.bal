// Stands in for GET {carrierApiUrl}/shipments/{trackingNumber}. It returns the
// responses captured from the carrier on 2026-11-12, so every request sees the
// same parcels and the sample needs no network access or credentials.
function fetchTracking(string trackingNumber) returns json? {
    map<json> captured = {
        "SWL-48213001": {
            trackingNumber: "SWL-48213001",
            serviceLevel: "Ground",
            origin: "Portland, OR, US",
            destination: "Seattle, WA, US",
            events: [
                {timestamp: "2026-11-10T09:12:00Z", status: "LABEL_CREATED", location: "Portland, OR, US"},
                {timestamp: "2026-11-10T17:45:00Z", status: "IN_TRANSIT", location: "Portland Hub, OR, US"},
                {timestamp: "2026-11-11T08:03:00Z", status: "OUT_FOR_DELIVERY", location: "Seattle, WA, US"},
                {timestamp: "2026-11-11T14:28:00Z", status: "DELIVERED", location: "Seattle, WA, US"}
            ]
        },
        "SWL-48213002": {
            trackingNumber: "SWL-48213002",
            serviceLevel: "Express",
            origin: "Portland, OR, US",
            destination: "Denver, CO, US",
            events: [
                {timestamp: "2026-11-11T10:40:00Z", status: "LABEL_CREATED", location: "Portland, OR, US"},
                {timestamp: "2026-11-11T19:02:00Z", status: "IN_TRANSIT", location: "Salt Lake City Hub, UT, US"},
                {timestamp: "2026-11-12T07:51:00Z", status: "OUT_FOR_DELIVERY", location: "Denver, CO, US"}
            ]
        },
        "SWL-48213003": {
            // An international parcel: it has to clear customs in the destination country.
            trackingNumber: "SWL-48213003",
            serviceLevel: "International Priority",
            origin: "Portland, OR, US",
            destination: "Leeds, GB",
            events: [
                {timestamp: "2026-11-09T11:20:00Z", status: "LABEL_CREATED", location: "Portland, OR, US"},
                {timestamp: "2026-11-09T22:15:00Z", status: "IN_TRANSIT", location: "Los Angeles Gateway, CA, US"},
                {timestamp: "2026-11-11T06:38:00Z", status: "HELD_AT_CUSTOMS", location: "London Heathrow, GB"}
            ]
        }
    };
    return captured[trackingNumber];
}

// Maps the carrier's tracking response to the status shown on the order page:
// the latest event, in words a customer understands.
function toParcelStatus(CarrierTracking tracking) returns ParcelStatus {
    CarrierEvent latest = tracking.events[tracking.events.length() - 1];
    return {
        trackingNumber: tracking.trackingNumber,
        status: latest.status,
        statusText: statusTexts[latest.status] ?: latest.status,
        lastLocation: latest.location,
        lastUpdated: latest.timestamp,
        events: tracking.events.length()
    };
}

// The customer-facing wording of each carrier status.
final readonly & map<string> statusTexts = {
    [LABEL_CREATED]: "Label created, waiting for the carrier to collect it",
    [IN_TRANSIT]: "On its way",
    [OUT_FOR_DELIVERY]: "Out for delivery today",
    [DELIVERED]: "Delivered"
};
