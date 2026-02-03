import SwiftUI

struct FeedingSheet: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var feedingType: FeedingType = .breast
    @State private var quantity: Double = 120
    @State private var breastSide: BreastSide = .left
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var useDuration = false
    @State private var durationMinutes: Double = 15
    @State private var isLM = true
    
    enum FeedingType: String, CaseIterable {
        case breast = "Pecho"
        case bottle = "Biberón"
    }
    
    enum BreastSide: String, CaseIterable {
        case left = "Izquierdo"
        case right = "Derecho"
        case both = "Ambos"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo", selection: $feedingType) {
                        ForEach(FeedingType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    DatePicker("Inicio", selection: $startTime)
                    
                    Toggle("Registrar duración", isOn: $useDuration)
                    
                    if useDuration {
                        HStack {
                            Text("\(Int(durationMinutes)) min")
                                .font(.system(.body, design: .monospaced))
                            Slider(value: $durationMinutes, in: 1...60, step: 1)
                        }
                    } else {
                        DatePicker("Fin", selection: $endTime)
                    }
                }
                
                if feedingType == .breast {
                    Section("Lado") {
                        Picker("Lado", selection: $breastSide) {
                            ForEach(BreastSide.allCases, id: \.self) { side in
                                Text(side.rawValue).tag(side)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } else {
                    Section("Cantidad") {
                        HStack {
                            Text("\(Int(quantity)) ml")
                                .font(.system(.body, design: .monospaced))
                            Slider(value: $quantity, in: 0...300, step: 10)
                        }
                        
                        Toggle("Leche Materna", isOn: $isLM)
                    }
                }
                
                Section {
                    Button("Guardar Toma") {
                        saveFeeding()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .listRowBackground(Theme.primaryGreen)
                }
            }
            .navigationTitle("Registro Toma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
    
    private func saveFeeding() {
        let finalEndTime = useDuration ? Calendar.current.date(byAdding: .minute, value: Int(durationMinutes), to: startTime)! : endTime
        let subType = feedingType == .breast ? "Pecho (\(breastSide.rawValue))" : (isLM ? "Biberón (LM)" : "Biberón (Fórmula)")
        
        let event = TrackerEvent(
            type: .feeding,
            startTime: startTime,
            endTime: finalEndTime,
            value: feedingType == .bottle ? quantity : nil,
            subType: subType
        )
        viewModel.addEvent(event)
        dismiss()
    }
}
