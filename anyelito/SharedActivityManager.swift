import Foundation
import SwiftData
import WidgetKit

@MainActor
class SharedActivityManager {
    static let shared = SharedActivityManager()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    private init() {
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
    
    func toggleSleep() {
        let descriptor = FetchDescriptor<TrackerEvent>(
            predicate: #Predicate { $0.type == "Sueño" && $0.endTime == nil }
        )
        
        do {
            let activeEvents = try modelContext.fetch(descriptor)
            if let active = activeEvents.first {
                active.endTime = Date()
                active.isSynced = false
            } else {
                let newEvent = TrackerEvent(type: .sleep, startTime: Date(), isSynced: false)
                modelContext.insert(newEvent)
            }
            try modelContext.save()
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
            if let active = activeEvents.first {
                active.endTime = Date()
                active.isSynced = false
            } else {
                let newEvent = TrackerEvent(type: .feeding, startTime: Date(), subType: "Pecho (Ambos)", isSynced: false)
                modelContext.insert(newEvent)
            }
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error toggling feeding: \(error)")
        }
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
