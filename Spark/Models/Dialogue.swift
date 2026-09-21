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
