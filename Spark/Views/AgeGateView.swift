import SwiftUI

struct AgeGateView: View {
    @EnvironmentObject private var gameStore: GameStore
    @State private var confirmedAdult = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.12, blue: 0.20),
                    Color(red: 0.35, green: 0.18, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Text("Spark")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("居家养成")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))

                VStack(alignment: .leading, spacing: 12) {
                    Text("18+ 内容警告")
                        .font(.headline)
                        .foregroundStyle(.pink)
                    Text("本游戏为成人向（18+）居家养成 / 恋爱互动模拟。角色均为 22–32 岁成年人，包含服装切换与亲密关系进程。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    Text("禁止未成年人游玩。继续即表示你已年满 18 周岁，并接受相关内容。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("画面使用风格化 2D 分层占位，不含写实器官特写。")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding()
                .background(.ultraThinMaterial.opacity(0.35))
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Toggle(isOn: $confirmedAdult) {
                    Text("我已年满 18 岁")
                        .foregroundStyle(.white)
                }
                .tint(.pink)
                .padding(.horizontal, 32)

                Button {
                    gameStore.acceptAgeGate()
                } label: {
                    Text("进入游戏")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(confirmedAdult ? Color.pink : Color.gray.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!confirmedAdult)
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }
}
