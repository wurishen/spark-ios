import SwiftUI

struct OutfitSheet: View {
    let character: Character
    var onSelect: (OutfitState) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("服装按层次渐进：外出装 → 便装 → 居家服 → 内衣 → 裸身剪影。内衣与裸身受好感/信任门控。裸身为风格化剪影，不含写实器官特写。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("选择服装") {
                    ForEach(OutfitState.allCases) { outfit in
                        Button {
                            onSelect(outfit)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(outfit.displayName)
                                        .foregroundStyle(.primary)
                                    if !outfit.isUnlocked(stats: character.stats) {
                                        Text("需 好感≥\(Int(outfit.requiredAffection)) · 信任≥\(Int(outfit.requiredTrust))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if character.outfit == outfit {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.pink)
                                } else if !outfit.isUnlocked(stats: character.stats) {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("换装")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
