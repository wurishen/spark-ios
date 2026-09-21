import Foundation

/// 角色核心数值（全部 0–100）
struct CharacterStats: Codable, Equatable {
    var mood: Double
    var affection: Double
    var trust: Double
    var arousal: Double
    var energy: Double
    var hunger: Double

    static let starter = CharacterStats(
        mood: 55,
        affection: 20,
        trust: 25,
        arousal: 5,
        energy: 80,
        hunger: 30
    )

    mutating func clamp() {
        mood = min(100, max(0, mood))
        affection = min(100, max(0, affection))
        trust = min(100, max(0, trust))
        arousal = min(100, max(0, arousal))
        energy = min(100, max(0, energy))
        hunger = min(100, max(0, hunger))
    }

    var intimacyTier: IntimacyTier {
        if affection >= 70 && trust >= 65 { return .deep }
        if affection >= 45 && trust >= 40 { return .close }
        if affection >= 25 && trust >= 20 { return .light }
        return .locked
    }
}

enum IntimacyTier: Int, Codable, Comparable {
    case locked = 0
    case light = 1
    case close = 2
    case deep = 3

    static func < (lhs: IntimacyTier, rhs: IntimacyTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .locked: return "未解锁"
        case .light: return "轻柔"
        case .close: return "亲密"
        case .deep: return "深入"
        }
    }
}
