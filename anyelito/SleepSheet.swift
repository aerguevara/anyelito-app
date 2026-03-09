import SwiftUI

struct SleepSheet: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var startTime = Date().addingTimeInterval(-3600)
    @State private var endTime = Date()
    @State private var useDuration = false
    @State private var durationHours: Double = 1
    @State private var durationMinutes: Double = 0
    
    var existingEvent: TrackerEvent? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Inicio", selection: $startTime)
                    
                    Toggle("Registrar por duración", isOn: $useDuration)
                    
                    if useDuration {
                        HStack {
                            Text("\(Int(durationHours))h \(Int(durationMinutes))min")
                                .font(.system(.body, design: .monospaced))
                            
                            VStack {
                                Slider(value: $durationHours, in: 0...12, step: 1)
                                Slider(value: $durationMinutes, in: 0...59, step: 1)
                            }
                        }
                    } else {
                        DatePicker("Fin", selection: $endTime)
                    }
                }
                
                Section {
                    Button("Guardar Sueño") {
                        saveSleep()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .listRowBackground(Theme.primaryGreen)
                }
            }
            .navigationTitle("Registro Sueño")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    private func saveSleep() {
        let finalEndTime: Date
        if useDuration {
            let totalSeconds = (durationHours * 3600) + (durationMinutes * 60)
            finalEndTime = startTime.addingTimeInterval(totalSeconds)
        } else {
            finalEndTime = endTime
        }
        
        if let event = existingEvent {
            event.startTime = startTime
            event.endTime = finalEndTime
            viewModel.updateEvent(event)
        } else {
            let event = TrackerEvent(
                type: .sleep,
                startTime: startTime,
                endTime: finalEndTime,
                subType: "Manual"
            )
            viewModel.addEvent(event)
        }
        dismiss()
    }
}

extension SleepSheet {
    private func loadExistingData() {
        guard let event = existingEvent else { return }
        startTime = event.startTime
        endTime = event.endTime ?? event.startTime
        
        if let end = event.endTime {
            let diff = end.timeIntervalSince(event.startTime)
            durationHours = floor(diff / 3600)
            durationMinutes = floor((diff.truncatingRemainder(dividingBy: 3600)) / 60)
        }
    }
}
