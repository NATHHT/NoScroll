import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isMonitoring: Bool = false
    @Published var monitoredRegions: [CLCircularRegion] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func startMonitoring() {
        switch authorizationStatus {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            isMonitoring = true
        default: break
        }
    }

    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        isMonitoring = false
    }

    func startMonitoringGeofence(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        locationManager.startMonitoring(for: region)
        monitoredRegions.append(region)
    }

    func stopMonitoringGeofence(identifier: String) {
        if let index = monitoredRegions.firstIndex(where: { $0.identifier == identifier }) {
            locationManager.stopMonitoring(for: monitoredRegions[index])
            monitoredRegions.remove(at: index)
        }
    }

    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: location)
    }

    func getAddress(from coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { completion(nil); return }
            var address = ""
            if let name = placemark.name { address += name + ", " }
            if let locality = placemark.locality { address += locality }
            completion(address.isEmpty ? nil : address)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways { startMonitoring() }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        NotificationCenter.default.post(name: .didEnterBlockedZone, object: region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NotificationCenter.default.post(name: .didExitBlockedZone, object: region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed: \(error.localizedDescription)")
    }
}

extension Notification.Name {
    static let didEnterBlockedZone = Notification.Name("DidEnterBlockedZone")
    static let didExitBlockedZone = Notification.Name("DidExitBlockedZone")
}
