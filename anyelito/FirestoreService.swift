import Foundation
import FirebaseFirestore
import SwiftData

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private var babyCollection: CollectionReference {
        return db.collection("babies")
    }
    
    func syncProfile(_ profile: BabyProfile) async throws {
        print("☁️ [Firestore] Intentando sincronizar perfil: \(profile.name) (ID: \(profile.id.uuidString))")
        let data: [String: Any] = [
            "id": profile.id.uuidString,
            "name": profile.name,
            "birthDate": Timestamp(date: profile.birthDate),
            "birthWeight": profile.birthWeight as Any,
            "birthHeight": profile.birthHeight as Any,
            "birthHeadCircumference": profile.birthHeadCircumference as Any,
            "sharingID": profile.sharingID as Any,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await babyCollection.document(profile.id.uuidString).setData(data, merge: true)
            print("✅ [Firestore] Perfil sincronizado con éxito")
        } catch {
            print("❌ [Firestore] Error al sincronizar perfil: \(error.localizedDescription)")
            throw error
        }
    }
    
    func syncEvent(_ event: TrackerEvent, forBabyId babyId: String) async throws {
        print("☁️ [Firestore] Intentando sincronizar evento: \(event.type) (ID: \(event.id.uuidString))")
        let data: [String: Any] = [
            "id": event.id.uuidString,
            "type": event.type,
            "startTime": Timestamp(date: event.startTime),
            "endTime": event.endTime != nil ? Timestamp(date: event.endTime!) : NSNull(),
            "value": event.value as Any,
            "subType": event.subType as Any,
            "notes": event.notes as Any,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await babyCollection.document(babyId).collection("events").document(event.id.uuidString).setData(data)
            print("✅ [Firestore] Evento sincronizado con éxito")
        } catch {
            print("❌ [Firestore] Error al sincronizar evento: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Listeners & Fetching
    
    func fetchBabyBySharingID(_ code: String) async throws -> [String: Any]? {
        let snapshot = try await babyCollection.whereField("sharingID", isEqualTo: code).getDocuments()
        return snapshot.documents.first?.data()
    }
    
    func listenToProfile(forBabyId babyId: String, completion: @escaping ([String: Any]) -> Void) -> ListenerRegistration {
        print("👂 [Firestore] Iniciando listener de perfil para \(babyId)")
        return babyCollection.document(babyId).addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ [Firestore] Error en listener de perfil: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else { 
                print("⚠️ [Firestore] Snapshot de perfil vacío")
                return 
            }
            print("👤 [Firestore] Perfil actualizado desde la nube")
            completion(data)
        }
    }
    
    func listenToEvents(forBabyId babyId: String, completion: @escaping ([[String: Any]]) -> Void) -> ListenerRegistration {
        print("👂 [Firestore] Iniciando listener de eventos para \(babyId)")
        return babyCollection.document(babyId).collection("events").addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ [Firestore] Error en listener de eventos: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { 
                print("⚠️ [Firestore] Snapshot de eventos vacío")
                return 
            }
            let eventsData = documents.map { $0.data() }
            print("📥 [Firestore] Recibidos \(eventsData.count) eventos vía listener")
            completion(eventsData)
        }
    }
    
    func deleteEvent(eventId: String, babyId: String) async throws {
        print("☁️ [Firestore] Intentando eliminar evento: \(eventId)")
        do {
            try await babyCollection.document(babyId).collection("events").document(eventId).delete()
            print("✅ [Firestore] Evento eliminado con éxito")
        } catch {
            print("❌ [Firestore] Error al eliminar evento: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchEvents(forBabyId babyId: String) async throws -> [[String: Any]] {
        let snapshot = try await babyCollection.document(babyId).collection("events").getDocuments()
        return snapshot.documents.map { $0.data() }
    }
}
