import Foundation

struct WHOStandard: Identifiable {
    let id = UUID()
    let month: Int
    let p3: Double
    let p15: Double
    let p50: Double
    let p85: Double
    let p97: Double
}

struct WHOData {
    // Sample data for Weight-for-age (Boys 0-2 years) in kg
    static let weightBoys: [WHOStandard] = [
        WHOStandard(month: 0, p3: 2.5, p15: 2.9, p50: 3.3, p85: 3.9, p97: 4.4),
        WHOStandard(month: 1, p3: 3.4, p15: 3.9, p50: 4.5, p85: 5.1, p97: 5.7),
        WHOStandard(month: 2, p3: 4.3, p15: 4.9, p50: 5.6, p85: 6.3, p97: 7.0),
        WHOStandard(month: 3, p3: 5.0, p15: 5.7, p50: 6.4, p85: 7.2, p97: 7.9),
        WHOStandard(month: 4, p3: 5.6, p15: 6.3, p50: 7.0, p85: 7.8, p97: 8.6),
        WHOStandard(month: 6, p3: 6.4, p15: 7.1, p50: 7.9, p85: 8.8, p97: 9.7),
        WHOStandard(month: 9, p3: 7.1, p15: 8.0, p50: 8.9, p85: 9.9, p97: 11.0),
        WHOStandard(month: 12, p3: 7.7, p15: 8.6, p50: 9.6, p85: 10.8, p97: 12.0)
    ]
    
    // Sample data for Length-for-age (Boys 0-2 years) in cm
    static let lengthBoys: [WHOStandard] = [
        WHOStandard(month: 0, p3: 46.1, p15: 48.0, p50: 49.9, p85: 51.8, p97: 53.7),
        WHOStandard(month: 1, p3: 50.8, p15: 52.8, p50: 54.7, p85: 56.7, p97: 58.6),
        WHOStandard(month: 2, p3: 54.4, p15: 56.4, p50: 58.4, p85: 60.4, p97: 62.4),
        WHOStandard(month: 3, p3: 57.3, p15: 59.4, p50: 61.4, p85: 63.5, p97: 65.5),
        WHOStandard(month: 4, p3: 59.7, p15: 61.8, p50: 63.9, p85: 66.0, p97: 68.0),
        WHOStandard(month: 5, p3: 61.7, p15: 63.8, p50: 65.9, p85: 68.0, p97: 70.1),
        WHOStandard(month: 6, p3: 63.3, p15: 65.5, p50: 67.6, p85: 69.8, p97: 71.9),
        WHOStandard(month: 12, p3: 71.0, p15: 73.4, p50: 75.7, p85: 78.1, p97: 82.9)
    ]
    
    // Sample data for Head Circumference-for-age (Boys 0-2 years) in cm
    static let headCircBoys: [WHOStandard] = [
        WHOStandard(month: 0, p3: 32.1, p15: 33.5, p50: 34.5, p85: 35.8, p97: 36.9),
        WHOStandard(month: 1, p3: 35.1, p15: 36.3, p50: 37.3, p85: 38.6, p97: 39.5),
        WHOStandard(month: 2, p3: 36.9, p15: 38.1, p50: 39.1, p85: 40.4, p97: 41.3),
        WHOStandard(month: 6, p3: 41.0, p15: 42.3, p50: 43.3, p85: 44.6, p97: 45.6),
        WHOStandard(month: 12, p3: 43.6, p15: 45.0, p50: 46.1, p85: 47.4, p97: 48.5)
    ]
}
