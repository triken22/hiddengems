import Foundation
import CoreLocation

protocol LocationService {
    func currentLocation() async -> CLLocation?
}

final class DefaultLocationService: NSObject, LocationService, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async -> CLLocation? {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.last)
        continuation = nil
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }
}

final class PreviewLocationService: LocationService {
    func currentLocation() async -> CLLocation? {
        CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
}
