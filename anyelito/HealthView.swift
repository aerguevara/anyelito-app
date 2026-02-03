import SwiftUI

struct HealthView: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showingAddAppointment = false
    @State private var editingAppointment: TrackerEvent?
    
    var body: some View {
        NavigationStack {
            ZStack {
                NebulaBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Picker("Sección", selection: $selectedTab) {
                        Text("Vacunas").tag(0)
                        Text("Citas").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    ScrollView {
                        if selectedTab == 0 {
                            vaccineScheduleList
                        } else {
                            appointmentList
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Salud y Vacunas")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if selectedTab == 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddAppointment = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Theme.primaryGreen)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddAppointment) {
                AppointmentSheet(appointment: nil)
            }
            .sheet(item: $editingAppointment) { appointment in
                AppointmentSheet(appointment: appointment)
            }
        }
    }
    
    // MARK: - Vaccines
    
    private var vaccineScheduleList: some View {
        VStack(spacing: 24) {
            let schedule = VaccineSchedule.madrid
            let birthDate = viewModel.profiles.first?.birthDate ?? Date()
            
            ForEach(schedule.sections) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(Theme.starWhite)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(section.vaccines, id: \.name) { vaccine in
                            VaccineRow(
                                vaccine: vaccine,
                                probableDate: Calendar.current.date(byAdding: .month, value: section.months, to: birthDate) ?? Date()
                            )
                            
                            if vaccine.name != section.vaccines.last?.name {
                                Divider().background(Theme.glassBorder).padding(.horizontal)
                            }
                        }
                    }
                    .glassStyle()
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Appointments
    
    private var appointmentList: some View {
        VStack(spacing: 12) {
            let visits = viewModel.events.filter { $0.eventType == .doctorVisit }
                .sorted { $0.startTime > $1.startTime }
            
            if visits.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(Theme.tertiaryWhite)
                    Text("No hay citas programadas")
                        .font(.subheadline)
                        .foregroundColor(Theme.tertiaryWhite)
                }
                .padding(40)
                .glassStyle()
                .padding(.horizontal)
            } else {
                ForEach(visits) { event in
                    Button {
                        editingAppointment = event
                    } label: {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(event.notes ?? "Cita Médica")
                                        .font(.headline)
                                        .foregroundColor(Theme.starWhite)
                                    Spacer()
                                    Text(event.startTime, style: .date)
                                        .font(.caption.bold())
                                        .foregroundColor(Theme.primaryGreen)
                                }
                                
                                HStack {
                                    Image(systemName: "clock")
                                    Text(event.startTime, style: .time)
                                    Spacer()
                                    Image(systemName: "pencil")
                                        .font(.caption2)
                                }
                                .font(.caption)
                                .foregroundColor(Theme.secondaryWhite)
                            }
                        }
                        .glassStyle()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct VaccineRow: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    let vaccine: VaccineSchedule.Vaccine
    let probableDate: Date
    
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    
    var isCompleted: Bool {
        viewModel.events.contains { $0.eventType == .vaccine && $0.subType == vaccine.name }
    }
    
    var completedEvent: TrackerEvent? {
        viewModel.events.first { $0.eventType == .vaccine && $0.subType == vaccine.name }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Theme.primaryGreen.opacity(0.12) : Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "syringe.fill")
                    .font(.footnote)
                    .foregroundColor(isCompleted ? Theme.primaryGreen : .blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(vaccine.name)
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.starWhite)
                
                if isCompleted, let date = completedEvent?.startTime {
                    Text("Puesta: \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.primaryGreen)
                } else {
                    Text("Prevista: \(probableDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.secondaryWhite)
                }
            }
            
            Spacer()
            
            Button {
                if isCompleted {
                    if let event = completedEvent { viewModel.deleteEvent(event) }
                } else {
                    showingDatePicker = true
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isCompleted ? Theme.primaryGreen : Theme.tertiaryWhite)
            }
        }
        .padding(.vertical, 10)
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Registrar Vacuna: \(vaccine.name)")
                        .font(.headline)
                        .foregroundColor(Theme.starWhite)
                    
                    DatePicker("Fecha de administración", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .glassStyle()
                    
                    Button("Confirmar") {
                        viewModel.addEvent(TrackerEvent(type: .vaccine, startTime: selectedDate, subType: vaccine.name))
                        showingDatePicker = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primaryGreen)
                }
                .padding()
                .background(NebulaBackground())
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showingDatePicker = false }
                    }
                }
            }
        }
    }
}

