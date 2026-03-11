import AppIntents
import SwiftData

struct ToggleFeedingIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar Toma"
    static var description = IntentDescription("Inicia o detiene el temporizador de la toma")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        print("🔘 [ToggleFeedingIntent] Ejecutando...")
        SharedActivityManager.shared.toggleFeeding()
        // Damos un pequeño respiro para que el guardado local se complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        return .result()
    }
}

struct ToggleSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar Sueño"
    static var description = IntentDescription("Inicia o detiene el temporizador del sueño")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        print("🔘 [ToggleSleepIntent] Ejecutando...")
        SharedActivityManager.shared.toggleSleep()
        // Damos un pequeño respiro para que el guardado local se complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        return .result()
    }
}
