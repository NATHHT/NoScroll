import SwiftUI
import CoreLocation

struct BlockingView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showingAddRule = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Location Rules")) {
                    ForEach(appData.locationRules) { rule in
                        LocationRuleRow(rule: rule)
                    }
                    .onDelete { indexSet in
                        appData.removeLocationRule(at: indexSet)
                    }
                }

                Section(header: Text("Bluetooth Devices")) {
                    ForEach(bluetoothManager.discoveredDevices) { device in
                        BluetoothDeviceRow(device: device)
                    }
                }
            }
            .navigationTitle("Blocking Rules")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRule = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRule) {
                AddLocationRuleView()
                    .environmentObject(appData)
                    .environmentObject(locationManager)
            }
        }
    }
}

struct LocationRuleRow: View {
    let rule: LocationRule

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(rule.name)
                    .font(.headline)
                Text(rule.ruleType.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if let coord = rule.coordinate {
                    Text("Range: \(Int(rule.rangeMeters))m")
                        .font(.caption)
                }
            }
            Spacer()
            if rule.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

struct BluetoothDeviceRow: View {
    @EnvironmentObject var appData: AppData
    let device: BluetoothDevice

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                if let distance = device.distanceEstimate {
                    Text("~ \(Int(distance))m away")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Button {
                appData.addLocationRule(LocationRule(
                    name: device.name,
                    ruleType: .bluetooth,
                    deviceIdentifier: device.identifier
                ))
            } label: {
                Image(systemName: "plus.circle")
                    .foregroundColor(.blue)
            }
        }
    }
}

struct AddLocationRuleView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\dismiss) var dismiss

    @State private var ruleName = ""
    @State private var ruleType: RuleType = .gps
    @State private var rangeMeters: Double = 10.0
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var gracePeriodMinutes: Int = 1
    @State private var useGracePeriod = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rule Details")) {
                    TextField("Rule Name", text: $ruleName)
                    Picker("Rule Type", selection: $ruleType) {
                        Text("GPS").tag(RuleType.gps)
                        Text("Bluetooth").tag(RuleType.bluetooth)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                if ruleType == .gps {
                    Section(header: Text("Location")) {
                        if let coord = selectedCoordinate {
                            VStack(alignment: .leading) {
                                Text("Latitude: \(coord.latitude)")
                                Text("Longitude: \(coord.longitude)")
                            }
                        }
                        Slider(value: $rangeMeters, in: 1...100, step: 1) {
                            Text("Range")
                        }
                        Text("\(Int(rangeMeters)) meters")
                    }
                }

                Section(header: Text("Grace Period")) {
                    Toggle("Use Grace Period", isOn: $useGracePeriod)
                    if useGracePeriod {
                        Stepper("Minutes: \(gracePeriodMinutes)", value: $gracePeriodMinutes, in: 1...10)
                    }
                }
            }
            .navigationTitle("Add Location Rule")
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
                    .disabled(ruleName.isEmpty)
                }
            }
        }
    }

    private func saveRule() {
        let rule = LocationRule(
            name: ruleName,
            ruleType: ruleType,
            coordinate: selectedCoordinate,
            rangeMeters: rangeMeters,
            gracePeriodSeconds: useGracePeriod ? gracePeriodMinutes * 60 : nil
        )
        appData.addLocationRule(rule)
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