struct AppointmentSheet: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    let appointment: TrackerEvent?
    
    @State private var date = Date()
    @State private var notes = "Cita pediatra centro de salud"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Detalles") {
                    TextField("Título / Notas", text: $notes)
                    DatePicker("Fecha y Hora", selection: $date)
                }
                
                Section {
                    Button(appointment == nil ? "Agregar Cita" : "Guardar Cambios") {
                        save()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .listRowBackground(Theme.primaryGreen)
                    
                    if let appointment = appointment {
                        Button("Eliminar Cita", role: .destructive) {
                            viewModel.deleteEvent(appointment)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(appointment == nil ? "Nueva Cita" : "Editar Cita")
            .onAppear {
                if let app = appointment {
                    date = app.startTime
                    notes = app.notes ?? ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
    
    private func save() {
        if let app = appointment {
            app.startTime = date
            app.notes = notes
            viewModel.fetchData() // Refresh
        } else {
            viewModel.addEvent(TrackerEvent(type: .doctorVisit, startTime: date, notes: notes))
        }
        dismiss()
    }
}

// MARK: - Data Models

struct VaccineSchedule {
    struct Section: Identifiable {
        let id = UUID()
        let title: String
        let months: Int
        let vaccines: [Vaccine]
    }
    struct Vaccine {
        let name: String
    }
    
    let sections: [Section]
    
    static let madrid = VaccineSchedule(sections: [
        Section(title: "2 Meses", months: 2, vaccines: [
            Vaccine(name: "Hexavalente (1ª)"),
            Vaccine(name: "Neumococo (1ª)"),
            Vaccine(name: "Meningococo B (1ª)"),
            Vaccine(name: "Rotavirus (1ª)")
        ]),
        Section(title: "4 Meses", months: 4, vaccines: [
            Vaccine(name: "Hexavalente (2ª)"),
            Vaccine(name: "Neumococo (2ª)"),
            Vaccine(name: "Meningococo B (2ª)"),
            Vaccine(name: "Meningococo ACWY (1ª)"),
            Vaccine(name: "Rotavirus (2ª)")
        ]),
        Section(title: "11 Meses", months: 11, vaccines: [
            Vaccine(name: "Hexavalente (3ª)"),
            Vaccine(name: "Neumococo (3ª)")
        ]),
        Section(title: "12 Meses", months: 12, vaccines: [
            Vaccine(name: "Triple Vírica (1ª)"),
            Vaccine(name: "Meningococo ACWY (2ª)"),
            Vaccine(name: "Meningococo B (3ª)")
        ]),
        Section(title: "15 Meses", months: 15, vaccines: [
            Vaccine(name: "Varicela (1ª)")
        ]),
        Section(title: "3-4 Años", months: 48, vaccines: [
            Vaccine(name: "Triple Vírica (2ª)"),
            Vaccine(name: "Varicela (2ª)")
        ]),
        Section(title: "6 Años", months: 72, vaccines: [
            Vaccine(name: "DTPa-VPI")
        ]),
        Section(title: "12 Años", months: 144, vaccines: [
            Vaccine(name: "Meningococo ACWY (3ª)"),
            Vaccine(name: "VPH (2 dosis)")
        ]),
        Section(title: "14 Años", months: 168, vaccines: [
            Vaccine(name: "Td (Tétanos-Difteria)")
        ])
    ])
}
