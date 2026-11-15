import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showingSessionStart = false
    @State private var selectedApp: MonitoredApp?
    @State private var showingLockedAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if appData.isAppLocked {
                        LockedView()
                            .padding()
                    } else if let session = appData.activeSession {
                        ActiveSessionCard(session: session)
                            .padding(.horizontal)
                    }

                    if !appData.isAppLocked {
                        Text("Select an app to start monitoring")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top)

                        AppGridView(selectedApp: $selectedApp, showingSessionStart: $showingSessionStart)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("NoScroll")
            .sheet(item: $selectedApp) { app in
                SessionStartView(app: app, isPresented: Binding(
                    get: { true },
                    set: { _ in selectedApp = nil }
                ))
                .environmentObject(appData)
            }
            .onChange(of: appData.isAppLocked) { isLocked in
                if isLocked {
                    showingLockedAlert = true
                }
            }
        }
    }
}

struct ActiveSessionCard: View {
    @EnvironmentObject var appData: AppData
    let session: DoomscrollSession

    @State private var showExtendAlert = false

    var timeRemaining: Int {
        session.app.defaultLimit - session.elapsedMinutes
    }

    var progress: Double {
        min(Double(session.elapsedMinutes) / Double(session.app.defaultLimit), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: session.app.iconName)
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.blue)
                            .cornerRadius(10)
                        
                        Text(session.app.appName)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Text(session.purpose.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(session.elapsedMinutes) min")
                        .font(.headline)
                    if session.isOverLimit {
                        Text("OVER LIMIT")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    } else {
                        Text("\(timeRemaining) min left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            ProgressView(value: progress, total: 1.0)
                .tint(session.isOverLimit ? .red : .blue)

            HStack(spacing: 12) {
                Button {
                    appData.extendSession()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Extend")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(session.extensionCount >= appData.blockSettings.maxExtensions)

                Button {
                    appData.endSession()
                } label: {
                    HStack {
                        Image(systemName: "xmark")
                        Text("End")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct AppGridView: View {
    @Binding var selectedApp: MonitoredApp?
    @Binding var showingSessionStart: Bool

    @EnvironmentObject var appData: AppData

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(appData.monitoredApps.filter { $0.isActive }) { app in
                AppIconButton(app: app, selectedApp: $selectedApp)
            }
        }
    }
}

struct AppIconButton: View {
    let app: MonitoredApp
    @Binding var selectedApp: MonitoredApp?

    var body: some View {
        Button {
            selectedApp = app
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: app.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                
                Text(app.appName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
    }
}

struct SessionStartView: View {
    let app: MonitoredApp
    @Binding var isPresented: Bool
    @EnvironmentObject var appData: AppData
    @State private var selectedPurpose: SessionPurpose = .browsing

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: app.iconName)
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                    }
                    
                    Text(app.appName)
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Time limit: \(app.defaultLimit) minutes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("What's your purpose?")
                        .font(.headline)

                    Picker("Purpose", selection: $selectedPurpose) {
                        Text("Socializing").tag(SessionPurpose.socializing)
                        Text("Browsing").tag(SessionPurpose.browsing)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Text("Choose 'Socializing' for conversations, 'Browsing' for casual scrolling")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                Spacer()

                Button {
                    appData.startSession(for: app, purpose: selectedPurpose)
                    isPresented = false
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Session")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
                }
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Start Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct LockedView: View {
    @EnvironmentObject var appData: AppData
    @State private var passcode: String = ""
    @State private var showEmergency = false

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding()

                Text("App Locked")
                    .font(.title)
                    .fontWeight(.bold)

                Text("You've exceeded your time limit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                SecureField("Enter passcode", text: $passcode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .keyboardType(.numberPad)
                    .frame(height: 50)

                Button {
                    if appData.unlockApp(with: passcode) {
                        passcode = ""
                    }
                } label: {
                    Text("Unlock")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(passcode.isEmpty)

                Button {
                    showEmergency = true
                } label: {
                    Text("Emergency Override")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showEmergency) {
            EmergencyCodeView()
                .environmentObject(appData)
                .presentationDetents([.height(250)])
        }
    }
}

struct EmergencyCodeView: View {
    @EnvironmentObject var appData: AppData
    @State private var code: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Emergency Code")
                .font(.title)
                .fontWeight(.bold)

            Text(appData.emergencyCode)
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            SecureField("Enter emergency code", text: $code)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.asciiCapable)

            Button {
                if appData.emergencyUnlock(with: code) {
                    code = ""
                }
            } label: {
                Text("Unlock")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(code == appData.emergencyCode ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(code.isEmpty)
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
