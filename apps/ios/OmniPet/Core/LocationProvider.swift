import Foundation
import CoreLocation

actor LocationProvider {
    private let manager = CLLocationManager()

    func currentLocation() async -> CLLocation? {
        manager.requestWhenInUseAuthorization()
        return manager.location
    }
}
