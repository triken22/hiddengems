import Foundation
import CoreLocation

protocol LocationService {
    func currentLocation() async -> CLLocation?
}

final class DefaultLocationService: NSObject, LocationService, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?
    private let timeoutSeconds: TimeInterval = 8

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async -> CLLocation? {
        // Handle denied/restricted quickly
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted { return nil }
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        manager.startUpdatingLocation()

        return await withCheckedContinuation { continuation in
            // If another caller is pending, resume it to avoid leaks
            self.continuation?.resume(returning: nil)
            self.continuation = continuation

            // Timeout safeguard
            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds) { [weak self] in
                guard let self = self, let cont = self.continuation else { return }
                cont.resume(returning: nil)
                self.continuation = nil
                self.manager.stopUpdatingLocation()
            }
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
