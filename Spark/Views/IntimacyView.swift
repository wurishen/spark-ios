import SwiftUI

/// 多步亲密场景面板：选择推进 / 温柔 / 暂停 / 停止
struct IntimacyView: View {
    @EnvironmentObject private var gameStore: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var session = IntimacySession(step: .kiss, beatsCompleted: 0, refused: false, finished: false)
    @State private var log: [DialogueLine] = []
    @State private var currentBeat: IntimacyBeat?
    private let engine = IntimacySceneEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.18, green: 0.10, blue: 0.20), Color(red: 0.35, green: 0.16, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if let character = gameStore.state.character {
                    VStack(spacing: 12) {
                        CharacterPortraitView(
                            character: character,
                            isSpeaking: log.last?.speaker == .character,
                            height: 280
                        )

                        stepHeader

                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(log) { line in
                                        bubble(line).id(line.id)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(maxHeight: 180)
                            .onChange(of: log.count) { _, _ in
                                if let last = log.last {
                                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                                }
                            }
                        }

                        if session.finished {
                            finishedBar
                        } else if let beat = currentBeat {
                            choicesBar(beat, character: character)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("亲密场景")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .onAppear { begin() }
        }
    }

    private var stepHeader: some View {
        HStack {
            Text(session.step.displayName)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Text("步骤 \(session.step.rawValue + 1)/4")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal)
    }

    private func choicesBar(_ beat: IntimacyBeat, character: Character) -> some View {
        VStack(spacing: 8) {
            ForEach(beat.choices) { choice in
                Button {
                    pick(choice, beat: beat)
                } label: {
                    Text(choice.title)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(choiceColor(choice.kind))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal)
    }

    private var finishedBar: some View {
        VStack(spacing: 10) {
            Text(session.refused ? "她想慢一点——被尊重也是亲密的一部分。" : "场景结束。可以继续同居日常。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            Button("回到房间") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
        }
        .padding()
    }

    private func choiceColor(_ kind: IntimacyChoice.Kind) -> Color {
        switch kind {
        case .advance: return Color.pink.opacity(0.9)
        case .soft: return Color.purple.opacity(0.85)
        case .pause: return Color.indigo.opacity(0.8)
        case .stop: return Color.gray.opacity(0.7)
        }
    }

    private func bubble(_ line: DialogueLine) -> some View {
        HStack {
            if line.speaker == .player { Spacer(minLength: 24) }
            Text(line.text)
                .font(.footnote)
                .padding(10)
                .background(line.speaker == .player ? Color.pink.opacity(0.85) : Color.white.opacity(0.92))
                .foregroundStyle(line.speaker == .player ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            if line.speaker != .player { Spacer(minLength: 24) }
        }
    }

    private func begin() {
        guard var character = gameStore.state.character else { return }
        if let gate = engine.startGate(character: character) {
            log = [DialogueLine(speaker: .character, text: gate)]
            session.finished = true
            session.refused = true
            return
        }
        character.currentRoom = .bedroom
        gameStore.applyIntimacyCharacter(character)
        let beat = engine.beat(for: .kiss, character: character)
        currentBeat = beat
        log = [
            DialogueLine(speaker: .system, text: "亲密场景开始。可随时暂停。所有角色均为成年（22–32）。"),
            DialogueLine(speaker: .system, text: beat.narration),
            DialogueLine(speaker: .character, text: beat.herLine)
        ]
    }

    private func pick(_ choice: IntimacyChoice, beat: IntimacyBeat) {
        guard var character = gameStore.state.character else { return }
        var sess = session
        let result = engine.applyChoice(choice, beat: beat, character: &character, session: &sess)
        session = sess
        log.append(contentsOf: result.lines)
        gameStore.commitIntimacyScene(character: character, lines: result.lines, banner: result.banner)

        if session.finished {
            currentBeat = nil
            return
        }
        let nextBeat = engine.beat(for: session.step, character: character)
        currentBeat = nextBeat
        if choice.kind == .advance || choice.kind == .soft {
            log.append(DialogueLine(speaker: .system, text: nextBeat.narration))
            log.append(DialogueLine(speaker: .character, text: nextBeat.herLine))
        }
    }
}
