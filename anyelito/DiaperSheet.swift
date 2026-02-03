import SwiftUI

struct DiaperSheet: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var isPee = true
    @State private var isPoo = false
    
    @State private var pooColor: PooColor = .mustard
    @State private var pooTexture: PooTexture = .normal
    
    enum PooColor: String, CaseIterable {
        case mustard = "Mostaza"
        case green = "Verde"
        case brown = "Marrón"
        case black = "Negro"
        case red = "Rojo"
        case white = "Blanco"
        
        var color: Color {
            switch self {
            case .mustard: return .yellow
            case .green: return .green
            case .brown: return .brown
            case .black: return .black
            case .red: return .red
            case .white: return .gray.opacity(0.3)
            }
        }
    }
    
    enum PooTexture: String, CaseIterable {
        case liquid = "Líquida"
        case normal = "Normal"
        case hard = "Dura"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Hora", selection: $date)
                }
                
                Section("Tipo") {
                    Toggle("Orina 💧", isOn: $isPee)
                    Toggle("Heces 💩", isOn: $isPoo)
                }
                
                if isPoo {
                    Section("Detalle Heces") {
                        Text("Color")
                            .font(.subheadline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(PooColor.allCases, id: \.self) { color in
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(pooColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                        .onTapGesture {
                                            pooColor = color
                                        }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Picker("Textura", selection: $pooTexture) {
                            ForEach(PooTexture.allCases, id: \.self) { texture in
                                Text(texture.rawValue).tag(texture)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                Section {
                    Button("Guardar") {
                        saveDiaper()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .listRowBackground(Color.purple)
                    .disabled(!isPee && !isPoo)
                }
            }
            .navigationTitle("Registro Pañal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
    
    private func saveDiaper() {
        var subTypes: [String] = []
        if isPee { subTypes.append("Orina") }
        if isPoo { subTypes.append("Heces (\(pooColor.rawValue), \(pooTexture.rawValue))") }
        
        let event = TrackerEvent(
            type: .diaper,
            startTime: date,
            subType: subTypes.joined(separator: " + ")
        )
        viewModel.addEvent(event)
        dismiss()
    }
}
