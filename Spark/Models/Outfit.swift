import Foundation
import SwiftUI

/// 服装分层状态：由外到内渐进脱衣，受好感/信任门控
enum OutfitState: String, Codable, CaseIterable, Identifiable {
    case outdoor
    case casual
    case home
    case underwear
    case nude

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .outdoor: return "外出装"
        case .casual: return "便装"
        case .home: return "居家服"
        case .underwear: return "内衣"
        case .nude: return "裸身"
        }
    }

    var rank: Int {
        switch self {
        case .outdoor: return 0
        case .casual: return 1
        case .home: return 2
        case .underwear: return 3
        case .nude: return 4
        }
    }

    var requiredAffection: Double {
        switch self {
        case .outdoor, .casual, .home: return 0
        case .underwear: return 40
        case .nude: return 65
        }
    }

    var requiredTrust: Double {
        switch self {
        case .outdoor, .casual, .home: return 0
        case .underwear: return 35
        case .nude: return 60
        }
    }

    func isUnlocked(stats: CharacterStats) -> Bool {
        stats.affection >= requiredAffection && stats.trust >= requiredTrust
    }

    var showsOuterClothes: Bool {
        self == .outdoor || self == .casual || self == .home
    }

    var showsUnderwear: Bool {
        self == .underwear || showsOuterClothes
    }

    var showsNudeSilhouette: Bool {
        self == .nude
    }

    var clothColor: Color {
        switch self {
        case .outdoor: return Color(red: 0.25, green: 0.35, blue: 0.55)
        case .casual: return Color(red: 0.55, green: 0.45, blue: 0.70)
        case .home: return Color(red: 0.95, green: 0.75, blue: 0.80)
        case .underwear, .nude: return .clear
        }
    }
}

struct AppearancePalette: Codable, Equatable {
    var skinTone: String
    var hairColor: String
    var eyeColor: String
    var underwearColor: String

    static let defaults: [AppearancePalette] = [
        AppearancePalette(skinTone: "#F5D0C0", hairColor: "#2C1810", eyeColor: "#4A3728", underwearColor: "#E8B4CB"),
        AppearancePalette(skinTone: "#E8C4A8", hairColor: "#8B4513", eyeColor: "#3D5A80", underwearColor: "#A8D5E5"),
        AppearancePalette(skinTone: "#F2C9B0", hairColor: "#1A1A2E", eyeColor: "#2D6A4F", underwearColor: "#C77DFF"),
        AppearancePalette(skinTone: "#D4A574", hairColor: "#4A0E0E", eyeColor: "#1B263B", underwearColor: "#FF6B9D"),
        AppearancePalette(skinTone: "#FFE0D0", hairColor: "#C9A227", eyeColor: "#5C4033", underwearColor: "#FFB4A2"),
    ]
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (200, 180, 160)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
