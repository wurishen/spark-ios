import SwiftUI

struct CharacterIntroView: View {
    @EnvironmentObject private var gameStore: GameStore
    @State private var isGenerating = false

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.94, blue: 0.92).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("迎接新室友")
                    .font(.largeTitle.bold())
                Text("系统将随机生成一位成年女性室友/伴侣（22–32 岁），包含性格、喜好与初始数值。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Button {
                    isGenerating = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        gameStore.generateNewCharacter()
                        isGenerating = false
                    }
                } label: {
                    HStack {
                        if isGenerating { ProgressView() }
                        Text(isGenerating ? "生成中…" : "随机生成角色")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isGenerating)
                .padding(.horizontal, 40)
            }
        }
    }
}
