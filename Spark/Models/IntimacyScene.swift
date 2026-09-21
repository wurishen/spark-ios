import Foundation

/// 多步亲密场景（成人 22–32）：亲吻 → 爱抚 → 协助脱衣 → 缠绵高潮文本
enum IntimacyStep: Int, Codable, CaseIterable, Comparable {
    case kiss = 0
    case caress = 1
    case undressAssist = 2
    case climax = 3

    static func < (lhs: IntimacyStep, rhs: IntimacyStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .kiss: return "亲吻"
        case .caress: return "爱抚"
        case .undressAssist: return "协助宽衣"
        case .climax: return "缠绵"
        }
    }

    var requiredTier: IntimacyTier {
        switch self {
        case .kiss: return .close
        case .caress: return .close
        case .undressAssist: return .deep
        case .climax: return .deep
        }
    }

    /// 进入该步建议的最低兴奋
    var minArousal: Double {
        switch self {
        case .kiss: return 10
        case .caress: return 25
        case .undressAssist: return 40
        case .climax: return 55
        }
    }

    var next: IntimacyStep? {
        IntimacyStep(rawValue: rawValue + 1)
    }
}

struct IntimacyChoice: Identifiable {
    let id: String
    let title: String
    let kind: Kind

    enum Kind {
        case advance
        case soft
        case pause
        case stop
    }
}

struct IntimacyBeat {
    var step: IntimacyStep
    var narration: String
    var herLine: String
    var choices: [IntimacyChoice]
    var outfitHint: OutfitState?
    var deltaAffection: Double
    var deltaTrust: Double
    var deltaArousal: Double
    var deltaMood: Double
    var deltaEnergy: Double
}

/// 进行中的亲密会话（非持久化 UI 状态；结束后写回角色数值）
struct IntimacySession: Equatable {
    var step: IntimacyStep
    var beatsCompleted: Int
    var refused: Bool
    var finished: Bool
}
