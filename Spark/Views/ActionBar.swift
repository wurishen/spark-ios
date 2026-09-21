import SwiftUI

struct ActionBar: View {
    var onAction: (CareAction) -> Void
    var onOutfit: () -> Void
    var onRoomToggle: () -> Void

    private let actions: [CareAction] = [.chat, .cook, .gift, .rest, .goOut, .intimacy]

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(actions) { action in
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
                        .background(action == .intimacy ? Color.pink.opacity(0.85) : Color.white.opacity(0.9))
                        .foregroundStyle(action == .intimacy ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
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
                    onRoomToggle()
                } label: {
                    Label("切换房间", systemImage: "door.left.hand.open")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.teal.opacity(0.85))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}
