import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.65, green: 0.46, blue: 0.25)

    static func background(_ dark: Bool) -> Color {
        dark ? Color(red: 0.09, green: 0.095, blue: 0.105) : Color(red: 0.96, green: 0.95, blue: 0.91)
    }

    static func surface(_ dark: Bool) -> Color {
        dark ? Color(red: 0.16, green: 0.17, blue: 0.18) : Color.white.opacity(0.8)
    }

    static func primaryText(_ dark: Bool) -> Color {
        dark ? Color(red: 0.94, green: 0.93, blue: 0.90) : Color(red: 0.31, green: 0.29, blue: 0.25)
    }

    static func secondaryText(_ dark: Bool) -> Color {
        dark ? Color(red: 0.70, green: 0.69, blue: 0.66) : Color(red: 0.53, green: 0.50, blue: 0.45)
    }

    static func border(_ dark: Bool) -> Color {
        dark ? Color.white.opacity(0.12) : Color.white.opacity(0.88)
    }
}

enum TilePalette: String, CaseIterable, Identifiable {
    case warm
    case cool

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warm: "Warm"
        case .cool: "Cool"
        }
    }

    func colors(for value: Int) -> (background: Color, foreground: Color) {
        switch self {
        case .warm:
            warmColors(for: value)
        case .cool:
            coolColors(for: value)
        }
    }

    private func warmColors(for value: Int) -> (background: Color, foreground: Color) {
        switch value {
        case ...0: (Color(red: 0.83, green: 0.79, blue: 0.72).opacity(0.55), .clear)
        case 2: (Color(red: 0.93, green: 0.90, blue: 0.84), Color(red: 0.42, green: 0.39, blue: 0.34))
        case 4: (Color(red: 0.92, green: 0.86, blue: 0.73), Color(red: 0.42, green: 0.39, blue: 0.34))
        case 8: (Color(red: 0.92, green: 0.67, blue: 0.46), .white)
        case 16: (Color(red: 0.91, green: 0.54, blue: 0.36), .white)
        case 32: (Color(red: 0.89, green: 0.43, blue: 0.34), .white)
        case 64: (Color(red: 0.84, green: 0.30, blue: 0.23), .white)
        case 128: (Color(red: 0.87, green: 0.70, blue: 0.36), .white)
        case 256: (Color(red: 0.85, green: 0.65, blue: 0.25), .white)
        case 512: (Color(red: 0.80, green: 0.58, blue: 0.18), .white)
        case 1024: (Color(red: 0.74, green: 0.50, blue: 0.12), .white)
        case 2048: (Color(red: 0.68, green: 0.44, blue: 0.12), .white)
        case 4096: (Color(red: 0.76, green: 0.38, blue: 0.22), .white)
        case 8192: (Color(red: 0.70, green: 0.28, blue: 0.25), .white)
        case 16384: (Color(red: 0.62, green: 0.26, blue: 0.34), .white)
        case 32768: (Color(red: 0.52, green: 0.24, blue: 0.39), .white)
        default: (Color(red: 0.40, green: 0.20, blue: 0.34), .white)
        }
    }

    private func coolColors(for value: Int) -> (background: Color, foreground: Color) {
        switch value {
        case ...0: (Color(red: 0.75, green: 0.81, blue: 0.86).opacity(0.52), .clear)
        case 2: (Color(red: 0.88, green: 0.94, blue: 0.97), Color(red: 0.22, green: 0.34, blue: 0.42))
        case 4: (Color(red: 0.73, green: 0.88, blue: 0.93), Color(red: 0.18, green: 0.33, blue: 0.40))
        case 8: (Color(red: 0.45, green: 0.79, blue: 0.82), Color(red: 0.10, green: 0.28, blue: 0.33))
        case 16: (Color(red: 0.28, green: 0.69, blue: 0.78), .white)
        case 32: (Color(red: 0.22, green: 0.57, blue: 0.78), .white)
        case 64: (Color(red: 0.25, green: 0.44, blue: 0.76), .white)
        case 128: (Color(red: 0.35, green: 0.40, blue: 0.78), .white)
        case 256: (Color(red: 0.45, green: 0.37, blue: 0.78), .white)
        case 512: (Color(red: 0.55, green: 0.34, blue: 0.76), .white)
        case 1024: (Color(red: 0.46, green: 0.34, blue: 0.70), .white)
        case 2048: (Color(red: 0.30, green: 0.34, blue: 0.68), .white)
        case 4096: (Color(red: 0.22, green: 0.47, blue: 0.66), .white)
        case 8192: (Color(red: 0.18, green: 0.38, blue: 0.60), .white)
        case 16384: (Color(red: 0.20, green: 0.31, blue: 0.56), .white)
        case 32768: (Color(red: 0.28, green: 0.25, blue: 0.52), .white)
        default: (Color(red: 0.21, green: 0.20, blue: 0.40), .white)
        }
    }
}
