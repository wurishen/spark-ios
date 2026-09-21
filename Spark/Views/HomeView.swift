import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var gameStore: GameStore
    @State private var showOutfit = false
    @State private var showIntimacy = false
    @State private var showIntimacyScene = false
    @State private var showChatTopics = false
    @State private var showRoomPicker = false

    var body: some View {
        if let character = gameStore.state.character {
            ZStack(alignment: .top) {
                roomBackground(character.currentRoom)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar(character)
                    ScrollView {
                        VStack(spacing: 12) {
                            CharacterPortraitView(
                                character: character,
                                isSpeaking: isCharacterSpeaking
                            )
                            .padding(.top, 8)

                            statsStrip(character)

                            ChatPanel(messages: gameStore.chatLog)
                                .frame(minHeight: 160, maxHeight: 220)

                            ActionBar(
                                timeOfDay: gameStore.state.timeOfDay,
                                onAction: handleAction,
                                onOutfit: { showOutfit = true },
                                onPickRoom: { showRoomPicker = true }
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
            .sheet(isPresented: $showIntimacyScene) {
                IntimacyView()
                    .environmentObject(gameStore)
            }
            .confirmationDialog("亲密互动", isPresented: $showIntimacy, titleVisibility: .visible) {
                Button("进入亲密场景（推荐）") { showIntimacyScene = true }
                ForEach(IntimacyAction.allCases) { action in
                    Button(action.displayName) {
                        gameStore.performIntimacy(action)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("当前档位：\(character.stats.intimacyTier.displayName) · \(gameStore.state.timeOfDay.displayName)")
            }
            .confirmationDialog("聊什么？", isPresented: $showChatTopics, titleVisibility: .visible) {
                ForEach(topics(for: character)) { topic in
                    Button(topic.title) {
                        gameStore.sendChat(topic: topic)
                    }
                }
                Button("取消", role: .cancel) {}
            }
            .confirmationDialog("去哪个房间？", isPresented: $showRoomPicker, titleVisibility: .visible) {
                ForEach(RoomScene.allCases) { room in
                    Button("\(room.displayName)") {
                        gameStore.switchRoom(room)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text(character.currentRoom.blurb)
            }
        }
    }

    private var isCharacterSpeaking: Bool {
        gameStore.chatLog.last?.speaker == .character
    }

    private func topics(for character: Character) -> [ChatTopic] {
        ChatTopic.topics(for: gameStore.state.timeOfDay, likes: character.likes, intimacyTier: character.stats.intimacyTier, arousal: character.stats.arousal)
    }

    private func handleAction(_ action: CareAction) {
        switch action {
        case .chat:
            showChatTopics = true
        case .intimacy:
            if gameStore.openIntimacySceneAllowed() {
                showIntimacyScene = true
            } else {
                showIntimacy = true
            }
        default:
            gameStore.perform(action)
        }
    }

    private func topBar(_ c: Character) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(c.name)
                    .font(.headline)
                Text("\(c.age) 岁 · \(c.occupation) · 第 \(gameStore.state.day) 天 · \(gameStore.state.timeOfDay.emoji)\(gameStore.state.timeOfDay.displayName) · \(c.currentRoom.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("切换房间") { showRoomPicker = true }
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
            Text("喜好：\(c.likes.joined(separator: "、")) · 礼物×\(gameStore.state.inventoryGifts)")
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
            case .kitchen:
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.97, blue: 0.88), Color(red: 0.95, green: 0.90, blue: 0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .bathroomDoor:
                LinearGradient(
                    colors: [Color(red: 0.88, green: 0.94, blue: 0.96), Color(red: 0.78, green: 0.86, blue: 0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}
