import SwiftUI
import CoreLocation

struct BlockingView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showingAddRule = false
    @State private var showingBluetoothScan = false

    var activeRules: [LocationRule] {
        appData.locationRules.filter { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Active Rules")) {
                    if activeRules.isEmpty {
                        Text("No active blocking rules")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(activeRules) { rule in
                            LocationRuleRow(rule: rule, appData: appData)
                        }
                        .onDelete { indexSet in
                            appData.removeLocationRule(at: indexSet)
                        }
                    }
                }

                Section(header: Text("Bluetooth Devices")) {
                    if bluetoothManager.isPoweredOn {
                        if bluetoothManager.discoveredDevices.isEmpty {
                            Text("No devices found")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(bluetoothManager.discoveredDevices) { device in
                                BluetoothDeviceRow(device: device, appData: appData)
                            }
                        }
                    } else {
                        Text("Bluetooth is off")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Button {
                                showingAddRule = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add GPS Rule")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }

                            Button {
                                showingBluetoothScan = true
                            } label: {
                                HStack {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                    Text("Add Bluetooth Rule")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Blocking Rules")
            .sheet(isPresented: $showingAddRule) {
                AddGPSRuleView()
                    .environmentObject(appData)
                    .environmentObject(locationManager)
            }
            .sheet(isPresented: $showingBluetoothScan) {
                BluetoothScanView()
                    .environmentObject(appData)
                    .environmentObject(bluetoothManager)
            }
            .onAppear {
                if bluetoothManager.centralManager.state == .poweredOn {
                    bluetoothManager.startScanning()
                }
            }
        }
    }
}

struct LocationRuleRow: View {
    let rule: LocationRule
    let appData: AppData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: rule.ruleType == .gps ? "mappin" : "antenna.radiowaves.left.and.right")
                        .foregroundColor(.blue)
                    Text(rule.ruleType.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                if let coord = rule.coordinate {
                    Text("Range: \(Int(rule.rangeMeters))m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { rule.isActive },
                set: { isActive in
                    var updatedRule = rule
                    updatedRule.isActive = isActive
                    appData.updateLocationRule(updatedRule)
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}

struct BluetoothDeviceRow: View {
    let device: BluetoothDevice
    let appData: AppData

    @State private var showingAddConfirmation = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                
                if let distance = device.distanceEstimate {
                    Text("~ \(Int(distance))m away")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                showingAddConfirmation = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .confirmationDialog("Add Bluetooth Rule", isPresented: $showingAddConfirmation) {
            Button("Add Rule") {
                appData.addLocationRule(LocationRule(
                    name: device.name,
                    ruleType: .bluetooth,
                    deviceIdentifier: device.identifier,
                    rangeMeters: 10.0
                ))
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Add \(device.name) as a blocking rule?")
        }
    }
}

struct AddGPSRuleView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\dismiss) var dismiss

    @State private var ruleName = ""
    @State private var rangeMeters: Double = 10.0
    @State private var useGracePeriod = false
    @State private var gracePeriodMinutes: Int = 1

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rule Details")) {
                    TextField("Rule Name", text: $ruleName)
                    
                    if let location = locationManager.currentLocation {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Lat: \(location.coordinate.latitude)")
                            Text("Lon: \(location.coordinate.longitude)")
                        }
                        .font(.footnote)
                    }
                }

                Section(header: Text("Range")) {
                    Slider(value: $rangeMeters, in: 1...100, step: 1) {
                        Text("Range")
                    }
                    Text("\(Int(rangeMeters)) meters")
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Section(header: Text("Grace Period")) {
                    Toggle("Use Grace Period", isOn: $useGracePeriod)
                    if useGracePeriod {
                        Stepper("Minutes: \(gracePeriodMinutes)", value: $gracePeriodMinutes, in: 1...10)
                    }
                }
            }
            .navigationTitle("Add GPS Rule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRule()
                        dismiss()
                    }
                    .disabled(ruleName.isEmpty || locationManager.currentLocation == nil)
                }
            }
        }
    }

    private func saveRule() {
        guard let location = locationManager.currentLocation else { return }
        
        let rule = LocationRule(
            name: ruleName,
            ruleType: .gps,
            coordinate: location.coordinate,
            rangeMeters: rangeMeters,
            gracePeriodSeconds: useGracePeriod ? gracePeriodMinutes * 60 : nil
        )
        appData.addLocationRule(rule)
    }
}

struct BluetoothScanView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\dismiss) var dismiss

    @State private var selectedDevice: BluetoothDevice?
    @State private var rangeMeters: Double = 10.0

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Nearby Devices")) {
                    if bluetoothManager.discoveredDevices.isEmpty {
                        Text("Scanning for devices...")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(bluetoothManager.discoveredDevices) { device in
                            Button {
                                selectedDevice = device
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(device.name)
                                            .font(.headline)
                                        if let distance = device.distanceEstimate {
                                            Text("~ \(Int(distance))m")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if selectedDevice?.id == device.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }

                if let device = selectedDevice {
                    Section(header: Text("Rule Settings")) {
                        Text("Selected: \(device.name)")
                            .font(.subheadline)

                        Slider(value: $rangeMeters, in: 1...30, step: 1) {
                            Text("Range")
                        }
                        Text("\(Int(rangeMeters)) meters")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Bluetooth Scan")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Rule") {
                        if let device = selectedDevice {
                            appData.addLocationRule(LocationRule(
                                name: device.name,
                                ruleType: .bluetooth,
                                deviceIdentifier: device.identifier,
                                rangeMeters: rangeMeters
                            ))
                            dismiss()
                        }
                    }
                    .disabled(selectedDevice == nil)
                }
            }
            .onAppear {
                bluetoothManager.startScanning()
            }
            .onDisappear {
                bluetoothManager.stopScanning()
            }
        }
    }
}

struct BlockingView_Previews: PreviewProvider {
    static var previews: some View {
        BlockingView()
            .environmentObject(AppData())
            .environmentObject(LocationManager())
            .environmentObject(BluetoothManager())
    }
}
