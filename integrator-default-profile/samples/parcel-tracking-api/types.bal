// A parcel's status as the carrier's tracking API reports it.
enum CarrierStatus {
    LABEL_CREATED,
    IN_TRANSIT,
    OUT_FOR_DELIVERY,
    DELIVERED
}

// A parcel as the carrier's API returns it from GET /shipments/{trackingNumber}.
// The records are open because the API sends more fields than the store uses.
type CarrierEvent record {
    string timestamp;
    CarrierStatus status;
    string location;
};

type CarrierTracking record {
    string trackingNumber;
    string serviceLevel;
    string origin;
    string destination;
    CarrierEvent[] events;
};

// What the API returns to the store's order page.
type ParcelStatus record {|
    string trackingNumber;
    CarrierStatus status;
    string statusText;
    string lastLocation;
    string lastUpdated;
    int events;
|};
