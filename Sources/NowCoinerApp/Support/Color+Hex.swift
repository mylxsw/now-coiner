import SwiftUI

extension Color {
    init(hex: String) {
        let input = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: input).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch input.count {
        case 8:
            a = (value & 0xFF000000) >> 24
            r = (value & 0x00FF0000) >> 16
            g = (value & 0x0000FF00) >> 8
            b = value & 0x000000FF
        default:
            a = 255
            r = (value & 0xFF0000) >> 16
            g = (value & 0x00FF00) >> 8
            b = value & 0x0000FF
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
