import SwiftUI

struct ActionBar: View {
    var timeOfDay: TimeOfDay
    var onAction: (CareAction) -> Void
    var onOutfit: () -> Void
    var onPickRoom: () -> Void

    private let actions: [CareAction] = [.chat, .cook, .gift, .rest, .goOut, .intimacy]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(timeOfDay.emoji) \(timeOfDay.displayName)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(timeOfDay.unavailableHint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(actions) { action in
                    let enabled = timeOfDay.isActionAvailable(action)
                    Button {
                        onAction(action)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: action.systemImage)
                            Text(action.displayName)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(bg(action, enabled: enabled))
                        .foregroundStyle(fg(action, enabled: enabled))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(enabled ? 1 : 0.45)
                    }
                    .disabled(!enabled && action != .intimacy)
                }
            }

            HStack(spacing: 8) {
                Button {
                    onOutfit()
                } label: {
                    Label("换装", systemImage: "tshirt.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.indigo.opacity(0.85))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button {
                    onPickRoom()
                } label: {
                    Label("房间", systemImage: "door.left.hand.open")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.teal.opacity(0.85))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private func bg(_ action: CareAction, enabled: Bool) -> Color {
        if action == .intimacy { return Color.pink.opacity(enabled ? 0.85 : 0.4) }
        return Color.white.opacity(0.9)
    }

    private func fg(_ action: CareAction, enabled: Bool) -> Color {
        if action == .intimacy { return .white }
        return .primary
    }
}
