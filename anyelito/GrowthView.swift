import SwiftUI
import Charts
import SwiftData

struct GrowthView: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @State private var selectedMetric: MetricType = .weight
    
    enum MetricType: String, CaseIterable {
        case weight = "Peso (kg)"
        case height = "Altura (cm)"
        case head = "Perímetro (cm)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                NebulaBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Picker("Métrica", selection: $selectedMetric) {
                            ForEach(MetricType.allCases, id: \.self) { metric in
                                Text(metric.rawValue).tag(metric)
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        chartSection
                            .glassStyle()
                            .padding(.horizontal)
                        
                        chartExplanationCard
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Historial")
                                .font(.headline)
                                .foregroundColor(Theme.starWhite)
                                .padding(.horizontal)
                            
                            measurementList
                                .glassStyle()
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Crecimiento")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    private var chartSection: some View {
        Chart {
            // 1. Shaded area: Normal Development Range (P3 to P97)
            ForEach(currentWHOData) { data in
                AreaMark(
                    x: .value("Mes", Double(data.month)),
                    yStart: .value("P3", data.p3),
                    yEnd: .value("P97", data.p97)
                )
                .foregroundStyle(Theme.primaryGreen.opacity(0.15))
                .interpolationMethod(.catmullRom)
            }
            
            // 2. WHO Median (P50): Global Average
            ForEach(currentWHOData) { data in
                LineMark(
                    x: .value("Mes", Double(data.month)),
                    y: .value("P50", data.p50),
                    series: .value("WHO", "Median")
                )
                .foregroundStyle(Color.white.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [5, 5]))
                .interpolationMethod(.catmullRom)
            }
            
            // 3. User Baby Data: Cyan Solid Line
            let babyPoints = userMeasurementsForChart
            ForEach(babyPoints) { dataPoint in
                LineMark(
                    x: .value("Mes", dataPoint.month),
                    y: .value("Valor", dataPoint.value),
                    series: .value("Baby", "User")
                )
                .foregroundStyle(Color.cyan)
                .lineStyle(StrokeStyle(lineWidth: 1.8)) // Even thinner for "finesa" (was 3)
                .interpolationMethod(.catmullRom)
            }
            
            // Distinct points on top
            ForEach(babyPoints) { dataPoint in
                PointMark(
                    x: .value("Mes", dataPoint.month),
                    y: .value("Valor", dataPoint.value)
                )
                .foregroundStyle(dataPoint.month == 0 ? .white : Color.cyan.opacity(0.8))
                .symbolSize(dataPoint.month == 0 ? 60 : 20)
            }
        }
        .frame(height: 250)
        .chartXScale(domain: chartXScaleDomain)
        .clipped() // Ensure no overflow beyond the plot area
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine().foregroundStyle(Theme.tertiaryWhite)
                AxisValueLabel {
                    if let month = value.as(Double.self) {
                        Text("\(Int(month))m")
                            .foregroundColor(Theme.secondaryWhite)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine().foregroundStyle(Theme.tertiaryWhite)
                AxisValueLabel().foregroundStyle(Theme.secondaryWhite)
            }
        }
    }
    
    private var chartExplanationCard: some View {
        let babyName = viewModel.profiles.first?.name ?? "tu bebé"
        let hasEnoughPoints = userMeasurementsForChart.count >= 2
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.cyan)
                Text("Entendiendo la gráfica")
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.starWhite)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                // User Baby
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.cyan)
                            .frame(width: 20, height: 4)
                        Text("Evolución de \(babyName)")
                            .font(.caption2.bold())
                            .foregroundColor(Theme.starWhite)
                    }
                    if !hasEnoughPoints {
                        Text("(Añade una segunda medición para ver la línea)")
                            .font(.system(size: 8))
                            .foregroundColor(Theme.tertiaryWhite)
                            .padding(.leading, 28)
                    }
                }
                
                // WHO Average
                HStack(spacing: 8) {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 5))
                        path.addLine(to: CGPoint(x: 20, y: 5))
                    }
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(width: 20, height: 10)
                    Text("Media mundial (Percentil 50)")
                        .font(.caption2)
                        .foregroundColor(Theme.secondaryWhite)
                }
                
                // Normal Range
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.primaryGreen.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.primaryGreen.opacity(0.2), lineWidth: 0.5))
                        .frame(width: 20, height: 10)
                    Text("Franja de desarrollo normal (P3-P97)")
                        .font(.caption2)
                        .foregroundColor(Theme.secondaryWhite)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassStyle()
    }
    
    private var measurementList: some View {
        VStack(spacing: 0) {
            let sortedEvents = userMeasurementsForList
            
            if sortedEvents.isEmpty {
                Text("No hay mediciones registradas")
                    .font(.caption)
                    .foregroundColor(Theme.tertiaryWhite)
                    .padding()
            } else {
                ForEach(sortedEvents) { event in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.startTime, style: .date)
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.starWhite)
                            Text(event.startTime, style: .time)
                                .font(.caption2)
                                .foregroundColor(Theme.tertiaryWhite)
                        }
                        
                        Spacer()
                        
                        Text(event.value?.formattedSpanish(decimals: selectedMetric == .weight ? 2 : 1) ?? "0")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(Theme.primaryGreen)
                        
                        Text(selectedMetric == .weight ? "kg" : "cm")
                            .font(.caption2)
                            .foregroundColor(Theme.secondaryWhite)
                    }
                    .padding(.vertical, 8)
                    
                    if event.id != sortedEvents.last?.id {
                        Divider().background(Theme.glassBorder)
                    }
                }
            }
        }
    }
    
    struct DataPoint: Identifiable {
        let id = UUID()
        let month: Double
        let value: Double
    }
    
    private var currentWHOData: [WHOStandard] {
        switch selectedMetric {
        case .weight: return WHOData.weightBoys
        case .height: return WHOData.lengthBoys
        case .head: return WHOData.headCircBoys
        }
    }
    
    private var userMeasurementsForChart: [DataPoint] {
        var points: [DataPoint] = []
        if let profile = viewModel.profiles.first {
            switch selectedMetric {
            case .weight:
                if let weight = profile.birthWeight { points.append(DataPoint(month: 0, value: weight)) }
            case .height:
                if let height = profile.birthHeight { points.append(DataPoint(month: 0, value: height)) }
            case .head:
                if let head = profile.birthHeadCircumference { points.append(DataPoint(month: 0, value: head)) }
            }
        }
        
        let events = viewModel.events.filter { event in
            event.eventType == .measurement && (
                (selectedMetric == .weight && event.subType == "Peso") ||
                (selectedMetric == .height && event.subType == "Altura") ||
                (selectedMetric == .head && event.subType == "Perímetro Cefálico")
            )
        }
        
        for event in events {
            points.append(DataPoint(month: monthsSinceBirth(event.startTime), value: event.value ?? 0))
        }
        
        return points.sorted { $0.month < $1.month }
    }
    
    private var userMeasurementsForList: [TrackerEvent] {
        viewModel.events.filter { event in
            event.eventType == .measurement && (
                (selectedMetric == .weight && event.subType == "Peso") ||
                (selectedMetric == .height && event.subType == "Altura") ||
                (selectedMetric == .head && event.subType == "Perímetro Cefálico")
            )
        }.sorted { $0.startTime > $1.startTime }
    }
    
    private var chartXScaleDomain: ClosedRange<Double> {
        let currentMonths = monthsSinceBirth(Date())
        let lastMeasurementMonth = userMeasurementsForChart.last?.month ?? 0
        let maxDataMonth = max(currentMonths, lastMeasurementMonth)
        
        // Show at least 6 months, or current age + a small buffer
        let upperLimit = max(6.0, ceil(maxDataMonth + 0.5))
        return 0...min(24.0, upperLimit)
    }
    
    private func monthsSinceBirth(_ date: Date) -> Double {
        guard let birthDate = viewModel.profiles.first?.birthDate else { return 0 }
        let components = Calendar.current.dateComponents([.month, .day], from: birthDate, to: date)
        return Double(components.month ?? 0) + Double(components.day ?? 0) / 30.0
    }
}
