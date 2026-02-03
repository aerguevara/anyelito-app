import Foundation
import SwiftData

@Model
final class BabyProfile {
    var name: String
    var birthDate: Date
    var birthWeight: Double? // In kg
    var birthHeight: Double? // In cm
    var birthHeadCircumference: Double? // In cm
    var image: Data?
    
    init(name: String, birthDate: Date, birthWeight: Double? = nil, birthHeight: Double? = nil, birthHeadCircumference: Double? = nil, image: Data? = nil) {
        self.name = name
        self.birthDate = birthDate
        self.birthWeight = birthWeight
        self.birthHeight = birthHeight
        self.birthHeadCircumference = birthHeadCircumference
        self.image = image
    }
}

enum EventType: String, Codable, CaseIterable {
    case feeding = "Toma"
    case sleep = "Sueño"
    case diaper = "Pañal"
    case measurement = "Medición"
    case vaccine = "Vacuna"
    case doctorVisit = "Cita Médica"
    
    var icon: String {
        switch self {
        case .feeding: return "drop.fill"
        case .sleep: return "moon.zzz.fill"
        case .diaper: return "toilet.fill"
        case .measurement: return "ruler.fill"
        case .vaccine: return "syringe.fill"
        case .doctorVisit: return "stethoscope"
        }
    }
}

@Model
final class TrackerEvent {
    @Attribute(.unique) var id: UUID
    var type: String
    var startTime: Date
    var endTime: Date?
    var value: Double? // Quantity ml, weight kg, height cm
    var subType: String? // "LeftBreast", "Formula", "Pee", "Poo"
    var notes: String?
    var metadata: [String: String]? // For colors or vaccine batch
    
    var eventType: EventType {
        get { EventType(rawValue: type) ?? .feeding }
        set { type = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), type: EventType, startTime: Date = Date(), endTime: Date? = nil, value: Double? = nil, subType: String? = nil, notes: String? = nil, metadata: [String: String]? = nil) {
        self.id = id
        self.type = type.rawValue
        self.startTime = startTime
        self.endTime = endTime
        self.value = value
        self.subType = subType
        self.notes = notes
        self.metadata = metadata
    }
}
