import SwiftUI

struct ChatPanel: View {
    let messages: [DialogueLine]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { line in
                        bubble(line)
                            .id(line.id)
                    }
                }
                .padding(10)
            }
            .background(Color.black.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func bubble(_ line: DialogueLine) -> some View {
        HStack {
            if line.speaker == .player { Spacer(minLength: 40) }
            Text(line.text)
                .font(.subheadline)
                .padding(10)
                .background(bg(line.speaker))
                .foregroundStyle(fg(line.speaker))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if line.speaker != .player { Spacer(minLength: 40) }
        }
    }

    private func bg(_ s: DialogueSpeaker) -> Color {
        switch s {
        case .player: return Color.pink.opacity(0.85)
        case .character: return Color.white.opacity(0.95)
        case .system: return Color.gray.opacity(0.25)
        }
    }

    private func fg(_ s: DialogueSpeaker) -> Color {
        switch s {
        case .player: return .white
        case .character, .system: return .primary
        }
    }
}
