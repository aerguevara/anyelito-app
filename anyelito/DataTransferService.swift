import Foundation
import SwiftData

class DataTransferService {
    static func exportToCSV(events: [TrackerEvent]) -> String {
        var csvString = "id,type,startTime,endTime,value,subType,notes\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for event in events {
            let id = event.id.uuidString
            let type = event.type
            let start = dateFormatter.string(from: event.startTime)
            let end = event.endTime != nil ? dateFormatter.string(from: event.endTime!) : ""
            let val = event.value != nil ? String(event.value!) : ""
            let sub = event.subType ?? ""
            let notes = (event.notes ?? "").replacingOccurrences(of: "\n", with: " ")
            
            csvString += "\(id),\(type),\(start),\(end),\(val),\(sub),\(notes)\n"
        }
        
        return csvString
    }
    
    static func importCSV(from url: URL) -> [TrackerEvent] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        let rows = content.components(separatedBy: .newlines)
        guard rows.count > 1 else { return [] }
        
        let dateFormatter = ISO8601DateFormatter()
        var events: [TrackerEvent] = []
        
        for i in 1..<rows.count {
            let columns = rows[i].components(separatedBy: ",")
            if columns.count >= 7 {
                let typeStr = columns[1]
                guard let type = EventType(rawValue: typeStr) else { continue }
                let start = dateFormatter.date(from: columns[2]) ?? Date()
                let end = dateFormatter.date(from: columns[3])
                let val = Double(columns[4])
                let sub = columns[5].isEmpty || columns[5] == "nil" ? nil : columns[5]
                let notes = columns[6].isEmpty || columns[6] == "nil" ? nil : columns[6]
                
                let event = TrackerEvent(
                    type: type,
                    startTime: start,
                    endTime: end,
                    value: val,
                    subType: sub,
                    notes: notes
                )
                events.append(event)
            }
        }
        return events
    }
    
    static func importFromCSV(_ csvContent: String, context: ModelContext) {
        let rows = csvContent.components(separatedBy: "\n")
        guard rows.count > 1 else { return }
        
        let dateFormatter = ISO8601DateFormatter()
        
        for i in 1..<rows.count {
            let columns = rows[i].components(separatedBy: ",")
            if columns.count >= 7 {
                let typeStr = columns[1]
                guard let type = EventType(rawValue: typeStr) else { continue }
                let start = dateFormatter.date(from: columns[2]) ?? Date()
                let end = dateFormatter.date(from: columns[3])
                let val = Double(columns[4])
                let sub = columns[5].isEmpty ? nil : columns[5]
                let notes = columns[6].isEmpty ? nil : columns[6]
                
                let event = TrackerEvent(
                    type: type,
                    startTime: start,
                    endTime: end,
                    value: val,
                    subType: sub,
                    notes: notes
                )
                context.insert(event)
            }
        }
        
        try? context.save()
    }
}
