import Foundation
import SwiftData
import WidgetKit

#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
#endif

@MainActor
class SharedActivityManager {
    static let shared = SharedActivityManager()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    private init() {
        // Initialize Firebase if not already configured
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 [SharedActivityManager] Firebase configured")
        }
        #endif

        let schema = Schema([
            BabyProfile.self,
            TrackerEvent.self,
        ])
        
        let appGroupIdentifier = "group.com.anyelo.anyelito"
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier)
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not initialize SharedActivityManager: \(error)")
        }
    }
    
    // MARK: - Toggle Actions
    
    func toggleSleep() {
        let descriptor = FetchDescriptor<TrackerEvent>(
            predicate: #Predicate { $0.type == "Sueño" && $0.endTime == nil }
        )
        
        do {
            let activeEvents = try modelContext.fetch(descriptor)
            let event: TrackerEvent
            if let active = activeEvents.first {
                active.endTime = Date()
                active.isSynced = false
                event = active
                print("🌙 [SharedActivityManager] Deteniendo sueño")
            } else {
                let newEvent = TrackerEvent(type: .sleep, startTime: Date(), isSynced: false)
                modelContext.insert(newEvent)
                event = newEvent
                print("🌙 [SharedActivityManager] Iniciando sueño")
            }
            try modelContext.save()
            
            // Background sync
            syncEventToCloud(event)
            
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error toggling sleep: \(error)")
        }
    }
    
    func toggleFeeding() {
        let descriptor = FetchDescriptor<TrackerEvent>(
            predicate: #Predicate { $0.type == "Toma" && $0.endTime == nil }
        )
        
        do {
            let activeEvents = try modelContext.fetch(descriptor)
            let event: TrackerEvent
            if let active = activeEvents.first {
                active.endTime = Date()
                active.isSynced = false
                event = active
                print("🍼 [SharedActivityManager] Deteniendo toma")
            } else {
                let newEvent = TrackerEvent(type: .feeding, startTime: Date(), subType: "Pecho (Ambos)", isSynced: false)
                modelContext.insert(newEvent)
                event = newEvent
                print("🍼 [SharedActivityManager] Iniciando toma")
            }
            try modelContext.save()
            
            // Background sync
            syncEventToCloud(event)
            
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error toggling feeding: \(error)")
        }
    }

    // MARK: - Cloud Sync
    
    func syncFromCloud(isWidget: Bool = false) async {
        let tag = isWidget ? "🏷️ [WidgetSync]" : "📱 [AppSync]"
        #if canImport(FirebaseCore)
        do {
            // Ensure we are signed in
            if Auth.auth().currentUser == nil {
                print("\(tag) Solicitando login anónimo...")
                _ = try await Auth.auth().signInAnonymously()
            }
            
            // Get baby profile ID
            let profileDescriptor = FetchDescriptor<BabyProfile>()
            guard let profile = try modelContext.fetch(profileDescriptor).first else { 
                print("\(tag) ⚠️ No se encontró perfil local")
                return 
            }
            
            let babyId = profile.id.uuidString
            print("\(tag) ☁️ Consultando Firestore para \(profile.name)...")
            
            // Fetch remote events
            let remoteEventsData = try await FirestoreService.shared.fetchEvents(forBabyId: babyId)
            print("\(tag) 📥 Recibidos \(remoteEventsData.count) eventos remotos")
            
            // Merge remote events into local SwiftData
            for data in remoteEventsData {
                guard let idString = data["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let typeString = data["type"] as? String,
                      let startTimeTimestamp = data["startTime"] as? Timestamp else { continue }
                
                let type = EventType(rawValue: typeString) ?? .feeding
                let startTime = startTimeTimestamp.dateValue()
                let endTime = (data["endTime"] as? Timestamp)?.dateValue()
                let subType = data["subType"] as? String
                let notes = data["notes"] as? String
                let value = data["value"] as? Double
                
                // Check if event exists locally
                let localDescriptor = FetchDescriptor<TrackerEvent>(
                    predicate: #Predicate { $0.id == id }
                )
                let localEvents = try modelContext.fetch(localDescriptor)
                
                if let localEvent = localEvents.first {
                    // Update existing local event if needed
                    localEvent.type = type.rawValue
                    localEvent.startTime = startTime
                    localEvent.endTime = endTime
                    localEvent.subType = subType
                    localEvent.notes = notes
                    localEvent.value = value
                    localEvent.isSynced = true
                } else {
                    // Create new local event
                    let newEvent = TrackerEvent(
                        type: type,
                        startTime: startTime,
                        endTime: endTime,
                        value: value,
                        subType: subType,
                        notes: notes,
                        isSynced: true
                    )
                    newEvent.id = id // Preserve remote ID
                    modelContext.insert(newEvent)
                }
            }
            
            try modelContext.save()
            print("✅ [SharedActivityManager] Sincronización remota completada")
        } catch {
            print("❌ [SharedActivityManager] Error en syncFromCloud: \(error.localizedDescription)")
        }
        #endif
    }
    
    private func syncEventToCloud(_ event: TrackerEvent) {
        #if canImport(FirebaseCore)
        Task {
            do {
                // Ensure we are signed in (anonymously)
                if Auth.auth().currentUser == nil {
                    print("👤 [SharedActivityManager] Intentando login anónimo para sync...")
                    _ = try await Auth.auth().signInAnonymously()
                }
                
                // Get the baby profile ID
                let profileDescriptor = FetchDescriptor<BabyProfile>()
                guard let profile = try modelContext.fetch(profileDescriptor).first else {
                    print("⚠️ [SharedActivityManager] No se encontró perfil para sincronizar")
                    return
                }
                
                print("☁️ [SharedActivityManager] Sincronizando evento \(event.type)...")
                try await FirestoreService.shared.syncEvent(event, forBabyId: profile.id.uuidString)
                
                event.isSynced = true
                try modelContext.save()
                print("✅ [SharedActivityManager] Sincronización exitosa")
            } catch {
                print("❌ [SharedActivityManager] Error en sincronización: \(error.localizedDescription)")
            }
        }
        #else
        print("ℹ️ [SharedActivityManager] Firebase no disponible en este target. El evento se sincronizará cuando se abra la app.")
        #endif
    }
    
    func isFeedingActive() -> Bool {
        let descriptor = FetchDescriptor<TrackerEvent>(
            predicate: #Predicate { $0.type == "Toma" && $0.endTime == nil }
        )
        return (try? modelContext.fetch(descriptor))?.isEmpty == false
    }
    
    func isSleepActive() -> Bool {
        let descriptor = FetchDescriptor<TrackerEvent>(
            predicate: #Predicate { $0.type == "Sueño" && $0.endTime == nil }
        )
        return (try? modelContext.fetch(descriptor))?.isEmpty == false
    }
    
    func activeFeedingStartTime() -> Date? {
        let descriptor = FetchDescriptor<TrackerEvent>(
            predicate: #Predicate { $0.type == "Toma" && $0.endTime == nil }
        )
        return try? modelContext.fetch(descriptor).first?.startTime
    }
    
    func activeSleepStartTime() -> Date? {
        let descriptor = FetchDescriptor<TrackerEvent>(
            predicate: #Predicate { $0.type == "Sueño" && $0.endTime == nil }
        )
        return try? modelContext.fetch(descriptor).first?.startTime
    }
}
