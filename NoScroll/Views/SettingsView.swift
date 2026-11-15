import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var newPasscode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var showPasscodeChange = false
    @State private var showEmergencyCode = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Block Settings")) {
                    Stepper("Max Extensions: \(appData.blockSettings.maxExtensions)", value: $appData.blockSettings.maxExtensions, in: 1...10)

                    Toggle("Use Grace Period", isOn: $appData.blockSettings.useGracePeriod)
                    if appData.blockSettings.useGracePeriod {
                        Stepper("Grace Period: \(appData.blockSettings.gracePeriodMinutes) min", value: $appData.blockSettings.gracePeriodMinutes, in: 1...10)
                    }
                }

                Section(header: Text("Security")) {
                    Button("Change Passcode") {
                        showPasscodeChange = true
                    }

                    Button("Show Emergency Code") {
                        showEmergencyCode = true
                    }

                    Toggle("Show Emergency QR", isOn: $appData.blockSettings.showEmergencyQR)
                }

                Section(header: Text("Monitored Apps")) {
                    ForEach($appData.monitoredApps) { $app in
                        Toggle(app.appName, isOn: $app.isActive)
                    }
                }

                Section {
                    Button("Reset All Data") {
                        // Reset functionality
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPasscodeChange) {
                VStack(spacing: 20) {
                    Text("Change Passcode")
                        .font(.title)
                        .padding()

                    SecureField("New Passcode", text: $newPasscode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .keyboardType(.numberPad)

                    SecureField("Confirm Passcode", text: $confirmPasscode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .keyboardType(.numberPad)

                    HStack(spacing: 20) {
                        Button("Cancel") {
                            showPasscodeChange = false
                            newPasscode = ""
                            confirmPasscode = ""
                        }
                        .padding()

                        Button("Save") {
                            if newPasscode == confirmPasscode && !newPasscode.isEmpty {
                                appData.blockSettings.passcode = newPasscode
                                showPasscodeChange = false
                                newPasscode = ""
                                confirmPasscode = ""
                            }
                        }
                        .padding()
                        .disabled(newPasscode != confirmPasscode || newPasscode.isEmpty)
                    }
                }
                .padding()
                .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showEmergencyCode) {
                VStack(spacing: 20) {
                    Text("Emergency Code")
                        .font(.title)
                        .padding()

                    Text(appData.emergencyCode)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)

                    Text("Show this code to unlock in emergencies")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()

                    Button("Close") {
                        showEmergencyCode = false
                    }
                    .padding()
                }
                .padding()
                .presentationDetents([.height(250)])
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppData())
    }
}
