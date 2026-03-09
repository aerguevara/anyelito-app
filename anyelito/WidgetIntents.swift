import AppIntents
import SwiftData

struct ToggleFeedingIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar Toma"
    static var description = IntentDescription("Inicia o detiene el temporizador de la toma")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SharedActivityManager.shared.toggleFeeding()
        return .result()
    }
}

struct ToggleSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar Sueño"
    static var description = IntentDescription("Inicia o detiene el temporizador del sueño")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        SharedActivityManager.shared.toggleSleep()
        return .result()
    }
}
