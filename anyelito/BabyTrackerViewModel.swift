import SwiftUI
import SwiftData
import Combine

@Observable
final class BabyTrackerViewModel {
    var modelContext: ModelContext
    var events: [TrackerEvent] = []
    var profiles: [BabyProfile] = []
    
    var activeSleepEvent: TrackerEvent?
    var timer: AnyCancellable?
    var sleepDuration: TimeInterval = 0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
        checkForActiveTimer()
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
    
    func addEvent(_ event: TrackerEvent) {
        modelContext.insert(event)
        fetchData()
    }
    
    func deleteEvent(_ event: TrackerEvent) {
        modelContext.delete(event)
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
}
