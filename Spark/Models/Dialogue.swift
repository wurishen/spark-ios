import Foundation

struct DialogueLine: Identifiable, Equatable {
    let id: UUID
    let speaker: DialogueSpeaker
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), speaker: DialogueSpeaker, text: String, timestamp: Date = Date()) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
    }
}

enum DialogueSpeaker: String, Codable {
    case player
    case character
    case system
}

struct ChatTopic: Identifiable {
    let id: String
    let title: String
    let category: TopicCategory
}

enum TopicCategory: String {
    case daily
    case hobby
    case feelings
    case past
    case flirt
}

extension ChatTopic {
    static func topics(for time: TimeOfDay, likes: [String], intimacyTier: IntimacyTier = .locked, arousal: Double = 0) -> [ChatTopic] {
        var list = dailyTopics(for: time) + hobbyTopics(likes: likes) + [
            ChatTopic(id: "feelings", title: "想听你的感受", category: .feelings),
            ChatTopic(id: "past", title: "你以前的生活", category: .past),
            ChatTopic(id: "flirt", title: flirtTitle(for: time), category: .flirt)
        ]
        if intimacyTier >= .close || arousal >= 35 {
            list += adultTopics(for: time, tier: intimacyTier)
        }
        return list
    }

    static func adultTopics(for time: TimeOfDay, tier: IntimacyTier) -> [ChatTopic] {
        var items = [
            ChatTopic(id: "a1", title: "刚才靠得好近……你有没有心跳加速？", category: .flirt),
            ChatTopic(id: "a2", title: "想听你说「今晚想要我」", category: .flirt),
        ]
        if tier >= .deep {
            items += [
                ChatTopic(id: "a3", title: "如果现在宽衣，你会害羞吗？", category: .flirt),
                ChatTopic(id: "a4", title: "卧室灯关小一点，好不好？", category: .flirt),
            ]
        }
        if time == .night || time == .evening {
            items.append(ChatTopic(id: "a5", title: "夜里只想抱着你不说话", category: .flirt))
        }
        return items
    }

    static func dailyTopics(for time: TimeOfDay) -> [ChatTopic] {
        switch time {
        case .morning:
            return [
                ChatTopic(id: "d1", title: "早上好，睡得怎么样？", category: .daily),
                ChatTopic(id: "d2", title: "今天有什么安排？", category: .daily)
            ]
        case .afternoon:
            return [
                ChatTopic(id: "d1", title: "今天过得怎么样？", category: .daily),
                ChatTopic(id: "d2", title: "下午想喝点什么？", category: .daily)
            ]
        case .evening:
            return [
                ChatTopic(id: "d1", title: "傍晚风不错，聊一会儿？", category: .daily),
                ChatTopic(id: "d2", title: "晚饭想吃什么？", category: .daily)
            ]
        case .night:
            return [
                ChatTopic(id: "d1", title: "还不睡吗？陪我说说话", category: .daily),
                ChatTopic(id: "d2", title: "今天最开心的事是什么？", category: .daily)
            ]
        }
    }

    static func hobbyTopics(likes: [String]) -> [ChatTopic] {
        let base = likes.prefix(2).enumerated().map { i, like in
            ChatTopic(id: "h\(i)", title: "聊聊\(like)", category: .hobby)
        }
        if base.isEmpty {
            return [ChatTopic(id: "h0", title: "聊聊手冲咖啡", category: .hobby)]
        }
        return Array(base)
    }

    static func flirtTitle(for time: TimeOfDay) -> String {
        switch time {
        case .morning: return "你今早也很好看"
        case .afternoon: return "你今天很好看"
        case .evening: return "灯下的你，有点晃眼"
        case .night: return "夜里想靠近你一点"
        }
    }
}
