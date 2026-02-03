import SwiftUI
import SwiftData
import Combine

struct DashboardView: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @State private var showingFeedingSheet = false
    @State private var showingSleepSheet = false
    @State private var showingDiaperSheet = false
    @State private var showingMeasurementSheet = false
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                NebulaBackground()
                    .ignoresSafeArea()
                
                // Infant Decorations
                GeometryReader { geo in
                    ZStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 100))
                            .foregroundColor(Theme.primaryGreen.opacity(0.05))
                            .offset(x: geo.size.width * 0.7, y: geo.size.height * 0.1)
                        
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 120))
                            .foregroundColor(Theme.primaryGreen.opacity(0.03))
                            .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.4)
                        
                        Image(systemName: "teddybear.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Theme.primaryGreen.opacity(0.04))
                            .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.7)
                    }
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        
                        LiveAgeTrackerView()
                            .padding(.horizontal)
                        
                        quickActionsGrid
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Actividad Reciente")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal)
                            
                            timelineSection
                                .glassStyle()
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Cuidado Diario")
            .sheet(isPresented: $showingFeedingSheet) {
                FeedingSheet()
                    .environment(viewModel)
            }
            .sheet(isPresented: $showingDiaperSheet) {
                DiaperSheet()
                    .environment(viewModel)
            }
            .sheet(isPresented: $showingMeasurementSheet) {
                MeasurementSheet()
                    .environment(viewModel)
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                if let imageData = viewModel.profiles.first?.image, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.primaryGreen.opacity(0.5), lineWidth: 2))
                } else {
                    Circle()
                        .fill(.linearGradient(colors: [Theme.nebulaGreen, Theme.primaryGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
            }
            .shadow(color: Theme.primaryGreen.opacity(0.3), radius: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.profiles.first?.name ?? "Tu Bebé")
                    .font(.title3.bold())
                    .foregroundColor(Theme.starWhite)
                Text("Última toma: \(viewModel.lastFeeding)")
                    .font(.caption)
                    .foregroundColor(Theme.secondaryWhite)
            }
        }
        .padding(.horizontal)
    }
    
    private var quickActionsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            QuickActionButton(
                title: "Toma",
                icon: "drop.fill",
                gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                shape: .roundedRect(radius: 30)
            ) {
                showingFeedingSheet = true
            }
            
            SleepActionButton(showingManualSleep: $showingSleepSheet)
            
            QuickActionButton(
                title: "Pañal",
                icon: "toilet.fill",
                gradient: LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                shape: .pill
            ) {
                showingDiaperSheet = true
            }
            
            QuickActionButton(
                title: "Medición",
                icon: "ruler.fill",
                gradient: LinearGradient(colors: [Theme.primaryGreen, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
                shape: .roundedRect(radius: 12)
            ) {
                showingMeasurementSheet = true
            }
        }
        .padding(.horizontal)
    }
    
    private var timelineSection: some View {
        VStack(spacing: 0) {
            if viewModel.events.isEmpty {
                Text("Aún no hay registros")
                    .font(.subheadline)
                    .foregroundColor(Theme.tertiaryWhite)
                    .padding()
            } else {
                ForEach(viewModel.events.prefix(8)) { event in
                    TimelineRow(event: event)
                    if event.id != viewModel.events.prefix(8).last?.id {
                        Divider()
                            .background(Theme.glassBorder)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

enum ActionShape {
    case roundedRect(radius: CGFloat)
    case pill
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let shape: ActionShape
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    shapeView
                        .fill(gradient.opacity(0.12))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.title3.bold())
                        .foregroundStyle(gradient)
                }
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.secondaryWhite)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .glassStyle()
        }
    }
    
    private var shapeView: AnyShape {
        switch shape {
        case .roundedRect(let radius):
            AnyShape(RoundedRectangle(cornerRadius: radius))
        case .pill:
            AnyShape(Capsule())
        }
    }
}

