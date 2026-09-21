import SwiftUI

/// 程序化分层立绘：身体 → 内衣 → 外衣 → 头发/面部
/// v0.1 使用几何色块占位；正式立绘可替换为 Image 图层
struct CharacterPortraitView: View {
    let character: Character
    var height: CGFloat = 380

    private var skin: Color { Color(hex: character.appearance.skinTone) }
    private var hair: Color { Color(hex: character.appearance.hairColor) }
    private var eyes: Color { Color(hex: character.appearance.eyeColor) }
    private var underwear: Color { Color(hex: character.appearance.underwearColor) }

    var body: some View {
        ZStack {
            // 身体（底层）
            bodyLayer
                .zIndex(1)

            // 裸身剪影软性指示（非写实）
            if character.outfit.showsNudeSilhouette {
                nudeSoftIndicators
                    .zIndex(2)
            }

            // 内衣层
            if character.outfit.showsUnderwear && !character.outfit.showsNudeSilhouette {
                underwearLayer
                    .zIndex(3)
            } else if character.outfit == .nude {
                // nude: no underwear
            }

            // 外衣层
            if character.outfit.showsOuterClothes {
                clothesLayer
                    .zIndex(4)
            }

            // 头 / 发 / 脸（顶层）
            headLayer
                .zIndex(5)

            // 服装标签
            VStack {
                Spacer()
                Text(character.outfit.displayName)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
            }
            .zIndex(6)
        }
        .frame(width: height * 0.55, height: height)
        .accessibilityLabel("\(character.name) 的立绘，当前服装：\(character.outfit.displayName)")
    }

    private var bodyLayer: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: height * 0.22)
            // 躯干
            RoundedRectangle(cornerRadius: 28)
                .fill(skin)
                .frame(width: height * 0.28, height: height * 0.38)
            // 腿
            HStack(spacing: 10) {
                Capsule().fill(skin).frame(width: height * 0.09, height: height * 0.28)
                Capsule().fill(skin).frame(width: height * 0.09, height: height * 0.28)
            }
            .offset(y: -8)
        }
    }

    /// 软性非写实身体提示（椭圆剪影）
    private var nudeSoftIndicators: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: height * 0.30)
            HStack(spacing: 22) {
                Ellipse()
                    .fill(skin.opacity(0.55))
                    .overlay(Ellipse().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    .frame(width: 22, height: 16)
                Ellipse()
                    .fill(skin.opacity(0.55))
                    .overlay(Ellipse().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    .frame(width: 22, height: 16)
            }
            Capsule()
                .fill(Color.pink.opacity(0.25))
                .frame(width: 18, height: 10)
                .overlay(
                    Text("TODO: 正式立绘")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                        .offset(y: 16)
                )
            Spacer()
        }
    }

    private var underwearLayer: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: height * 0.32)
            // 上衣/文胸示意
            Capsule()
                .fill(underwear.opacity(0.9))
                .frame(width: height * 0.26, height: height * 0.08)
            Spacer().frame(height: height * 0.10)
            // 下装示意
            RoundedRectangle(cornerRadius: 8)
                .fill(underwear.opacity(0.85))
                .frame(width: height * 0.16, height: height * 0.07)
            Spacer()
        }
    }

    private var clothesLayer: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: height * 0.28)
            RoundedRectangle(cornerRadius: 20)
                .fill(character.outfit.clothColor)
                .frame(width: height * 0.32, height: height * 0.42)
                .overlay(alignment: .top) {
                    if character.outfit == .outdoor {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 40, height: 10)
                            .padding(.top, 16)
                    }
                }
            Spacer()
        }
    }

    private var headLayer: some View {
        VStack(spacing: 0) {
            // 头发后层
            Ellipse()
                .fill(hair)
                .frame(width: height * 0.30, height: height * 0.28)
                .offset(y: height * 0.02)
            // 脸
            ZStack {
                Ellipse()
                    .fill(skin)
                    .frame(width: height * 0.22, height: height * 0.24)
                // 眼睛
                HStack(spacing: 18) {
                    Capsule().fill(eyes).frame(width: 8, height: 10)
                    Capsule().fill(eyes).frame(width: 8, height: 10)
                }
                .offset(y: -4)
                // 嘴
                Capsule()
                    .fill(Color.pink.opacity(0.7))
                    .frame(width: 14, height: 5)
                    .offset(y: 16)
            }
            .offset(y: -height * 0.16)
            // 头发前刘海
            Capsule()
                .fill(hair)
                .frame(width: height * 0.24, height: height * 0.06)
                .offset(y: -height * 0.30)
            Spacer()
        }
    }
}
