import SwiftUI
import SwiftData

import PhotosUI

struct SettingsView: View {
    @Environment(BabyTrackerViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var babyName: String = ""
    @State private var birthDate: Date = Date()
    @State private var weightBirth: String = ""
    @State private var heightBirth: String = ""
    @State private var headBirth: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    
    @State private var isEditing: Bool = false
    @State private var showingSaveAlert: Bool = false
    @State private var showingImportPicker: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var joinCode: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                NebulaBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Perfil del Bebé")
                                    .font(.headline)
                                    .foregroundColor(Theme.starWhite)
                                Spacer()
                                Button(isEditing ? "Cancelar" : "Editar") {
                                    withAnimation { isEditing.toggle() }
                                    if !isEditing { loadExistingData() }
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.primaryGreen)
                            }
                            
                            VStack(spacing: 20) {
                                profileImageSection
                                
                                CustomTextField(label: "Nombre", text: $babyName)
                                    .disabled(!isEditing)
                                
                                DatePicker("Nacimiento", selection: $birthDate, displayedComponents: [.date, .hourAndMinute])
                                    .foregroundColor(Theme.starWhite)
                                    .disabled(!isEditing)
                                
                                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                                    GridRow {
                                        CustomTextField(label: "Peso (kg)", text: $weightBirth)
                                            .keyboardType(.decimalPad)
                                        CustomTextField(label: "Altura (cm)", text: $heightBirth)
                                            .keyboardType(.decimalPad)
                                    }
                                    GridRow {
                                        CustomTextField(label: "Perímetro (cm)", text: $headBirth)
                                            .keyboardType(.decimalPad)
                                        Color.clear // Spacer
                                    }
                                }
                                .disabled(!isEditing)
                                
                                if isEditing {
                                    Button(action: saveProfile) {
                                        Text("Guardar Cambios")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(.linearGradient(colors: [Theme.nebulaGreen, Theme.primaryGreen], startPoint: .leading, endPoint: .trailing))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .glassStyle()
                            .opacity(isEditing ? 1.0 : 0.8)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Datos")
                                .font(.headline)
                                .foregroundColor(Theme.starWhite)
                            
                            VStack(spacing: 0) {
                                if let profile = viewModel.profiles.first, let sharingID = profile.sharingID {
                                    HStack {
                                        SettingsRow(title: "Código de Compartir", icon: "shareplay", color: Theme.primaryGreen)
                                        Text(sharingID)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(Theme.starWhite)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Theme.glassBackground)
                                            .cornerRadius(6)
                                            .onTapGesture {
                                                UIPasteboard.general.string = sharingID
                                            }
                                    }
                                    .padding(.trailing, 10)
                                    
                                    Divider().background(Theme.glassBorder).padding(.vertical, 8)
                                }
                                
                                Button {
                                    let csv = DataTransferService.exportToCSV(events: viewModel.events)
                                    shareCSV(csv)
                                } label: {
                                    SettingsRow(title: "Exportar CSV", icon: "square.and.arrow.up", color: .blue)
                                }
                                
                                Divider().background(Theme.glassBorder).padding(.vertical, 8)

                                Button(action: { showingImportPicker = true }) {
                                    SettingsRow(title: "Importar Datos", icon: "square.and.arrow.down", color: .purple)
                                }
                                
                                Divider().background(Theme.glassBorder).padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Unirse a un Bebé")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Theme.secondaryWhite)
                                    
                                    HStack {
                                        TextField("Ingresar código", text: $joinCode)
                                            .textFieldStyle(.plain)
                                            .foregroundColor(Theme.starWhite)
                                            .padding(10)
                                            .background(Color.white.opacity(0.08))
                                            .cornerRadius(8)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.characters)
                                        
                                        Button(action: { 
                                            viewModel.joinBaby(with: joinCode)
                                            joinCode = ""
                                        }) {
                                            Text("Unirse")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(Theme.primaryGreen)
                                                .cornerRadius(8)
                                        }
                                        .disabled(joinCode.isEmpty)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                Divider().background(Theme.glassBorder).padding(.vertical, 8)
                                
                                Button(action: { showingDeleteAlert = true }) {
                                    SettingsRow(title: "Borrar Todo", icon: "trash", color: .red)
                                }
                            }
                            .glassStyle()
                        }
                        
