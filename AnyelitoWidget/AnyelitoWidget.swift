import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    typealias Entry = SimpleEntry

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), feedingActive: false, sleepActive: false, feedingStartTime: nil, sleepStartTime: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), feedingActive: false, sleepActive: false, feedingStartTime: nil, sleepStartTime: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        Task {
            let feedingActive = await SharedActivityManager.shared.isFeedingActive()
            let sleepActive = await SharedActivityManager.shared.isSleepActive()
            let feedingStartTime = await SharedActivityManager.shared.activeFeedingStartTime()
            let sleepStartTime = await SharedActivityManager.shared.activeSleepStartTime()
            
            let entry = SimpleEntry(date: Date(), feedingActive: feedingActive, sleepActive: sleepActive, feedingStartTime: feedingStartTime, sleepStartTime: sleepStartTime)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let feedingActive: Bool
    let sleepActive: Bool
    let feedingStartTime: Date?
    let sleepStartTime: Date?
}

struct AnyelitoWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 12) {
            Text("anyelito")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                // Control de Toma
                Button(intent: ToggleFeedingIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: entry.feedingActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                        if entry.feedingActive, let startTime = entry.feedingStartTime {
                            Text(startTime, style: .timer)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Toma")
                                .font(.caption2)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(entry.feedingActive ? Color.orange.opacity(0.2) : Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // Control de Sueño
                Button(intent: ToggleSleepIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: entry.sleepActive ? "moon.zzz.fill" : "moon.fill")
                            .font(.system(size: 24))
                        if entry.sleepActive, let startTime = entry.sleepStartTime {
                            Text(startTime, style: .timer)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Sueño")
                                .font(.caption2)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(entry.sleepActive ? Color.purple.opacity(0.2) : Color.indigo.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .containerBackground(
            LinearGradient(colors: [Color.white, Color(hex: "F0F4FF")], startPoint: .topLeading, endPoint: .bottomTrailing),
            for: .widget
        )
    }
}

// Extensión para Color desde Hex (necesaria aquí si no se hereda)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AnyelitoWidget: Widget {
    let kind: String = "AnyelitoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AnyelitoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("anyelito Control")
        .description("Controla las tomas y el sueño de tu bebé.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
