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
        print("🏷️ [Widget] getTimeline invocado")
        Task {
            // Sincronizar desde la nube antes de cargar la entrada
            await SharedActivityManager.shared.syncFromCloud(isWidget: true)
            
            let feedingActive = await SharedActivityManager.shared.isFeedingActive()
            let sleepActive = await SharedActivityManager.shared.isSleepActive()
            let feedingStartTime = await SharedActivityManager.shared.activeFeedingStartTime()
            let sleepStartTime = await SharedActivityManager.shared.activeSleepStartTime()
            
            print("🏷️ [Widget] Datos obtenidos - Feeding: \(feedingActive), Sleep: \(sleepActive)")
            
            let entry = SimpleEntry(date: Date(), feedingActive: feedingActive, sleepActive: sleepActive, feedingStartTime: feedingStartTime, sleepStartTime: sleepStartTime)
            
            // Actualizar cada 15 minutos para asegurar sincronización remota
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
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
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("anyelito")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .white.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Spacer()
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                // Control de Toma (Feeding)
                WidgetButton(
                    intent: ToggleFeedingIntent(),
                    isActive: entry.feedingActive,
                    startTime: entry.feedingStartTime,
                    label: "Toma",
                    icon: "drop.fill",
                    activeColors: [Color(hex: "FF9500"), Color(hex: "FFCC00")]
                )
                
                // Control de Sueño (Sleep)
                WidgetButton(
                    intent: ToggleSleepIntent(),
                    isActive: entry.sleepActive,
                    startTime: entry.sleepStartTime,
                    label: "Sueño",
                    icon: "moon.zzz.fill",
                    activeColors: [Color(hex: "5856D6"), Color(hex: "AF52DE")]
                )
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            ZStack {
                // Color exacto Theme.deepSpace
                Color(hex: "08120A")
                
                // Efecto Nebulosa (Theme.nebulaGreen y Theme.primaryGreen)
                RadialGradient(
                    colors: [Color(hex: "064E3B").opacity(0.7), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 200
                )
                
                RadialGradient(
                    colors: [Color(hex: "34D399").opacity(0.15), .clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 250
                )
            }
        }
    }
}

// MARK: - Premium Button Component
struct WidgetButton: View {
    let intent: any AppIntent
    let isActive: Bool
    let startTime: Date?
    let label: String
    let icon: String
    let activeColors: [Color]
    
    var body: some View {
        Button(intent: intent) {
            VStack(spacing: 6) {
                // Icon Container
                ZStack {
                    if isActive {
                        Circle()
                            .fill(
                                LinearGradient(colors: activeColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .blur(radius: 8)
                            .opacity(0.5)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            isActive ? 
                            AnyGradient(gradient: LinearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .top, endPoint: .bottom)) :
                            AnyGradient(gradient: LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        )
                        .symbolEffect(.bounce, value: isActive)
                }
                .frame(height: 32)
                
                VStack(spacing: 1) {
                    if isActive, let startTime = startTime {
                        Text(startTime, style: .timer)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(isActive ? 1.0 : 0.4))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    // Glass effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(isActive ? 0.15 : 0.05))
                    
                    // Glossy border
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(isActive ? 0.4 : 0.1),
                                    .clear,
                                    .white.opacity(isActive ? 0.1 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// Helper to handle any gradient (compatibility)
struct AnyGradient: ShapeStyle {
    let gradient: LinearGradient
    func resolve(in proxy: EnvironmentValues) -> LinearGradient {
        gradient
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
