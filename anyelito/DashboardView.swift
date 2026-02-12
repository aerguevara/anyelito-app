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
                
                FloatingDecorations()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        unifiedProfileHeader
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
    
    private var unifiedProfileHeader: some View {
        VStack(spacing: 0) {
            // Top Part: Avatar and Name
            HStack(spacing: 16) {
                ZStack {
                    if let imageData = viewModel.profiles.first?.image, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.primaryGreen.opacity(0.5), lineWidth: 1.5))
                    } else {
                        Circle()
                            .fill(.linearGradient(colors: [Theme.nebulaGreen, Theme.primaryGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: Theme.primaryGreen.opacity(0.2), radius: 6)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.profiles.first?.name ?? "Tu Bebé")
                        .font(.headline.bold())
                        .foregroundColor(Theme.starWhite)
                    Text("Última toma: \(viewModel.lastFeeding)")
                        .font(.caption2)
                        .foregroundColor(Theme.secondaryWhite)
                }
                
                Spacer()
                
                Image(systemName: "clock.badge.checkmark.fill")
                    .foregroundColor(Theme.primaryGreen.opacity(0.8))
                    .font(.caption)
            }
            .padding(.bottom, 12)
            
            Divider()
                .background(Theme.glassBorder)
                .padding(.bottom, 12)
            
            // Bottom Part: Age Tracker
            TimelineView(.animation) { timeline in
                let now = timeline.date
                if let birthDate = viewModel.profiles.first?.birthDate {
                    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: birthDate, to: now)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Text("Edad")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.tertiaryWhite)
                                .textCase(.uppercase)
                            Image(systemName: "sparkles")
                                .font(.system(size: 8))
                                .foregroundColor(Theme.primaryGreen.opacity(0.6))
                        }
                        
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
                                .font(.system(.caption2, design: .monospaced).bold())
                                .foregroundColor(Theme.primaryGreen)
                        }
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.glassBorder)
                                .frame(height: 3)
                            
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
                        .frame(height: 3)
                        .clipShape(Capsule())
                    }
                } else {
                    Text("Configura el perfil en ajustes")
                        .font(.caption2)
                        .foregroundColor(Theme.tertiaryWhite)
                }
            }
        }
        .padding(12)
        .glassStyle()
    }
    
    private var quickActionsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            QuickActionButton(
                title: "Toma",
                icon: "drop.fill",
                gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                animal: .bear
            ) {
                showingFeedingSheet = true
            }
            
            SleepActionButton(showingManualSleep: $showingSleepSheet)
            
            QuickActionButton(
                title: "Pañal",
                icon: "toilet.fill",
                gradient: LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                animal: .cat
            ) {
                showingDiaperSheet = true
            }
            
            QuickActionButton(
                title: "Medición",
                icon: "ruler.fill",
                gradient: LinearGradient(colors: [Theme.primaryGreen, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
                animal: .bird
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

struct SquishyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

enum AnimalType {
    case bear, rabbit, cat, bird
    
    var symbol: String {
        switch self {
        case .bear: return "teddybear.fill"
        case .rabbit: return "rabbit.fill"
        case .cat: return "cat.fill"
        case .bird: return "bird.fill"
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String // Main action icon
    let gradient: LinearGradient
    let animal: AnimalType // Used for the background 'stamp'
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    // Soft background animal silhouette
                    Image(systemName: animal.symbol)
                        .font(.system(size: 40))
                        .foregroundStyle(gradient.opacity(0.12))
                    
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
        .buttonStyle(SquishyButtonStyle())
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
                    let isPressed = viewModel.activeSleepEvent != nil
                    
                    // Background rabbit stamp
                    Image(systemName: AnimalType.rabbit.symbol)
                        .font(.system(size: 40))
                        .foregroundStyle(isPressed ? Color.purple.opacity(0.2) : Theme.primaryGreen.opacity(0.12))
                    
                    Image(systemName: isPressed ? "stop.fill" : "moon.zzz.fill")
                        .font(.title3.bold())
                        .foregroundColor(isPressed ? .white : Theme.primaryGreen)
                }
                
                if viewModel.activeSleepEvent != nil {
                    Text(timeString(from: viewModel.sleepDuration))
                        .font(.system(.caption, design: .monospaced).bold())
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
        .buttonStyle(SquishyButtonStyle())
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
    @Environment(BabyTrackerViewModel.self) private var viewModel
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
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteEvent(event)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
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

struct FloatingDecorations: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background animals and icons
                FloatingIcon(name: "cloud.fill", size: 100, color: SwiftUI.Color.white.opacity(0.04), offset: animate ? (geo.size.width * 0.1) : (geo.size.width * 0.2), y: geo.size.height * 0.15)
                FloatingIcon(name: "sparkles", size: 60, color: Theme.nebulaMint.opacity(0.1), offset: animate ? (geo.size.width * 0.8) : (geo.size.width * 0.7), y: geo.size.height * 0.05)
                FloatingIcon(name: "teddybear.fill", size: 50, color: Theme.primaryGreen.opacity(0.06), offset: animate ? (geo.size.width * 0.3) : (geo.size.width * 0.2), y: geo.size.height * 0.45)
                FloatingIcon(name: "balloon.fill", size: 40, color: .orange.opacity(0.04), offset: animate ? (geo.size.width * 0.7) : (geo.size.width * 0.8), y: geo.size.height * 0.75)
                FloatingIcon(name: "pawprint.fill", size: 30, color: .yellow.opacity(0.03), offset: animate ? (geo.size.width * 0.9) : (geo.size.width * 0.8), y: geo.size.height * 0.25)
                FloatingIcon(name: "heart.fill", size: 25, color: .pink.opacity(0.05), offset: animate ? (geo.size.width * 0.1) : (geo.size.width * 0.05), y: geo.size.height * 0.65)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

struct FloatingIcon: View {
    let name: String
    let size: CGFloat
    let color: SwiftUI.Color
    let offset: CGFloat
    let y: CGFloat
    
    var body: some View {
        Image(systemName: name)
            .font(.system(size: size))
            .foregroundColor(color)
            .position(x: offset, y: y)
    }
}