                        VStack(spacing: 8) {
                            Text("Anyelito v1.1")
                                .font(.caption)
                                .foregroundColor(Theme.tertiaryWhite)
                            Text("Hecho con ❤️ para bebés felices.")
                                .font(.caption2)
                                .foregroundColor(Theme.tertiaryWhite.opacity(0.5))
                        }
                        .padding(.top, 32)
                    }
                    .padding()
                }
            }
            .navigationTitle("Ajustes")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear { loadExistingData() }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [.commaSeparatedText]) { result in
                switch result {
                case .success(let url):
                    let events = DataTransferService.importCSV(from: url)
                    for event in events {
                        viewModel.addEvent(event)
                    }
                case .failure(let error):
                    print("Error importando CSV: \(error)")
                }
            }
            .alert("Perfil Guardado", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { isEditing = false }
            } message: {
                Text("Los datos del bebé se han actualizado correctamente.")
            }
            .alert("¿Borrar todo?", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Borrar Todo", role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text("Esta acción eliminará todos los registros y el perfil del bebé. No se puede deshacer.")
            }
        }
    }
    
    private var profileImageSection: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.glassBackground)
                        .frame(width: 100, height: 100)
                    Image(systemName: "camera.fill")
                        .foregroundColor(Theme.tertiaryWhite)
                }
            }
            .overlay(Circle().stroke(Theme.primaryGreen.opacity(0.3), lineWidth: 2))
        }
        .disabled(!isEditing)
    }
    
    private func loadExistingData() {
        if let profile = viewModel.profiles.first {
            babyName = profile.name
            birthDate = profile.birthDate
            weightBirth = profile.birthWeight?.formattedSpanish(maxDecimals: 5) ?? ""
            heightBirth = profile.birthHeight?.formattedSpanish(maxDecimals: 5) ?? ""
            headBirth = profile.birthHeadCircumference?.formattedSpanish(maxDecimals: 5) ?? ""
            imageData = profile.image
        }
    }
    
    private func saveProfile() {
        let weight = Double(weightBirth.replacingOccurrences(of: ",", with: "."))
        let height = Double(heightBirth.replacingOccurrences(of: ",", with: "."))
        let head = Double(headBirth.replacingOccurrences(of: ",", with: "."))
        
        if let profile = viewModel.profiles.first {
            profile.name = babyName
            profile.birthDate = birthDate
            profile.birthWeight = weight
            profile.birthHeight = height
            profile.birthHeadCircumference = head
            profile.image = imageData
            viewModel.saveProfile(profile)
        } else {
            let newProfile = BabyProfile(name: babyName, birthDate: birthDate, birthWeight: weight, birthHeight: height, birthHeadCircumference: head, image: imageData)
            viewModel.saveProfile(newProfile)
        }
        showingSaveAlert = true
    }
    
    private func shareCSV(_ content: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("anyelito_data.csv")
        try? content.write(to: url, atomically: true, encoding: .utf8)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(vc, animated: true)
        }
    }
}

struct CustomTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(Theme.secondaryWhite)
            TextField("", text: $text, prompt: Text("Escribe aquí...").foregroundColor(Theme.tertiaryWhite))
                .textFieldStyle(.plain)
                .foregroundColor(Theme.starWhite)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.footnote.bold())
                    .foregroundColor(color)
            }
            Text(title)
                .foregroundColor(Theme.starWhite)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(Theme.tertiaryWhite)
        }
        .padding(.vertical, 8)
    }
}
