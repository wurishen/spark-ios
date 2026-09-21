import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var gameStore: GameStore
    @State private var showOutfit = false
    @State private var showIntimacy = false
    @State private var showChatTopics = false

    var body: some View {
        if let character = gameStore.state.character {
            ZStack(alignment: .top) {
                roomBackground(character.currentRoom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar(character)
                    ScrollView {
                        VStack(spacing: 12) {
                            CharacterPortraitView(character: character)
                                .padding(.top, 8)

                            statsStrip(character)

                            ChatPanel(messages: gameStore.chatLog)
                                .frame(minHeight: 160, maxHeight: 220)

                            ActionBar(
                                onAction: handleAction,
                                onOutfit: { showOutfit = true },
                                onRoomToggle: toggleRoom
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }

                if let banner = gameStore.statusBanner {
                    Text(banner)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.top, 56)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showOutfit) {
                OutfitSheet(character: character) { outfit in
                    gameStore.setOutfit(outfit)
                    showOutfit = false
                }
            }
            .confirmationDialog("亲密互动", isPresented: $showIntimacy, titleVisibility: .visible) {
                ForEach(IntimacyAction.allCases) { action in
                    Button(action.displayName) {
                        gameStore.performIntimacy(action)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("当前档位：\(character.stats.intimacyTier.displayName)")
            }
            .confirmationDialog("聊什么？", isPresented: $showChatTopics, titleVisibility: .visible) {
                ForEach(topics) { topic in
                    Button(topic.title) {
                        gameStore.sendChat(topic: topic)
                    }
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private var topics: [ChatTopic] {
        [
            ChatTopic(id: "1", title: "今天过得怎么样？", category: .daily),
            ChatTopic(id: "2", title: "聊聊手冲咖啡", category: .hobby),
            ChatTopic(id: "3", title: "想听你的感受", category: .feelings),
            ChatTopic(id: "4", title: "你以前的生活", category: .past),
            ChatTopic(id: "5", title: "你今天很好看", category: .flirt)
        ]
    }

    private func handleAction(_ action: CareAction) {
        switch action {
        case .chat:
            showChatTopics = true
        case .intimacy:
            showIntimacy = true
        default:
            gameStore.perform(action)
        }
    }

    private func toggleRoom() {
        guard let c = gameStore.state.character else { return }
        let next: RoomScene = c.currentRoom == .livingRoom ? .bedroom : .livingRoom
        gameStore.switchRoom(next)
    }

    private func topBar(_ c: Character) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(c.name)
                    .font(.headline)
                Text("\(c.age) 岁 · \(c.occupation) · 第 \(gameStore.state.day) 天 · \(gameStore.state.timeOfDay.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("切换房间") { toggleRoom() }
                Button("换装") { showOutfit = true }
                Divider()
                Button("重置存档", role: .destructive) {
                    gameStore.resetAll()
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.pink)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func statsStrip(_ c: Character) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(c.traitsSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                statLabel("心情", c.stats.mood, .orange)
                statLabel("好感", c.stats.affection, .pink)
                statLabel("信任", c.stats.trust, .blue)
                statLabel("亲密", c.stats.arousal, .purple)
                statLabel("精力", c.stats.energy, .green)
                statLabel("饥饿", c.stats.hunger, .brown)
            }
            Text("喜好：\(c.likes.joined(separator: "、"))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statLabel(_ title: String, _ value: Double, _ color: Color) -> some View {
        HStack {
            Text(title)
                .font(.caption2)
                .frame(width: 28, alignment: .leading)
            ProgressView(value: value, total: 100)
                .tint(color)
            Text("\(Int(value))")
                .font(.caption2.monospacedDigit())
                .frame(width: 24, alignment: .trailing)
        }
    }

    private func roomBackground(_ room: RoomScene) -> some View {
        Group {
            switch room {
            case .livingRoom:
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.95, blue: 0.90), Color(red: 0.92, green: 0.88, blue: 0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .bedroom:
                LinearGradient(
                    colors: [Color(red: 0.20, green: 0.16, blue: 0.28), Color(red: 0.40, green: 0.22, blue: 0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}
