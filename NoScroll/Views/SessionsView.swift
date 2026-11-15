import SwiftUI

struct SessionsView: View {
    @EnvironmentObject var appData: AppData

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Recent Sessions")) {
                    if appData.usageHistory.isEmpty {
                        Text("No sessions recorded yet")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(appData.usageHistory.sorted(by: { $0.timestamp > $1.timestamp }).prefix(20)) { record in
                            SessionRow(record: record)
                        }
                    }
                }

                Section(header: Text("Statistics")) {
                    StatisticsView()
                }
            }
            .navigationTitle("Sessions")
        }
    }
}

struct SessionRow: View {
    let record: UsageRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: record.app.iconName)
                        .foregroundColor(.blue)
                    Text(record.app.appName)
                        .font(.headline)
                }
                Text(record.purpose.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if let duration = record.duration {
                    Text("\(Int(duration)) minutes")
                        .font(.caption)
                }
            }
            Spacer()
            Text(record.timestamp.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct StatisticsView: View {
    @EnvironmentObject var appData: AppData

    var totalSessions: Int {
        appData.usageHistory.count
    }

    var doomscrollingSessions: Int {
        appData.usageHistory.filter { $0.purpose == .doomscrolling }.count
    }

    var totalTime: Int {
        Int(appData.usageHistory.compactMap { $0.duration }.reduce(0, +))
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                StatCard(value: "\(totalSessions)", label: "Total Sessions")
                Spacer()
                StatCard(value: "\(doomscrollingSessions)", label: "Doomscrolling")
            }
            HStack {
                StatCard(value: "\(totalTime) min", label: "Total Time")
                Spacer()
                StatCard(value: appData.isAppLocked ? "Yes" : "No", label: "Currently Locked")
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SessionsView_Previews: PreviewProvider {
    static var previews: some View {
        SessionsView()
            .environmentObject(AppData())
    }
}
