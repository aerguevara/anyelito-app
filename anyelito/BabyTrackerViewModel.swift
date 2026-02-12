import SwiftUI
import SwiftData
import Combine
import FirebaseFirestore

@Observable
final class BabyTrackerViewModel {
    var modelContext: ModelContext
    var events: [TrackerEvent] = []
    var profiles: [BabyProfile] = []
    
    var activeSleepEvent: TrackerEvent?
    var timer: AnyCancellable?
    var sleepDuration: TimeInterval = 0
    
    private var profileListener: ListenerRegistration?
    private var eventsListener: ListenerRegistration?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
        checkForActiveTimer()
        setupFirebase()
    }
    
    private func setupFirebase() {
        Task {
            do {
                try await FirebaseManager.shared.signInAnonymously()
                print("Signed in anonymously to Firebase")
                syncAllPendingData()
                
                // Start listeners if we have a baby
                if let profile = profiles.first {
                    startFirestoreListeners(for: profile.id.uuidString)
                }
            } catch {
                print("Firebase auth failed: \(error)")
            }
        }
    }
    
    func joinBaby(with code: String) {
        Task {
            do {
                guard let babyData = try await FirestoreService.shared.fetchBabyBySharingID(code) else {
                    print("No baby found with code \(code)")
                    return
                }
                
                guard let babyIdString = babyData["id"] as? String, let babyId = UUID(uuidString: babyIdString) else { return }
                
                // Clear existing local data to avoid confusion (since we are joining a new profile)
                deleteAllData()
                
                // 1. Create Profile locally
                let name = babyData["name"] as? String ?? "Bebé"
                let birthDate = (babyData["birthDate"] as? Timestamp)?.dateValue() ?? Date()
                let weight = babyData["birthWeight"] as? Double
                let height = babyData["birthHeight"] as? Double
                let head = babyData["birthHeadCircumference"] as? Double
                
                let newProfile = BabyProfile(id: babyId, name: name, birthDate: birthDate, birthWeight: weight, birthHeight: height, birthHeadCircumference: head, sharingID: code)
                modelContext.insert(newProfile)
                
                // 2. Fetch all events for this baby
                let eventsData = try await FirestoreService.shared.fetchEvents(forBabyId: babyIdString)
                for data in eventsData {
                    if let event = createEvent(from: data) {
                        modelContext.insert(event)
                    }
                }
                
                try? modelContext.save()
                fetchData()
                
                // 3. Start real-time listeners
                startFirestoreListeners(for: babyIdString)
                
            } catch {
                print("Error joining baby: \(error)")
            }
        }
    }
    
    private func startFirestoreListeners(for babyId: String) {
        profileListener?.remove()
        eventsListener?.remove()
        
        profileListener = FirestoreService.shared.listenToProfile(forBabyId: babyId) { [weak self] data in
            self?.updateProfileLocally(with: data)
        }
        
        eventsListener = FirestoreService.shared.listenToEvents(forBabyId: babyId) { [weak self] eventsData in
            self?.updateEventsLocally(with: eventsData)
        }
    }
    
    private func updateProfileLocally(with data: [String: Any]) {
        guard let idString = data["id"] as? String, let id = UUID(uuidString: idString) else { return }
        
        if let localProfile = profiles.first(where: { $0.id == id }) {
            localProfile.name = data["name"] as? String ?? localProfile.name
            localProfile.birthDate = (data["birthDate"] as? Timestamp)?.dateValue() ?? localProfile.birthDate
            localProfile.birthWeight = data["birthWeight"] as? Double
            localProfile.birthHeight = data["birthHeight"] as? Double
            localProfile.birthHeadCircumference = data["birthHeadCircumference"] as? Double
            localProfile.sharingID = data["sharingID"] as? String
            
            try? modelContext.save()
            fetchData()
        }
    }
    
    private func updateEventsLocally(with eventsData: [[String: Any]]) {
        let serverIds = Set(eventsData.compactMap { $0["id"] as? String })
        
        // 1. Remove local events that are no longer on the server
        for localEvent in events {
            if !serverIds.contains(localEvent.id.uuidString) {
                modelContext.delete(localEvent)
            }
        }
        
        // 2. Update or Insert
        for data in eventsData {
            guard let idString = data["id"] as? String, let id = UUID(uuidString: idString) else { continue }
            
            if let localEvent = events.first(where: { $0.id == id }) {
                // Update existing
                localEvent.type = data["type"] as? String ?? localEvent.type
                localEvent.startTime = (data["startTime"] as? Timestamp)?.dateValue() ?? localEvent.startTime
                localEvent.endTime = (data["endTime"] as? Timestamp)?.dateValue()
                localEvent.value = data["value"] as? Double
                localEvent.subType = data["subType"] as? String
                localEvent.notes = data["notes"] as? String
            } else {
                // Insert new
                if let newEvent = createEvent(from: data) {
                    modelContext.insert(newEvent)
                }
            }
        }
        try? modelContext.save()
        fetchData()
    }
    
    private func createEvent(from data: [String: Any]) -> TrackerEvent? {
        guard let idString = data["id"] as? String, let id = UUID(uuidString: idString) else { return nil }
        guard let typeStr = data["type"] as? String, let type = EventType(rawValue: typeStr) else { return nil }
        
        let start = (data["startTime"] as? Timestamp)?.dateValue() ?? Date()
        let end = (data["endTime"] as? Timestamp)?.dateValue()
        let value = data["value"] as? Double
        let sub = data["subType"] as? String
        let notes = data["notes"] as? String
        
        return TrackerEvent(id: id, type: type, startTime: start, endTime: end, value: value, subType: sub, notes: notes)
    }
    
    func fetchData() {
        do {
            let eventDescriptor = FetchDescriptor<TrackerEvent>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
            events = try modelContext.fetch(eventDescriptor)
            
            let profileDescriptor = FetchDescriptor<BabyProfile>()
            profiles = try modelContext.fetch(profileDescriptor)
        } catch {
            print("Fetch failed")
        }
    }
    
    func saveProfile(_ profile: BabyProfile) {
        let isNew = !profiles.contains(where: { $0.id == profile.id })
        if isNew {
            modelContext.insert(profile)
        }
        
        fetchData()
        
        // Start listeners if it's the first time
        if isNew || profileListener == nil {
            startFirestoreListeners(for: profile.id.uuidString)
        }
        
        // Immediate cloud sync
        Task {
            if profile.sharingID == nil {
                profile.sharingID = String(profile.id.uuidString.prefix(6)).uppercased()
            }
            do {
                try await FirestoreService.shared.syncProfile(profile)
                print("✅ Perfil sincronizado con la nube con éxito")
            } catch {
                print("❌ Error al sincronizar perfil con la nube: \(error)")
            }
        }
    }
    
    func addEvent(_ event: TrackerEvent) {
        modelContext.insert(event)
        fetchData()
        
        // Push to cloud
        Task {
            if let profile = profiles.first {
                do {
                    try await FirestoreService.shared.syncEvent(event, forBabyId: profile.id.uuidString)
                    print("✅ Evento enviado a la nube con éxito")
                } catch {
                    print("❌ Error al enviar evento a la nube: \(error)")
                }
            } else {
                print("⚠️ No hay perfil de bebé para sincronizar el evento")
            }
        }
    }
    
    func deleteEvent(_ event: TrackerEvent) {
        let eventId = event.id.uuidString
        modelContext.delete(event)
        fetchData()
        
        // Delete from cloud
        Task {
            if let babyId = profiles.first?.id.uuidString {
                do {
                    try await FirestoreService.shared.deleteEvent(eventId: eventId, babyId: babyId)
                } catch {
                    print("❌ Error al eliminar evento de la nube: \(error)")
                }
            }
        }
    }
    
    func deleteAllData() {
        try? modelContext.delete(model: TrackerEvent.self)
        try? modelContext.delete(model: BabyProfile.self)
        fetchData()
    }
    
    // MARK: - Sleep Logic
    
    func checkForActiveTimer() {
        activeSleepEvent = events.first { $0.eventType == .sleep && $0.endTime == nil }
        if activeSleepEvent != nil {
            startTimer()
        }
    }
    
    func toggleSleep() {
        if let active = activeSleepEvent {
            active.endTime = Date()
            activeSleepEvent = nil
            stopTimer()
        } else {
            let newEvent = TrackerEvent(type: .sleep, startTime: Date())
            addEvent(newEvent)
            activeSleepEvent = newEvent
            startTimer()
        }
    }
    
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let active = self.activeSleepEvent else { return }
                self.sleepDuration = Date().timeIntervalSince(active.startTime)
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        sleepDuration = 0
    }
    
    // MARK: - Summary Logic
    
    var lastFeeding: String {
        guard let feeding = events.first(where: { $0.eventType == .feeding }) else {
            return "Sin registros"
        }
        let interval = Date().timeIntervalSince(feeding.startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "hace \(hours)h \(minutes)m"
    }
    
    // MARK: - Cloud Sync
    
    func syncAllPendingData() {
        print("🔄 Iniciando sincronización de todos los datos pendientes...")
        Task {
            if profiles.isEmpty {
                print("⚠️ No se encontraron perfiles para sincronizar")
            }
            for profile in profiles {
                if profile.sharingID == nil {
                    // Generate a simple sharing ID if missing (e.g., first 6 chars of UUID)
                    profile.sharingID = String(profile.id.uuidString.prefix(6)).uppercased()
                }
                do {
                    try await FirestoreService.shared.syncProfile(profile)
                    print("✅ Perfil \(profile.name) sincronizado")
                    for event in events {
                        try await FirestoreService.shared.syncEvent(event, forBabyId: profile.id.uuidString)
                    }
                    print("✅ Todos los eventos (\(events.count)) sincronizados")
                } catch {
                    print("❌ Error en syncAllPendingData: \(error)")
                }
            }
        }
    }
}
