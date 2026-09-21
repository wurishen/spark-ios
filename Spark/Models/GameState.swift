import Foundation
import Combine

struct GameState: Codable, Equatable {
    var hasPassedAgeGate: Bool
    var character: Character?
    var day: Int
    var timeOfDay: TimeOfDay
    var lastMessages: [PersistedMessage]
    var inventoryGifts: Int

    static let fresh = GameState(
        hasPassedAgeGate: false,
        character: nil,
        day: 1,
        timeOfDay: .afternoon,
        lastMessages: [],
        inventoryGifts: 3
    )
}

struct PersistedMessage: Codable, Equatable, Identifiable {
    var id: UUID
    var speakerRaw: String
    var text: String
    var timestamp: Date

    init(from line: DialogueLine) {
        id = line.id
        speakerRaw = line.speaker.rawValue
        text = line.text
        timestamp = line.timestamp
    }

    func toLine() -> DialogueLine {
        DialogueLine(
            id: id,
            speaker: DialogueSpeaker(rawValue: speakerRaw) ?? .system,
            text: text,
            timestamp: timestamp
        )
    }
}

enum TimeOfDay: String, Codable, CaseIterable {
    case morning
    case afternoon
    case evening
    case night

    var displayName: String {
        switch self {
        case .morning: return "早晨"
        case .afternoon: return "午后"
        case .evening: return "傍晚"
        case .night: return "夜晚"
        }
    }

    mutating func advance() {
        switch self {
        case .morning: self = .afternoon
        case .afternoon: self = .evening
        case .evening: self = .night
        case .night: self = .morning
        }
    }
}

/// 全局游戏状态仓库
@MainActor
final class GameStore: ObservableObject {
    @Published var state: GameState
    @Published var chatLog: [DialogueLine] = []
    @Published var statusBanner: String?

    private let persistence = PersistenceService()
    private let dialogue = DialogueEngine()

    init() {
        if let loaded = PersistenceService().load() {
            state = loaded
            chatLog = loaded.lastMessages.map { $0.toLine() }
        } else {
            state = .fresh
        }
    }

    func acceptAgeGate() {
        state.hasPassedAgeGate = true
        save()
    }

    func generateNewCharacter() {
        let character = CharacterGenerator.generate()
        state.character = character
        state.day = 1
        state.timeOfDay = .afternoon
        state.inventoryGifts = 3
        chatLog = [
            DialogueLine(
                speaker: .system,
                text: "你搬进了新家。室友 \(character.name)（\(character.age) 岁，\(character.occupation)）正在客厅等你。"
            ),
            DialogueLine(
                speaker: .character,
                text: dialogue.greeting(for: character)
            )
        ]
        persistChat()
        save()
    }

    func perform(_ action: CareAction) {
        guard var character = state.character else { return }
        let result = dialogue.resolveCareAction(action, character: character, giftsLeft: state.inventoryGifts)
        character = result.updatedCharacter
        if action == .gift && state.inventoryGifts > 0 {
            state.inventoryGifts -= 1
        }
        if action == .goOut {
            character.outfit = .outdoor
        }
        if action == .rest {
            character.currentRoom = .bedroom
            character.outfit = character.outfit.rank < OutfitState.home.rank ? .home : character.outfit
        }
        state.character = character
        append(result.lines)
        advanceTimeLightly()
        save()
        flash(result.banner)
    }

    func performIntimacy(_ action: IntimacyAction) {
        guard var character = state.character else { return }
        let tier = character.stats.intimacyTier
        guard tier >= action.requiredTier else {
            flash("信任与好感还不够（需要：\(action.requiredTier.displayName)）")
            append([DialogueLine(speaker: .character, text: dialogue.intimacyRejected(for: character, action: action))])
            save()
            return
        }
        let result = dialogue.resolveIntimacy(action, character: character)
        character = result.updatedCharacter
        if action == .makeLove || action == .caress {
            if character.outfit.isUnlocked(stats: character.stats) == false {
                // keep current
            } else if character.outfit.rank < OutfitState.underwear.rank {
                character.outfit = .underwear
            }
        }
        state.character = character
        append(result.lines)
        advanceTimeLightly()
        save()
        flash(result.banner)
    }

    func setOutfit(_ outfit: OutfitState) {
        guard var character = state.character else { return }
        guard outfit.isUnlocked(stats: character.stats) else {
            flash("她还不太愿意换成「\(outfit.displayName)」（好感≥\(Int(outfit.requiredAffection))，信任≥\(Int(outfit.requiredTrust))）")
            append([DialogueLine(
                speaker: .character,
                text: dialogue.outfitRejected(for: character, outfit: outfit)
            )])
            save()
            return
        }
        character.outfit = outfit
        state.character = character
        append([DialogueLine(
            speaker: .character,
            text: dialogue.outfitAccepted(for: character, outfit: outfit)
        )])
        save()
        flash("服装已切换：\(outfit.displayName)")
    }

    func switchRoom(_ room: RoomScene) {
        guard var character = state.character else { return }
        character.currentRoom = room
        if room == .bedroom && character.outfit == .outdoor {
            character.outfit = .home
        }
        state.character = character
        save()
    }

    func sendChat(topic: ChatTopic) {
        guard var character = state.character else { return }
        let result = dialogue.chat(topic: topic, character: character)
        character = result.updatedCharacter
        state.character = character
        append(result.lines)
        advanceTimeLightly()
        save()
    }

    func resetAll() {
        state = .fresh
        chatLog = []
        persistence.clear()
    }

    private func append(_ lines: [DialogueLine]) {
        chatLog.append(contentsOf: lines)
        if chatLog.count > 80 {
            chatLog = Array(chatLog.suffix(60))
        }
        persistChat()
    }

    private func persistChat() {
        state.lastMessages = chatLog.suffix(40).map { PersistedMessage(from: $0) }
    }

    private func advanceTimeLightly() {
        state.timeOfDay.advance()
        if state.timeOfDay == .morning {
            state.day += 1
            state.character?.relationshipDays += 1
            state.inventoryGifts = min(5, state.inventoryGifts + 1)
        }
    }

    private func save() {
        persistence.save(state)
    }

    private func flash(_ text: String?) {
        guard let text else { return }
        statusBanner = text
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if statusBanner == text {
                statusBanner = nil
            }
        }
    }
}
