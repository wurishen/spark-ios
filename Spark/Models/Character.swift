import Foundation

struct Character: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var age: Int
    var occupation: String
    var personalityTraits: [PersonalityTrait]
    var likes: [String]
    var dislikes: [String]
    var stats: CharacterStats
    var outfit: OutfitState
    var appearance: AppearancePalette
    var currentRoom: RoomScene
    var relationshipDays: Int

    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        occupation: String,
        personalityTraits: [PersonalityTrait],
        likes: [String],
        dislikes: [String],
        stats: CharacterStats = .starter,
        outfit: OutfitState = .casual,
        appearance: AppearancePalette,
        currentRoom: RoomScene = .livingRoom,
        relationshipDays: Int = 1
    ) {
        precondition(age >= 22 && age <= 32, "角色年龄必须为成年 22–32")
        self.id = id
        self.name = name
        self.age = age
        self.occupation = occupation
        self.personalityTraits = personalityTraits
        self.likes = likes
        self.dislikes = dislikes
        self.stats = stats
        self.outfit = outfit
        self.appearance = appearance
        self.currentRoom = currentRoom
        self.relationshipDays = relationshipDays
    }

    var traitsSummary: String {
        personalityTraits.map(\.displayName).joined(separator: " · ")
    }
}

enum PersonalityTrait: String, Codable, CaseIterable {
    case gentle
    case cheerful
    case shy
    case witty
    case caring
    case independent
    case romantic
    case playful

    var displayName: String {
        switch self {
        case .gentle: return "温柔"
        case .cheerful: return "开朗"
        case .shy: return "害羞"
        case .witty: return "俏皮"
        case .caring: return "体贴"
        case .independent: return "独立"
        case .romantic: return "浪漫"
        case .playful: return "爱玩"
        }
    }
}

enum RoomScene: String, Codable, CaseIterable, Identifiable {
    case livingRoom
    case bedroom
    case kitchen
    case bathroomDoor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .livingRoom: return "客厅"
        case .bedroom: return "卧室"
        case .kitchen: return "厨房"
        case .bathroomDoor: return "浴室门口"
        }
    }

    var systemImage: String {
        switch self {
        case .livingRoom: return "sofa.fill"
        case .bedroom: return "bed.double.fill"
        case .kitchen: return "cooktop.fill"
        case .bathroomDoor: return "door.left.hand.closed"
        }
    }

    var blurb: String {
        switch self {
        case .livingRoom: return "阳光与沙发，日常聊天的地方"
        case .bedroom: return "柔软的床铺，适合休息与亲密"
        case .kitchen: return "锅碗瓢盆与咖啡香"
        case .bathroomDoor: return "梳妆台与半掩的门——礼貌地等候"
        }
    }
}

enum CareAction: String, CaseIterable, Identifiable {
    case chat
    case cook
    case gift
    case rest
    case goOut
    case intimacy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chat: return "聊天"
        case .cook: return "做饭"
        case .gift: return "送礼"
        case .rest: return "休息"
        case .goOut: return "出门"
        case .intimacy: return "亲密"
        }
    }

    var systemImage: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .cook: return "fork.knife"
        case .gift: return "gift.fill"
        case .rest: return "bed.double.fill"
        case .goOut: return "figure.walk"
        case .intimacy: return "heart.fill"
        }
    }
}

enum IntimacyAction: String, CaseIterable, Identifiable {
    case holdHands
    case hug
    case kiss
    case caress
    case makeLove

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .holdHands: return "牵手"
        case .hug: return "拥抱"
        case .kiss: return "亲吻"
        case .caress: return "爱抚"
        case .makeLove: return "缠绵"
        }
    }

    var requiredTier: IntimacyTier {
        switch self {
        case .holdHands: return .light
        case .hug: return .light
        case .kiss: return .close
        case .caress: return .close
        case .makeLove: return .deep
        }
    }
}
