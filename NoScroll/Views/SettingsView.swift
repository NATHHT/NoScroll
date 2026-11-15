import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var newPasscode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var currentPasscode: String = ""
    @State private var showPasscodeChange = false
    @State private var showEmergencyCode = false
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Blocking Settings")) {
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
                    Button {
                        showPasscodeChange = true
                    } label: {
                        HStack {
                            Text("Change Passcode")
                            Spacer()
                            Text(appData.blockSettings.passcode)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        showEmergencyCode = true
                    } label: {
                        Text("Show Emergency Code")
                    }

                    Toggle("Show Emergency QR", isOn: $appData.blockSettings.showEmergencyQR)
                }

                Section(header: Text("Monitored Apps")) {
                    ForEach($appData.monitoredApps) { $app in
                        NavigationLink {
                            AppSettingsView(app: $app)
                                .environmentObject(appData)
                        } label: {
                            HStack {
                                Image(systemName: app.iconName)
                                    .foregroundColor(.blue)
                                Text(app.appName)
                                Spacer()
                                Toggle("", isOn: $app.isActive)
                                    .labelsHidden()
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset All Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPasscodeChange) {
                PasscodeChangeView(
                    newPasscode: $newPasscode,
                    confirmPasscode: $confirmPasscode,
                    currentPasscode: $currentPasscode,
                    showPasscodeChange: $showPasscodeChange,
                    appData: appData
                )
            }
            .sheet(isPresented: $showEmergencyCode) {
                EmergencyCodeSheet(appData: appData)
            }
            .confirmationDialog(
                "Reset All Data",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all your sessions, rules, and settings. This cannot be undone.")
            }
        }
    }

    private func resetAllData() {
        appData.usageHistory.removeAll()
        appData.locationRules.removeAll()
        appData.blockSettings = BlockSettings()
        appData.isAppLocked = false
        appData.activeSession = nil
        appData.emergencyOverrideUsed = false
    }
}

struct AppSettingsView: View {
    @Binding var app: MonitoredApp
    @EnvironmentObject var appData: AppData
    @Environment(\dismiss) var dismiss

    @State private var customLimit: Int

    init(app: Binding<MonitoredApp>) {
        self._app = app
        self._customLimit = State(initialValue: app.wrappedValue.defaultLimit)
    }

    var body: some View {
        Form {
            Section(header: Text("App Settings")) {
                Toggle("Monitor This App", isOn: $app.isActive)

                Stepper(
                    "Time Limit: \(customLimit) minutes",
                    value: $customLimit,
                    in: 5...120
                )
            }

            Section {
                Button("Save") {
                    app.defaultLimit = customLimit
                    dismiss()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(app.appName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PasscodeChangeView: View {
    @Binding var newPasscode: String
    @Binding var confirmPasscode: String
    @Binding var currentPasscode: String
    @Binding var showPasscodeChange: Bool
    let appData: AppData

    @State private var step: PasscodeStep = .verifyCurrent

    enum PasscodeStep {
        case verifyCurrent
        case enterNew
        case confirmNew
    }

    var body: some View {
        VStack(spacing: 20) {
            switch step {
            case .verifyCurrent:
                VStack(spacing: 16) {
                    Text("Verify Current Passcode")
                        .font(.title2)
                        .fontWeight(.semibold)

                    SecureField("Current Passcode", text: $currentPasscode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    Button {
                        if currentPasscode == appData.blockSettings.passcode {
                            currentPasscode = ""
                            step = .enterNew
                        }
                    } label: {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentPasscode == appData.blockSettings.passcode ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(currentPasscode.isEmpty)
                }

            case .enterNew:
                VStack(spacing: 16) {
                    Text("Enter New Passcode")
                        .font(.title2)
                        .fontWeight(.semibold)

                    SecureField("New Passcode", text: $newPasscode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    Button {
                        step = .confirmNew
                    } label: {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(newPasscode.count >= 4 ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(newPasscode.count < 4)
                }

            case .confirmNew:
                VStack(spacing: 16) {
                    Text("Confirm New Passcode")
                        .font(.title2)
                        .fontWeight(.semibold)

                    SecureField("Confirm Passcode", text: $confirmPasscode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    Button {
                        if newPasscode == confirmPasscode {
                            appData.blockSettings.passcode = newPasscode
                            newPasscode = ""
                            confirmPasscode = ""
                            currentPasscode = ""
                            showPasscodeChange = false
                            step = .verifyCurrent
                        }
                    } label: {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(newPasscode == confirmPasscode && !confirmPasscode.isEmpty ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(newPasscode != confirmPasscode || confirmPasscode.isEmpty)
                }
            }

            Button("Cancel") {
                newPasscode = ""
                confirmPasscode = ""
                currentPasscode = ""
                showPasscodeChange = false
                step = .verifyCurrent
            }
            .foregroundColor(.red)
        }
        .padding()
        .presentationDetents([.height(300)])
    }
}

struct EmergencyCodeSheet: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)

                Text("Emergency Code")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Use this code to unlock if you forget your passcode")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Text(appData.emergencyCode)
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .onTapGesture {
                    UIPasteboard.general.string = appData.emergencyCode
                }

            Text("Tap to copy")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .presentationDetents([.height(300)])
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppData())
    }
}
