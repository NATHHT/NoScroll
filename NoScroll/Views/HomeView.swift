import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if appData.isAppLocked {
                    LockedView()
                } else if let session = appData.activeSession {
                    ActiveSessionView(session: session)
                } else {
                    AppGridView()
                }
            }
            .navigationTitle("NoScroll")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SetupView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct ActiveSessionView: View {
    @EnvironmentObject var appData: AppData
    let session: DoomscrollSession

    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Image(systemName: session.app.iconName)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text(session.app.appName)
                    .font(.title)
                Text("Purpose: \(session.purpose.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            VStack(spacing: 10) {
                Text("Time Elapsed")
                    .font(.headline)
                Text("\(session.elapsedMinutes) minutes")
                    .font(.title)
                    .fontWeight(.bold)

                if session.isOverLimit {
                    Text("Time limit exceeded!")
                        .foregroundColor(.red)
                        .font(.headline)
                }

                Text("Extensions: \(session.extensionCount)/\(appData.blockSettings.maxExtensions)")
                    .font(.subheadline)
            }

            HStack(spacing: 20) {
                Button("Extend") {
                    appData.extendSession()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("End Session") {
                    appData.endSession()
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct AppGridView: View {
    @EnvironmentObject var appData: AppData

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(appData.monitoredApps.filter { $0.isActive }) { app in
                    AppIconView(app: app)
                }
            }
            .padding()
        }
    }
}

struct AppIconView: View {
    @EnvironmentObject var appData: AppData
    let app: MonitoredApp

    var body: some View {
        VStack(spacing: 8) {
            Button {
                showPurposeAlert(app: app)
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: app.iconName)
                        .font(.system(size: 40))
                        .frame(width: 80, height: 80)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(16)
                    Text(app.appName)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func showPurposeAlert(app: MonitoredApp) {
        // This would trigger a session start with purpose selection
        // Implementation depends on how you want to handle the UI flow
    }
}

struct LockedView: View {
    @EnvironmentObject var appData: AppData
    @State private var passcode: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("App Locked")
                .font(.title)
                .fontWeight(.bold)

            Text("Enter passcode to unlock")
                .font(.subheadline)
                .foregroundColor(.gray)

            SecureField("Passcode", text: $passcode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .frame(width: 200)
                .keyboardType(.numberPad)

            Button("Unlock") {
                if appData.unlockApp(with: passcode) {
                    passcode = ""
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Text("Emergency Override")
                .font(.caption)
                .foregroundColor(.gray)
                .onTapGesture {
                    // Show emergency QR code
                }
        }
        .padding()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppData())
            .environmentObject(LocationManager())
            .environmentObject(BluetoothManager())
    }
}
