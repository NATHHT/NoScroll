import SwiftUI
import CoreLocation

struct SetupView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\dismiss) var dismiss

    @State private var selectedTab: SetupTab = .appSelection

    enum SetupTab {
        case appSelection
        case locationSetup
        case settings
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                AppSelectionView(selectedTab: $selectedTab)
                    .tag(SetupTab.appSelection)
                    .tabItem {
                        Label("Apps", systemImage: "apps.iphone")
                    }

                LocationSetupView(selectedTab: $selectedTab)
                    .tag(SetupTab.locationSetup)
                    .tabItem {
                        Label("Locations", systemImage: "mappin.and.ellipse")
                    }

                InitialSettingsView(selectedTab: $selectedTab)
                    .tag(SetupTab.settings)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AppSelectionView: View {
    @Binding var selectedTab: SetupView.SetupTab
    @EnvironmentObject var appData: AppData

    var body: some View {
        List {
            Section(header: Text("Monitored Apps")) {
                ForEach($appData.monitoredApps) { $app in
                    Toggle(app.appName, isOn: $app.isActive)
                }
            }

            Section {
                NavigationLink {
                    AddCustomAppView()
                        .environmentObject(appData)
                } label: {
                    Text("Add Custom App")
                }
            }
        }
    }
}

struct AddCustomAppView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\dismiss) var dismiss

    @State private var appName = ""
    @State private var bundleID = ""
    @State private var defaultLimit = 15
    @State private var iconName = "app"

    var availableIcons = ["camera", "music.note", "bubble", "play.tv", "text.bubble", "app", "network", "photo"]

    var body: some View {
        Form {
            Section(header: Text("App Details")) {
                TextField("App Name", text: $appName)
                TextField("Bundle ID", text: $bundleID)
                Stepper("Default Limit: \(defaultLimit) min", value: $defaultLimit, in: 5...120)
            }

            Section(header: Text("Icon")) {
                Picker("Icon", selection: $iconName) {
                    ForEach(availableIcons, id: \.self) { icon in
                        HStack {
                            Image(systemName: icon)
                            Text(icon)
                        }
                        .tag(icon)
                    }
                }
            }

            Section {
                Button("Add App") {
                    appData.monitoredApps.append(MonitoredApp(
                        appName: appName,
                        bundleID: bundleID,
                        defaultLimit: defaultLimit,
                        iconName: iconName,
                        isActive: true
                    ))
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .disabled(appName.isEmpty || bundleID.isEmpty)
            }
        }
        .navigationTitle("Add Custom App")
    }
}

struct LocationSetupView: View {
    @Binding var selectedTab: SetupView.SetupTab
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager

    @State private var showingAddGPS = false
    @State private var showingAddBluetooth = false

    var body: some View {
        List {
            Section(header: Text("GPS Rules")) {
                ForEach(appData.locationRules.filter { $0.ruleType == .gps }) { rule in
                    LocationRuleRow(rule: rule, appData: appData)
                }
                .onDelete { indexSet in
                    let gpsRules = appData.locationRules.filter { $0.ruleType == .gps }
                    let indices = indexSet.map { gpsRules[$0].id }
                    for id in indices {
                        if let index = appData.locationRules.firstIndex(where: { $0.id == id }) {
                            appData.locationRules.remove(at: index)
                        }
                    }
                }

                Button {
                    showingAddGPS = true
                } label: {
                    Text("Add GPS Rule")
                }
            }

            Section(header: Text("Bluetooth Rules")) {
                ForEach(appData.locationRules.filter { $0.ruleType == .bluetooth }) { rule in
                    LocationRuleRow(rule: rule, appData: appData)
                }
                .onDelete { indexSet in
                    let btRules = appData.locationRules.filter { $0.ruleType == .bluetooth }
                    let indices = indexSet.map { btRules[$0].id }
                    for id in indices {
                        if let index = appData.locationRules.firstIndex(where: { $0.id == id }) {
                            appData.locationRules.remove(at: index)
                        }
                    }
                }

                Button {
                    showingAddBluetooth = true
                } label: {
                    Text("Add Bluetooth Rule")
                }
            }
        }
        .sheet(isPresented: $showingAddGPS) {
            AddGPSRuleView()
                .environmentObject(appData)
                .environmentObject(locationManager)
        }
        .sheet(isPresented: $showingAddBluetooth) {
            BluetoothScanView()
                .environmentObject(appData)
                .environmentObject(BluetoothManager())
        }
    }
}

struct InitialSettingsView: View {
    @Binding var selectedTab: SetupView.SetupTab
    @EnvironmentObject var appData: AppData

    var body: some View {
        Form {
            Section(header: Text("Default Settings")) {
                Stepper(
                    "Max Extensions: \(appData.blockSettings.maxExtensions)",
                    value: $appData.blockSettings.maxExtensions,
                    in: 1...10
                )

                Toggle("Use Grace Period", isOn: $appData.blockSettings.useGracePeriod)

                if appData.blockSettings.useGracePeriod {
                    Stepper(
                        "Grace Period: \(appData.blockSettings.gracePeriodMinutes) min",
                        value: $appData.blockSettings.gracePeriodMinutes,
                        in: 1...10
                    )
                }
            }

            Section(header: Text("Security")) {
                NavigationLink {
                    PasscodeSetupView()
                        .environmentObject(appData)
                } label: {
                    Text("Set Passcode")
                }

                Toggle("Show Emergency QR", isOn: $appData.blockSettings.showEmergencyQR)
            }
        }
        .navigationTitle("Initial Settings")
    }
}

struct PasscodeSetupView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\dismiss) var dismiss

    @State private var passcode: String = ""
    @State private var confirmPasscode: String = ""

    var body: some View {
        Form {
            Section(header: Text("Set Passcode")) {
                SecureField("Enter Passcode", text: $passcode)
                    .keyboardType(.numberPad)
                SecureField("Confirm Passcode", text: $confirmPasscode)
                    .keyboardType(.numberPad)
            }

            Section {
                Button("Save") {
                    if passcode == confirmPasscode && passcode.count >= 4 {
                        appData.blockSettings.passcode = passcode
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(passcode != confirmPasscode || passcode.count < 4)
            }
        }
        .navigationTitle("Set Passcode")
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
