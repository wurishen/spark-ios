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

    var emoji: String {
        switch self {
        case .morning: return "🌅"
        case .afternoon: return "☀️"
        case .evening: return "🌇"
        case .night: return "🌙"
        }
    }

    /// 该时段可用的照顾行动（亲密另由门控）
    var availableCareActions: Set<CareAction> {
        switch self {
        case .morning:
            return [.chat, .cook, .gift, .goOut]
        case .afternoon:
            return [.chat, .cook, .gift, .rest, .goOut, .intimacy]
        case .evening:
            return [.chat, .cook, .gift, .rest, .intimacy]
        case .night:
            return [.chat, .rest, .intimacy]
        }
    }

    func isActionAvailable(_ action: CareAction) -> Bool {
        availableCareActions.contains(action)
    }

    var unavailableHint: String {
        switch self {
        case .morning: return "早晨更适合出门与早餐，休息/亲密稍后再说。"
        case .afternoon: return "午后百无禁忌。"
        case .evening: return "傍晚不宜出门太远，留在家里吧。"
        case .night: return "夜深了，做饭和出门改到明天；聊天、休息与亲密还可以。"
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
        guard state.timeOfDay.isActionAvailable(action) || action == .intimacy else {
            flash(state.timeOfDay.unavailableHint)
            append([DialogueLine(speaker: .system, text: "现在是\(state.timeOfDay.displayName)——\(state.timeOfDay.unavailableHint)")])
            save()
            return
        }
        let result = dialogue.resolveCareAction(
            action,
            character: character,
            giftsLeft: state.inventoryGifts,
            timeOfDay: state.timeOfDay
        )
        character = result.updatedCharacter
        if action == .gift && state.inventoryGifts > 0 {
            state.inventoryGifts -= 1
        }
        if action == .goOut {
            character.outfit = .outdoor
            character.currentRoom = .livingRoom
        }
        if action == .rest {
            character.currentRoom = .bedroom
            character.outfit = character.outfit.rank < OutfitState.home.rank ? .home : character.outfit
        }
        if action == .cook {
            character.currentRoom = .kitchen
        }
        state.character = character
        append(result.lines)
        advanceTimeLightly()
        save()
        flash(result.banner)
    }

    func performIntimacy(_ action: IntimacyAction) {
        guard var character = state.character else { return }
        guard state.timeOfDay.isActionAvailable(.intimacy) else {
            flash(state.timeOfDay.unavailableHint)
            append([DialogueLine(speaker: .character, text: dialogue.timeGatedIntimacy(for: character, time: state.timeOfDay))])
            save()
            return
        }
        let tier = character.stats.intimacyTier
        guard tier >= action.requiredTier else {
            flash("信任与好感还不够（需要：\(action.requiredTier.displayName)）")
            append([DialogueLine(speaker: .character, text: dialogue.intimacyRejected(for: character, action: action))])
            save()
            return
        }
        let result = dialogue.resolveIntimacy(action, character: character, timeOfDay: state.timeOfDay)
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
        let previous = character.currentRoom
        character.currentRoom = room
        if room == .bedroom && character.outfit == .outdoor {
            character.outfit = .home
        }
        if room == .bathroomDoor && character.outfit == .outdoor {
            character.outfit = .casual
        }
        state.character = character
        if previous != room {
            append([DialogueLine(
                speaker: .system,
                text: "来到\(room.displayName)。\(room.blurb)"
            ), DialogueLine(
                speaker: .character,
                text: dialogue.roomEnter(for: character, room: room, time: state.timeOfDay)
            )])
        }
        save()
    }

    func sendChat(topic: ChatTopic) {
        guard var character = state.character else { return }
        let result = dialogue.chat(topic: topic, character: character, timeOfDay: state.timeOfDay)
        character = result.updatedCharacter
        state.character = character
        append(result.lines)
        advanceTimeLightly()
        save()
    }

    /// 亲密场景写回角色（由 IntimacyView 调用）
    func applyIntimacyCharacter(_ character: Character) {
        state.character = character
        save()
    }

    func commitIntimacyScene(character: Character, lines: [DialogueLine], banner: String?) {
        state.character = character
        append(lines)
        // 高潮或较长场景推进时段
        if lines.contains(where: { $0.text.contains("缠绵结束") || $0.text.contains("场景结束") }) {
            advanceTimeLightly()
        }
        save()
        flash(banner)
    }

    func openIntimacySceneAllowed() -> Bool {
        guard let c = state.character else { return false }
        return IntimacySceneEngine().startGate(character: c) == nil && state.timeOfDay.isActionAvailable(.intimacy)
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
        let leaving = state.timeOfDay
        state.timeOfDay.advance()
        applyTimeTransition(from: leaving, to: state.timeOfDay)
        if state.timeOfDay == .morning {
            state.day += 1
            state.character?.relationshipDays += 1
            state.inventoryGifts = min(5, state.inventoryGifts + 1)
            if var c = state.character {
                c.stats.energy = min(100, c.stats.energy + 25)
                c.stats.hunger = min(100, c.stats.hunger + 15)
                c.stats.arousal = max(0, c.stats.arousal - 10)
                c.stats.clamp()
                state.character = c
                append([DialogueLine(
                    speaker: .system,
                    text: "新的一天开始了（第 \(state.day) 天）。礼物库存 +\(state.inventoryGifts > 0 ? 1 : 0)（当前 \(state.inventoryGifts)）。"
                )])
            }
        }
    }

    /// 时段切换对心情/精力的轻量影响
    private func applyTimeTransition(from: TimeOfDay, to: TimeOfDay) {
        guard var c = state.character else { return }
        switch to {
        case .morning:
            c.stats.mood += 4
        case .afternoon:
            c.stats.mood += 2
            c.stats.energy -= 3
        case .evening:
            c.stats.mood += 3
            c.stats.energy -= 5
            c.stats.hunger += 8
        case .night:
            c.stats.mood -= 2
            c.stats.energy -= 8
            if c.stats.affection > 40 {
                c.stats.arousal += 4
            }
        }
        c.stats.clamp()
        state.character = c
        _ = from
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
