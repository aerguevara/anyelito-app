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
                            Text("Duración (min)")
                            Spacer()
                            TextField("0", value: $durationMinutes, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 80)
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
                            Text("Cantidad (ml)")
                            Spacer()
                            TextField("0", value: $quantity, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 80)
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
        let finalEndTime = useDuration ? Calendar.current.date(byAdding: .second, value: Int(durationMinutes * 60), to: startTime)! : endTime
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
