import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    @Published var isScanning: Bool = false
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var authorizationStatus: CBManagerAuthorization = .notDetermined
    @Published var isPoweredOn: Bool = false
    private var monitoredDeviceIDs: Set<String> = []
    @Published var isInRangeOfMonitoredDevice: Bool = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        isScanning = true
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }

    func startMonitoring(deviceID: String) {
        monitoredDeviceIDs.insert(deviceID)
        startScanning()
    }

    func stopMonitoring(deviceID: String) {
        monitoredDeviceIDs.remove(deviceID)
        if monitoredDeviceIDs.isEmpty { stopScanning() }
    }

    func stopMonitoringAll() {
        monitoredDeviceIDs.removeAll()
        stopScanning()
    }

    func estimateDistance(from rssi: Int) -> Double {
        if rssi >= -50 { return 1.0 }
        else if rssi >= -60 { return 3.0 }
        else if rssi >= -70 { return 10.0 }
        else if rssi >= -80 { return 20.0 }
        else { return 30.0 + Double(abs(rssi + 80)) * 2 }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        authorizationStatus = CBManager.authorization
        isPoweredOn = central.state == .poweredOn
        switch central.state {
        case .poweredOn: startScanning()
        case .poweredOff: stopScanning()
        default: stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceName = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        let deviceID = peripheral.identifier.uuidString
        if let index = discoveredDevices.firstIndex(where: { $0.identifier == deviceID }) {
            discoveredDevices[index] = BluetoothDevice(id: discoveredDevices[index].id, identifier: deviceID, name: deviceName, rssi: RSSI.intValue)
        } else {
            discoveredDevices.append(BluetoothDevice(identifier: deviceID, name: deviceName, rssi: RSSI.intValue))
        }
        if monitoredDeviceIDs.contains(deviceID) {
            let distance = estimateDistance(from: RSSI.intValue)
            isInRangeOfMonitoredDevice = distance < 15.0
            NotificationCenter.default.post(name: .bluetoothDeviceInRange, object: deviceID, userInfo: ["distance": distance, "name": deviceName])
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {}
}

struct BluetoothDevice: Identifiable {
    let id: UUID
    let identifier: String
    let name: String
    let rssi: Int
    var distanceEstimate: Double?

    init(id: UUID = UUID(), identifier: String, name: String, rssi: Int) {
        self.id = id; self.identifier = identifier; self.name = name; self.rssi = rssi
        self.distanceEstimate = calculateDistance(from: rssi)
    }

    private func calculateDistance(from rssi: Int) -> Double? {
        if rssi == 0 { return nil }
        let txPower = -59; let pathLoss = 2.0
        let ratio = Double(rssi) / Double(txPower)
        if ratio < 1.0 { return pow(10.0, ((Double(txPower) - Double(rssi)) / (10 * pathLoss))) }
        return nil
    }
}

extension Notification.Name {
    static let bluetoothDeviceInRange = Notification.Name("BluetoothDeviceInRange")
    static let bluetoothDeviceOutOfRange = Notification.Name("BluetoothDeviceOutOfRange")
}
