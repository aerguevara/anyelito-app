import SwiftUI

struct MeasurementSheet: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    
    // Estados para los valores
    @State private var weight: Double = 3.5
    @State private var height: Double = 50.0
    @State private var headCirc: Double = 35.0
    
    // Estados para los toggles
    @State private var includeWeight = true
    @State private var includeHeight = false
    @State private var includeHeadCirc = false
    
    var existingEvent: TrackerEvent? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                NebulaBackground() // Uso el fondo animado para consistencia
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        DatePicker("Fecha y Hora", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("Momento de la medición")
                            .foregroundColor(Theme.secondaryWhite)
                    }
                    
                    // Peso
                    Section {
                        Toggle(isOn: $includeWeight) {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(.orange)
                                Text("Peso")
                                    .foregroundColor(Theme.starWhite)
                            }
                        }
                        .tint(Theme.primaryGreen)
                        
                        if includeWeight {
                            HStack {
                                Text("Cantidad (kg)")
                                    .foregroundColor(Theme.secondaryWhite)
                                Spacer()
                                TextField("0.00", value: $weight, format: .number.precision(.fractionLength(0...3)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(Theme.starWhite)
                                    .frame(width: 100)
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    } header: {
                        Text("Peso corporal")
                            .foregroundColor(Theme.secondaryWhite)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    // Altura
                    Section {
                        Toggle(isOn: $includeHeight) {
                            HStack {
                                Image(systemName: "ruler.fill")
                                    .foregroundColor(.blue)
                                Text("Altura")
                                    .foregroundColor(Theme.starWhite)
                            }
                        }
                        .tint(Theme.primaryGreen)
                        
                        if includeHeight {
                            HStack {
                                Text("Longitud (cm)")
                                    .foregroundColor(Theme.secondaryWhite)
                                Spacer()
                                TextField("0.0", value: $height, format: .number.precision(.fractionLength(0...2)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(Theme.starWhite)
                                    .frame(width: 100)
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    } header: {
                        Text("Altura / Longitud")
                            .foregroundColor(Theme.secondaryWhite)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    // Perímetro Cefálico
                    Section {
                        Toggle(isOn: $includeHeadCirc) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.purple)
                                Text("P. Cefálico")
                                    .foregroundColor(Theme.starWhite)
                            }
                        }
                        .tint(Theme.primaryGreen)
                        
                        if includeHeadCirc {
                            HStack {
                                Text("Perímetro (cm)")
                                    .foregroundColor(Theme.secondaryWhite)
                                Spacer()
                                TextField("0.0", value: $headCirc, format: .number.precision(.fractionLength(0...2)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(Theme.starWhite)
                                    .frame(width: 100)
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    } header: {
                        Text("Perímetro de la cabeza")
                            .foregroundColor(Theme.secondaryWhite)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    Section {
                        Button(action: saveAll) {
                            Text(existingEvent == nil ? "Guardar Mediciones" : "Actualizar Registro")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                        }
                        .disabled(!includeWeight && !includeHeight && !includeHeadCirc)
                        .listRowBackground(
                            (!includeWeight && !includeHeight && !includeHeadCirc) ? 
                            Color.gray.opacity(0.3) : Theme.primaryGreen
                        )
                        .foregroundColor(.white)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existingEvent == nil ? "Nueva Medición" : "Editar Medición")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                if let event = existingEvent {
                    loadData(from: event)
                }
            }
        }
    }
    
    private func saveAll() {
        if let event = existingEvent {
            event.startTime = date
            if includeWeight {
                event.subType = "Peso"
                event.value = weight
            } else if includeHeight {
                event.subType = "Altura"
                event.value = height
            } else if includeHeadCirc {
                event.subType = "Perímetro Cefálico"
                event.value = headCirc
            }
            viewModel.updateEvent(event)
        } else {
            if includeWeight {
                let e = TrackerEvent(type: .measurement, startTime: date, value: weight, subType: "Peso")
                viewModel.addEvent(e)
            }
            if includeHeight {
                let e = TrackerEvent(type: .measurement, startTime: date, value: height, subType: "Altura")
                viewModel.addEvent(e)
            }
            if includeHeadCirc {
                let e = TrackerEvent(type: .measurement, startTime: date, value: headCirc, subType: "Perímetro Cefálico")
                viewModel.addEvent(e)
            }
        }
        dismiss()
    }
    
    private func loadData(from event: TrackerEvent) {
        date = event.startTime
        if let sub = event.subType {
            if sub == "Peso" {
                includeWeight = true
                includeHeight = false
                includeHeadCirc = false
                weight = event.value ?? 0
            } else if sub == "Altura" {
                includeWeight = false
                includeHeight = true
                includeHeadCirc = false
                height = event.value ?? 0
            } else if sub == "Perímetro Cefálico" {
                includeWeight = false
                includeHeight = false
                includeHeadCirc = true
                headCirc = event.value ?? 0
            }
        }
    }
}
