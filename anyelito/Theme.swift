import SwiftUI

struct Theme {
    static let deepSpace = Color(hex: "050212")
    static let primaryGreen = Color(hex: "00C853") // Vibrant Green
    static let nebulaGreen = Color(hex: "004D40") // Dark Teal/Green
    static let nebulaMint = Color(hex: "64FFDA") // Mint
    static let starWhite = Color(hex: "FFFFFF")
    static let secondaryWhite = Color.white.opacity(0.7)
    static let tertiaryWhite = Color.white.opacity(0.4)
    static let glassBackground = Color.white.opacity(0.12)
    static let glassBorder = Color.white.opacity(0.18)
}

struct NebulaBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Theme.deepSpace
                .ignoresSafeArea()
            
            // Nebula layers
            RadialGradient(colors: [Theme.nebulaGreen.opacity(0.4), .clear], center: animate ? .topLeading : .bottomTrailing, startRadius: 100, endRadius: 600)
                .blur(radius: 50)
                .ignoresSafeArea()
            
            RadialGradient(colors: [Theme.nebulaMint.opacity(0.2), .clear], center: animate ? .bottomTrailing : .topLeading, startRadius: 100, endRadius: 700)
                .blur(radius: 60)
                .ignoresSafeArea()
            
            // Stars
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    for i in 0..<50 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let opacity = CGFloat.random(in: 0.1...0.8)
                        let starSize = CGFloat.random(in: 1...3)
                        
                        context.opacity = opacity
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)), with: .color(.white))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

struct GlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .background(Theme.glassBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Theme.glassBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassStyle() -> some View {
        self.modifier(GlassModifier())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Spanish format helper
extension Double {
    func formattedSpanish(decimals: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
