import SwiftUI

struct MeasurementSheet: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var weight: Double = 3.5
    @State private var height: Double = 50.0
    @State private var headCircumference: Double = 35.0
    
    @State private var saveWeight = false
    @State private var saveHeight = false
    @State private var saveHead = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Fecha y Hora", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    Toggle("Registrar Peso", isOn: $saveWeight)
                    if saveWeight {
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(Theme.primaryGreen)
                                .frame(width: 20)
                            Text("Peso (kg)")
                            Spacer()
                            TextField("0.00", value: $weight, format: .number.precision(.fractionLength(0...5)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 80)
                        }
                    }
                }
                
                Section {
                    Toggle("Registrar Altura", isOn: $saveHeight)
                    if saveHeight {
                        HStack {
                            Image(systemName: "ruler.fill")
                                .foregroundColor(Theme.primaryGreen)
                                .frame(width: 20)
                            Text("Altura (cm)")
                            Spacer()
                            TextField("0.0", value: $height, format: .number.precision(.fractionLength(0...5)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 80)
                        }
                    }
                }
                
                Section {
                    Toggle("Registrar Perímetro", isOn: $saveHead)
                    if saveHead {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(Theme.primaryGreen)
                                .frame(width: 20)
                            Text("Perímetro (cm)")
                            Spacer()
                            TextField("0.0", value: $headCircumference, format: .number.precision(.fractionLength(0...5)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 80)
                        }
                    }
                }
                
                Section {
                    Button("Guardar Selección") {
                        saveMeasurements()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .listRowBackground(saveWeight || saveHeight || saveHead ? Theme.primaryGreen : Color.gray)
                    .disabled(!(saveWeight || saveHeight || saveHead))
                }
            }
            .navigationTitle("Registro Medición")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
    
    private func saveMeasurements() {
        if saveWeight {
            viewModel.addEvent(TrackerEvent(type: .measurement, startTime: date, value: weight, subType: "Peso"))
        }
        if saveHeight {
            viewModel.addEvent(TrackerEvent(type: .measurement, startTime: date, value: height, subType: "Altura"))
        }
        if saveHead {
            viewModel.addEvent(TrackerEvent(type: .measurement, startTime: date, value: headCircumference, subType: "Perímetro Cefálico"))
        }
        
        dismiss()
    }
}
