import SwiftUI

struct SessionsView: View {
    @EnvironmentObject var appData: AppData

    var recentSessions: [UsageRecord] {
        appData.usageHistory.sorted(by: { $0.timestamp > $1.timestamp })
    }

    var doomscrollingSessions: [UsageRecord] {
        recentSessions.filter { $0.purpose == .doomscrolling }
    }

    var socializingSessions: [UsageRecord] {
        recentSessions.filter { $0.purpose == .socializing }
    }

    var browsingSessions: [UsageRecord] {
        recentSessions.filter { $0.purpose == .browsing }
    }

    var totalTime: Int {
        Int(recentSessions.compactMap { $0.duration }.reduce(0, +))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatisticsSummaryView(
                        totalSessions: recentSessions.count,
                        doomscrollingCount: doomscrollingSessions.count,
                        totalTime: totalTime
                    )
                    .padding(.horizontal)

                    if recentSessions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("No sessions yet")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Start a session to track your usage")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    } else {
                        SessionListView(sessions: recentSessions)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Sessions")
        }
    }
}

struct StatisticsSummaryView: View {
    let totalSessions: Int
    let doomscrollingCount: Int
    let totalTime: Int

    var doomscrollingPercentage: Double {
        totalSessions > 0 ? Double(doomscrollingCount) / Double(totalSessions) : 0
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(value: "\(totalSessions)", label: "Total", icon: "calendar")
                Spacer()
                StatCard(value: "\(doomscrollingCount)", label: "Doomscroll", icon: "exclamationmark.triangle")
                Spacer()
                StatCard(value: "\(totalTime)h", label: "Total Time", icon: "clock")
            }

            ProgressView(value: doomscrollingPercentage, total: 1.0)
                .tint(doomscrollingPercentage > 0.5 ? .red : doomscrollingPercentage > 0.25 ? .orange : .green)
                .overlay(
                    Text("\(Int(doomscrollingPercentage * 100))% doomscrolling")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(4)
                        .padding(.horizontal, 8)
                )
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SessionListView: View {
    let sessions: [UsageRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)

            ForEach(sessions.prefix(50)) { record in
                SessionRow(record: record)
                    .padding(.horizontal)
            }
        }
    }
}

struct SessionRow: View {
    let record: UsageRecord

    var purposeColor: Color {
        switch record.purpose {
        case .socializing: return .green
        case .browsing: return .blue
        case .doomscrolling: return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: record.app.iconName)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .cornerRadius(8)
                    
                    Text(record.app.appName)
                        .font(.headline)
                }

                HStack {
                    Text(record.purpose.rawValue)
                        .font(.subheadline)
                        .foregroundColor(purposeColor)
                    
                    if let duration = record.duration {
                        Text("• \(Int(duration)) min")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SessionsView_Previews: PreviewProvider {
    static var previews: some View {
        SessionsView()
            .environmentObject(AppData())
    }
}
