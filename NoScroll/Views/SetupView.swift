import SwiftUI
import CoreLocation

struct SetupView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\dismiss) var dismiss

    @State private var selectedApp: MonitoredApp?
    @State private var purpose: SessionPurpose = .browsing
    @State private var customLimit: Int = 15
    @State private var showLocationSetup = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Select App")) {
                    Picker("App", selection: $selectedApp) {
                        ForEach(appData.monitoredApps) { app in
                            Text(app.appName).tag(app as MonitoredApp?)
                        }
                    }
                }

                if selectedApp != nil {
                    Section(header: Text("Session Purpose")) {
                        Picker("Purpose", selection: $purpose) {
                            Text("Socializing").tag(SessionPurpose.socializing)
                            Text("Browsing").tag(SessionPurpose.browsing)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    Section(header: Text("Time Limit")) {
                        Stepper("Limit: \(customLimit) minutes", value: $customLimit, in: 5...120)
                    }
                }

                Section {
                    Button("Start Session") {
                        if let app = selectedApp {
                            appData.startSession(for: app, purpose: purpose)
                            dismiss()
                        }
                    }
                    .disabled(selectedApp == nil)
                    .frame(maxWidth: .infinity)
                }

                Section(header: Text("Location-Based Blocking")) {
                    Button("Setup Location Rule") {
                        showLocationSetup = true
                    }
                }
            }
            .navigationTitle("New Session")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showLocationSetup) {
                LocationSetupView()
                    .environmentObject(appData)
                    .environmentObject(locationManager)
            }
        }
    }
}

struct LocationSetupView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\dismiss) var dismiss

    @State private var ruleName = ""
    @State private var ruleType: RuleType = .gps
    @State private var rangeMeters: Double = 10.0
    @State private var useCurrentLocation = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rule Details")) {
                    TextField("Rule Name", text: $ruleName)
                    Picker("Type", selection: $ruleType) {
                        Text("GPS").tag(RuleType.gps)
                        Text("Bluetooth").tag(RuleType.bluetooth)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                if ruleType == .gps {
                    Section(header: Text("Location")) {
                        Toggle("Use Current Location", isOn: $useCurrentLocation)
                            .onChange(of: useCurrentLocation) { newValue in
                                if newValue {
                                    selectedCoordinate = locationManager.currentLocation?.coordinate
                                }
                            }

                        if let coord = selectedCoordinate {
                            VStack(alignment: .leading) {
                                Text("Lat: \(coord.latitude)")
                                Text("Lon: \(coord.longitude)")
                            }
                            .font(.caption)
                        }

                        Slider(value: $rangeMeters, in: 1...100, step: 1)
                        Text("\(Int(rangeMeters)) meters")
                    }
                }

                Section {
                    Button("Save Rule") {
                        let rule = LocationRule(
                            name: ruleName,
                            ruleType: ruleType,
                            coordinate: selectedCoordinate,
                            rangeMeters: rangeMeters
                        )
                        appData.addLocationRule(rule)
                        dismiss()
                    }
                    .disabled(ruleName.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Location Setup")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
            .environmentObject(AppData())
            .environmentObject(LocationManager())
            .environmentObject(BluetoothManager())
    }
}
