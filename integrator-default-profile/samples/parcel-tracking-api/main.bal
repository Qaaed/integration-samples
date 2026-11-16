import ballerina/http;
import ballerina/lang.value;
import ballerina/log;

function init() {
    log:printInfo("Parcel tracking API started", carrier = carrierName, carrierApi = carrierApiUrl);
}

// Serves the delivery status shown on the store's order page.
service /tracking on new http:Listener(9090) {

    // Returns a parcel's latest status from the carrier's tracking API.
    resource function get parcels/[string trackingNumber]()
            returns ParcelStatus|http:NotFound|http:InternalServerError {
        json? response = fetchTracking(trackingNumber);
        if response is () {
            log:printInfo("Parcel not found at the carrier", carrier = carrierName,
                    trackingNumber = trackingNumber);
            return <http:NotFound>{body: {message: string `No parcel with tracking number ${trackingNumber}`}};
        }

        CarrierTracking|error tracking = response.fromJsonWithType();
        if tracking is error {
            value:Cloneable detail = tracking.detail()["message"];
            string reason = re `\s+`.replaceAll(detail is string ? detail : tracking.message(), " ");
            log:printError("Could not read the carrier's tracking response; the parcel's status is unavailable",
                    carrier = carrierName, trackingNumber = trackingNumber, reason = reason);
            return <http:InternalServerError>{body: {message: "Tracking is unavailable for this parcel right now"}};
        }

        ParcelStatus status = toParcelStatus(tracking);
        log:printInfo("Parcel status returned", trackingNumber = trackingNumber,
                status = status.status, lastLocation = status.lastLocation);
        return status;
    }
}
