import SwiftUI

@main
struct NoScrollApp: App {
    @StateObject private var appData = AppData()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var bluetoothManager = BluetoothManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appData)
                .environmentObject(locationManager)
                .environmentObject(bluetoothManager)
                .onAppear {
                    locationManager.startMonitoring()
                    bluetoothManager.startScanning()
                }
        }
    }
}
