import SwiftUI
import UIKit

/// 日漫立ち絵 + SwiftUI live idle。便装/居家→casual；内衣→lingerie；裸身→程序化柔和剪影。
struct CharacterPortraitView: View {
    let character: Character
    var isSpeaking: Bool = false
    var height: CGFloat = 380

    private var skin: Color { Color(hex: character.appearance.skinTone) }
    private var hair: Color { Color(hex: character.appearance.hairColor) }
    private var eyes: Color { Color(hex: character.appearance.eyeColor) }
    private var underwear: Color { Color(hex: character.appearance.underwearColor) }

    @State private var breathPhase: CGFloat = 0
    @State private var swayPhase: CGFloat = 0
    @State private var blinkOpacity: CGFloat = 0
    @State private var speakBob: CGFloat = 0
    @State private var shadowPulse: CGFloat = 0.35

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.14 + shadowPulse * 0.08))
                .frame(width: height * 0.42 * (0.95 + breathScale * 0.05), height: height * 0.05)
                .offset(y: height * 0.46)
                .blur(radius: 4)
                .zIndex(0)

            Group {
                if let art = animeArt {
                    ZStack {
                        art
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: height)
                        if blinkOpacity > 0.01 {
                            blinkCapsules
                        }
                    }
                } else {
                    proceduralPortrait
                }
            }
            .scaleEffect(x: 1.0 + (breathScale - 1.0) * 0.35, y: breathScale, anchor: .bottom)
            .rotationEffect(.degrees(swayDegrees), anchor: .bottom)
            .offset(y: speakBob)
            .zIndex(1)

            VStack {
                Spacer()
                HStack(spacing: 6) {
                    Text(character.outfit.displayName)
                    if isSpeaking { Image(systemName: "waveform").font(.caption2) }
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 8)
            }
            .zIndex(10)
        }
        .frame(width: height * 0.62, height: height)
        .accessibilityLabel("\(character.name) 的立绘，当前服装：\(character.outfit.displayName)")
        .onAppear { startIdleLoops() }
        .onChange(of: isSpeaking) { _, speaking in
            if speaking { runSpeakBob() }
        }
    }

    private var animeArt: Image? {
        switch character.outfit {
        case .casual, .home:
            if UIImage(named: "PortraitCasual") != nil { return Image("PortraitCasual") }
            return EmbeddedPortrait.casualImage
        case .underwear:
            if UIImage(named: "PortraitLingerie") != nil { return Image("PortraitLingerie") }
            if UIImage(named: "PortraitUnderwear") != nil { return Image("PortraitUnderwear") }
            return EmbeddedPortrait.lingerieImage
        case .outdoor, .nude:
            return nil
        }
    }

    private var blinkCapsules: some View {
        VStack {
            Spacer().frame(height: height * 0.22)
            HStack(spacing: height * 0.06) {
                Capsule().fill(Color.black.opacity(0.55 * blinkOpacity))
                    .frame(width: height * 0.07, height: height * 0.012 * blinkOpacity)
                Capsule().fill(Color.black.opacity(0.55 * blinkOpacity))
                    .frame(width: height * 0.07, height: height * 0.012 * blinkOpacity)
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private var breathScale: CGFloat { 1.0 + 0.015 * (0.5 + 0.5 * sin(breathPhase)) }
    private var swayDegrees: Double { Double(2.0 * sin(swayPhase)) }

    private func startIdleLoops() {
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { breathPhase = .pi }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { swayPhase = .pi }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { shadowPulse = 0.7 }
        scheduleBlink()
    }

    private func scheduleBlink() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3.0...5.0)) {
            runBlink(); scheduleBlink()
        }
    }

    private func runBlink() {
        withAnimation(.easeIn(duration: 0.08)) { blinkOpacity = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.12)) { blinkOpacity = 0 }
        }
        if Double.random(in: 0...1) < 0.22 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                withAnimation(.easeIn(duration: 0.07)) { blinkOpacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                    withAnimation(.easeOut(duration: 0.10)) { blinkOpacity = 0 }
                }
            }
        }
    }

    private func runSpeakBob() {
        withAnimation(.easeInOut(duration: 0.18)) { speakBob = -4 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeInOut(duration: 0.18)) { speakBob = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard isSpeaking else { return }
            withAnimation(.easeInOut(duration: 0.15)) { speakBob = -3 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) { speakBob = 0 }
            }
        }
    }

    private var proceduralPortrait: some View {
        ZStack {
            bodyLayer.zIndex(1)
            if character.outfit.showsNudeSilhouette {
                softAnimeNude.zIndex(2)
            } else if character.outfit.showsUnderwear {
                underwearLayer.zIndex(3)
            }
            if character.outfit.showsOuterClothes {
                clothesLayer.zIndex(4)
            }
            headLayer.zIndex(5)
            if blinkOpacity > 0.01 {
                Canvas { ctx, size in
                    let w = size.width; let h = size.height
                    for dx in [w * 0.40, w * 0.54] {
                        let lid = Path(roundedRect: CGRect(x: dx, y: h * 0.17 + 4, width: 14, height: 3 * blinkOpacity), cornerRadius: 2)
                        ctx.fill(lid, with: .color(skin.opacity(0.95 * blinkOpacity)))
                    }
                }.zIndex(6).allowsHitTesting(false)
            }
        }
    }

    private var softAnimeNude: some View {
        Canvas { context, size in
            let w = size.width; let h = size.height
            for dx in [w * 0.38, w * 0.50] {
                let e = Path(ellipseIn: CGRect(x: dx, y: h * 0.38, width: 22, height: 16))
                context.fill(e, with: .color(skin.opacity(0.55)))
                context.stroke(e, with: .color(Color.white.opacity(0.2)), lineWidth: 1)
            }
            let waist = Path(roundedRect: CGRect(x: w * 0.36, y: h * 0.48, width: w * 0.28, height: 6), cornerRadius: 3)
            context.fill(waist, with: .color(skin.opacity(0.35)))
            let soft = Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.54, width: 20, height: 12))
            context.fill(soft, with: .color(Color.pink.opacity(0.18)))
        }
        .overlay(alignment: .bottom) {
            Text("剪影 · 二次元软表现")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .padding(.bottom, 28)
        }
    }

    private var bodyLayer: some View {
        Canvas { context, size in
            let w = size.width; let h = size.height
            context.fill(Path(roundedRect: CGRect(x: w * 0.32, y: h * 0.28, width: w * 0.36, height: h * 0.38), cornerRadius: 28), with: .color(skin))
            context.fill(Path(roundedRect: CGRect(x: w * 0.36, y: h * 0.62, width: w * 0.12, height: h * 0.30), cornerRadius: 16), with: .color(skin))
            context.fill(Path(roundedRect: CGRect(x: w * 0.52, y: h * 0.62, width: w * 0.12, height: h * 0.30), cornerRadius: 16), with: .color(skin))
            context.fill(Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.32, width: w * 0.12, height: h * 0.28), cornerRadius: 14), with: .color(skin.opacity(0.95)))
            context.fill(Path(roundedRect: CGRect(x: w * 0.70, y: h * 0.32, width: w * 0.12, height: h * 0.28), cornerRadius: 14), with: .color(skin.opacity(0.95)))
        }
    }

    private var underwearLayer: some View {
        Canvas { context, size in
            let w = size.width; let h = size.height
            context.fill(Path(roundedRect: CGRect(x: w * 0.34, y: h * 0.36, width: w * 0.32, height: h * 0.07), cornerRadius: 10), with: .color(underwear.opacity(0.9)))
            context.fill(Path(roundedRect: CGRect(x: w * 0.40, y: h * 0.52, width: w * 0.20, height: h * 0.06), cornerRadius: 8), with: .color(underwear.opacity(0.85)))
        }
    }

    private var clothesLayer: some View {
        Canvas { context, size in
            let w = size.width; let h = size.height
            context.fill(Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.30, width: w * 0.44, height: h * 0.42), cornerRadius: 20), with: .color(character.outfit.clothColor))
            if character.outfit == .outdoor {
                context.fill(Path(roundedRect: CGRect(x: w * 0.40, y: h * 0.34, width: w * 0.20, height: 8), cornerRadius: 4), with: .color(Color.white.opacity(0.3)))
            }
        }
    }

    private var headLayer: some View {
        Canvas { context, size in
            let w = size.width; let h = size.height
            context.fill(Path(ellipseIn: CGRect(x: w * 0.28, y: h * 0.02, width: w * 0.44, height: h * 0.28)), with: .color(hair))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.34, y: h * 0.08, width: w * 0.32, height: h * 0.22)), with: .color(skin))
            let eyeY = h * 0.16
            for dx in [w * 0.40, w * 0.54] {
                context.fill(Path(ellipseIn: CGRect(x: dx, y: eyeY, width: 14, height: 16)), with: .color(eyes))
                context.fill(Path(ellipseIn: CGRect(x: dx + 3, y: eyeY + 2, width: 4, height: 5)), with: .color(.white.opacity(0.85)))
            }
            let mouthH: CGFloat = isSpeaking ? 6 : 4
            context.fill(Path(roundedRect: CGRect(x: w * 0.46, y: h * 0.24, width: 12, height: mouthH), cornerRadius: 2), with: .color(Color.pink.opacity(0.75)))
            context.fill(Path(roundedRect: CGRect(x: w * 0.32, y: h * 0.06, width: w * 0.36, height: h * 0.06), cornerRadius: 8), with: .color(hair))
        }
    }
}