struct SleepActionButton: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @Binding var showingManualSleep: Bool
    
    var body: some View {
        Button(action: { 
            withAnimation(.spring()) {
                viewModel.toggleSleep()
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(viewModel.activeSleepEvent != nil ? 
                              LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [Theme.nebulaGreen.opacity(0.3), Theme.primaryGreen.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: viewModel.activeSleepEvent != nil ? "stop.fill" : "moon.zzz.fill")
                        .font(.title3.bold())
                        .foregroundColor(viewModel.activeSleepEvent != nil ? .white : Theme.primaryGreen)
                }
                
                if viewModel.activeSleepEvent != nil {
                    Text(timeString(from: viewModel.sleepDuration))
                        .font(.system(.subheadline, design: .monospaced).bold())
                        .foregroundColor(Theme.starWhite)
                } else {
                    Text("Sueño")
                        .font(.subheadline.bold())
                        .foregroundColor(Theme.secondaryWhite)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .glassStyle()
        }
        .contextMenu {
            Button {
                showingManualSleep = true
            } label: {
                Label("Registro Posterior", systemImage: "clock.arrow.circlepath")
            }
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct TimelineRow: View {
    let event: TrackerEvent
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(event.eventType.iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: event.eventType.icon)
                    .font(.caption.bold())
                    .foregroundColor(event.eventType.iconColor)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(event.eventType.rawValue)
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.starWhite)
                
                HStack(spacing: 4) {
                    if let subType = event.subType {
                        Text(subType)
                            .font(.caption2)
                            .foregroundColor(Theme.secondaryWhite)
                    }
                    
                    if let duration = event.durationString {
                        Text("• \(duration)")
                            .font(.caption2)
                            .foregroundColor(Theme.primaryGreen)
                    }
                }
            }
            
            Spacer()
            
            Text(event.startTime, style: .time)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.tertiaryWhite)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
        }
    }
}

struct LiveAgeTrackerView: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date
            VStack(alignment: .leading, spacing: 8) {
                if let birthDate = viewModel.profiles.first?.birthDate {
                    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: birthDate, to: now)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Edad")
                                .font(.caption2.bold())
                                .foregroundColor(Theme.tertiaryWhite)
                                .textCase(.uppercase)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                if let year = components.year, year > 0 {
                                    AgeValueView(value: year, unit: "a")
                                }
                                if let month = components.month, month > 0 || (components.year ?? 0) > 0 {
                                    AgeValueView(value: month, unit: "m")
                                }
                                if let day = components.day, day > 0 || (components.month ?? 0) > 0 {
                                    AgeValueView(value: day, unit: "d")
                                }
                                
                                AgeValueView(value: components.hour ?? 0, unit: "h")
                                AgeValueView(value: components.minute ?? 0, unit: "min")
                                
                                Text("\(components.second ?? 0)s")
                                    .font(.system(.subheadline, design: .monospaced).bold())
                                    .foregroundColor(Theme.primaryGreen)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "clock.badge.checkmark.fill")
                            .foregroundColor(Theme.primaryGreen)
                            .font(.subheadline)
                    }
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.glassBorder)
                            .frame(height: 4)
                        
                        GeometryReader { geo in
                            let seconds = Double(components.second ?? 0)
                            let nanos = Double(components.nanosecond ?? 0) / 1_000_000_000.0
                            let totalSeconds = seconds + nanos
                            let progress = min(totalSeconds / 60.0, 1.0)
                            
                            Capsule()
                                .fill(LinearGradient(colors: [Theme.nebulaGreen, Theme.primaryGreen], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * progress)
                                .shadow(color: Theme.primaryGreen.opacity(0.3), radius: 2)
                        }
                    }
                    .frame(height: 4)
                    .clipShape(Capsule())
                } else {
                    Text("Configura el perfil en ajustes")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryWhite)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(12)
            .glassStyle()
            .frame(maxWidth: .infinity)
        }
    }
}

struct AgeValueView: View {
    let value: Int
    let unit: String
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text("\(value)")
                .font(.system(.subheadline, design: .monospaced).bold())
                .foregroundColor(Theme.starWhite)
            Text(unit)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.secondaryWhite)
        }
    }
}

extension EventType {
    var iconColor: Color {
        switch self {
        case .feeding: return .blue
        case .sleep: return .purple
        case .diaper: return .orange
        case .measurement: return Theme.primaryGreen
        case .vaccine: return .red
        case .doctorVisit: return .cyan
        }
    }
}

extension TrackerEvent {
    var durationString: String? {
        guard let endTime = endTime else { return nil }
        let interval = endTime.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}
