import Foundation

/// 多步亲密剧本：性格分支 + 门控拒绝 + 服装推进
struct IntimacySceneEngine {

    func startGate(character: Character) -> String? {
        let tier = character.stats.intimacyTier
        if tier < .close {
            return "她轻轻摇头：「再多陪陪我……现在还太早。」（需要亲密档位：亲近）"
        }
        if character.stats.trust < 35 {
            return "她握住你的手，却没有更近：「信任还差一点。今晚先抱抱就好。」"
        }
        if character.stats.energy < 20 {
            return "她打了个哈欠：「好累……明天再好吗？」"
        }
        return nil
    }

    func beat(for step: IntimacyStep, character: Character) -> IntimacyBeat {
        switch step {
        case .kiss:
            return kissBeat(character)
        case .caress:
            return caressBeat(character)
        case .undressAssist:
            return undressBeat(character)
        case .climax:
            return climaxBeat(character)
        }
    }

    func refusalLine(character: Character, step: IntimacyStep) -> String {
        if character.personalityTraits.contains(.shy) {
            return "她耳朵发烫，却把你的手轻轻推开：「\(step.displayName)……再等一等，好吗？我想更安心一点。」"
        }
        if character.personalityTraits.contains(.independent) {
            return "她直视你：「进度由我来定。\(step.displayName)还不是现在。」"
        }
        return "她吻了吻你的额头：「想要，但还不到。我们把气氛留着。」"
    }

    // MARK: - Beats

    private func kissBeat(_ c: Character) -> IntimacyBeat {
        let her: String
        if c.personalityTraits.contains(.romantic) {
            her = "唇瓣相触的瞬间，她闭着眼，睫毛轻颤：「别急……让我记住这一秒。」"
        } else if c.personalityTraits.contains(.shy) {
            her = "她呼吸乱了一拍，声音发软：「嗯……再、再靠近一点也没关系。」"
        } else if c.personalityTraits.contains(.playful) {
            her = "她笑着咬了一下你的下唇：「哦？今晚这么主动？」"
        } else {
            her = "她回吻你，掌心贴在你胸口：「味道是安心的。」"
        }
        return IntimacyBeat(
            step: .kiss,
            narration: "灯光偏暗。你托起她的脸，缓慢地吻下去——没有急促，只有呼吸交叠。",
            herLine: her,
            choices: [
                IntimacyChoice(id: "k1", title: "加深这个吻", kind: .advance),
                IntimacyChoice(id: "k2", title: "吻她的颈侧", kind: .soft),
                IntimacyChoice(id: "k3", title: "先停一下，对视", kind: .pause),
                IntimacyChoice(id: "k0", title: "今晚到此为止", kind: .stop)
            ],
            outfitHint: nil,
            deltaAffection: 3, deltaTrust: 2, deltaArousal: 12, deltaMood: 4, deltaEnergy: -4
        )
    }

    private func caressBeat(_ c: Character) -> IntimacyBeat {
        let her: String
        if c.personalityTraits.contains(.shy) {
            her = "她抓住你的衣角，小声：「手……可以再慢一点。我、我没有要你停。」"
        } else if c.personalityTraits.contains(.romantic) {
            her = "她弓起背，气息喷在你耳边：「你的指尖像在写只有我能读的句子……」"
        } else if c.personalityTraits.contains(.witty) {
            her = "她喘着笑：「评分上涨中……别得意，继续。」"
        } else {
            her = "她的呼吸明显乱了：「再往上一点……对，就是那里。」"
        }
        return IntimacyBeat(
            step: .caress,
            narration: "吻沿着下颌滑向锁骨。你的手隔着衣料描过她的腰线与胸口——风格化、温柔，不急于揭开全部。",
            herLine: her,
            choices: [
                IntimacyChoice(id: "c1", title: "继续爱抚，升温", kind: .advance),
                IntimacyChoice(id: "c2", title: "问她舒不舒服", kind: .soft),
                IntimacyChoice(id: "c3", title: "只抱抱，降一点速", kind: .pause),
                IntimacyChoice(id: "c0", title: "停下来", kind: .stop)
            ],
            outfitHint: c.outfit.rank < OutfitState.home.rank ? .home : nil,
            deltaAffection: 4, deltaTrust: 2, deltaArousal: 18, deltaMood: 5, deltaEnergy: -6
        )
    }

    private func undressBeat(_ c: Character) -> IntimacyBeat {
        let unlockedUnderwear = OutfitState.underwear.isUnlocked(stats: c.stats)
        let unlockedNude = OutfitState.nude.isUnlocked(stats: c.stats)
        let her: String
        if !unlockedUnderwear {
            her = "她按住你的手，脸红但坚定：「衣服……再留一层。好感再深一点，我愿意为你宽衣。」"
        } else if c.personalityTraits.contains(.shy) {
            her = "她别过脸，却把肩带轻轻滑下：「别一直盯着看啦……但，你可以帮我。」"
        } else if c.personalityTraits.contains(.playful) {
            her = "她引导你的手指到扣子上：「自己来太慢——今晚你负责。」"
        } else {
            her = "布料落地的声音很轻。她看着你：「只给你看的样子。」"
        }
        let hint: OutfitState? = {
            if unlockedNude && c.stats.arousal >= 50 { return .nude }
            if unlockedUnderwear { return .underwear }
            return c.outfit.rank < OutfitState.home.rank ? .home : nil
        }()
        return IntimacyBeat(
            step: .undressAssist,
            narration: unlockedUnderwear
                ? "你帮她解开衣扣。日漫剪影的身体线条在暖光里起伏——柔和、非写实，像 galgame 的立ち絵换装。"
                : "你想帮她宽衣，她却把你的手按在心口。关系还差半步，今晚适可而止地亲密。",
            herLine: her,
            choices: unlockedUnderwear ? [
                IntimacyChoice(id: "u1", title: "温柔地继续宽衣", kind: .advance),
                IntimacyChoice(id: "u2", title: "亲吻她的肩，不急", kind: .soft),
                IntimacyChoice(id: "u3", title: "盖上薄毯，只拥抱", kind: .pause),
                IntimacyChoice(id: "u0", title: "停下来", kind: .stop)
            ] : [
                IntimacyChoice(id: "u2", title: "尊重她，改为深吻拥抱", kind: .soft),
                IntimacyChoice(id: "u3", title: "盖上薄毯休息", kind: .pause),
                IntimacyChoice(id: "u0", title: "今晚到此为止", kind: .stop)
            ],
            outfitHint: hint,
            deltaAffection: unlockedUnderwear ? 5 : 2,
            deltaTrust: unlockedUnderwear ? 3 : 4,
            deltaArousal: unlockedUnderwear ? 22 : 8,
            deltaMood: 4,
            deltaEnergy: -8
        )
    }

    private func climaxBeat(_ c: Character) -> IntimacyBeat {
        let her: String
        if c.personalityTraits.contains(.romantic) {
            her = "她把脸埋进你颈窝，声音断续：「就这样……别离开。今晚的呼吸，都留给彼此。」"
        } else if c.personalityTraits.contains(.shy) {
            her = "她眼角带潮，却主动环住你：「我、我还想要你更近……请、请温柔一点。」"
        } else if c.personalityTraits.contains(.playful) {
            her = "她喘着笑，腿缠上来：「门锁好了吧？那就别让我一个人先到。」"
        } else if c.personalityTraits.contains(.caring) {
            her = "她抚摸你的后背：「你也舒服吗？我们一起……慢慢来。」"
        } else {
            her = "她与你十指交扣，腰身迎上来：「现在……我是你的。」"
        }
        let nudeOk = OutfitState.nude.isUnlocked(stats: c.stats)
        return IntimacyBeat(
            step: .climax,
            narration: """
            窗帘拉上。两具身体贴近——画面保持日漫 galgame 式剪影与柔光，没有写实器官特写。\
            节奏由慢到密，喘息、低语与床单的细响交织；高潮来临时她绷紧又松开，像把一整晚的思念都还给你。
            """,
            herLine: her,
            choices: [
                IntimacyChoice(id: "x1", title: "相拥余韵，低声说爱", kind: .advance),
                IntimacyChoice(id: "x2", title: "帮她盖好被子", kind: .soft),
                IntimacyChoice(id: "x0", title: "结束场景", kind: .stop)
            ],
            outfitHint: nudeOk ? .nude : (OutfitState.underwear.isUnlocked(stats: c.stats) ? .underwear : nil),
            deltaAffection: 8, deltaTrust: 5, deltaArousal: 28, deltaMood: 10, deltaEnergy: -22
        )
    }

    func applyChoice(
        _ choice: IntimacyChoice,
        beat: IntimacyBeat,
        character: inout Character,
        session: inout IntimacySession
    ) -> (lines: [DialogueLine], banner: String?) {
        switch choice.kind {
        case .stop:
            session.finished = true
            character.stats.arousal = max(0, character.stats.arousal - 8)
            character.stats.clamp()
            return ([
                DialogueLine(speaker: .player, text: choice.title),
                DialogueLine(speaker: .character, text: "她点点头，整理呼吸：「嗯。被尊重的感觉……我也喜欢。」")
            ], "亲密暂停")
        case .pause:
            character.stats.affection += 2
            character.stats.trust += 3
            character.stats.arousal = max(0, character.stats.arousal - 5)
            character.stats.mood += 3
            character.stats.clamp()
            session.finished = true
            return ([
                DialogueLine(speaker: .player, text: choice.title),
                DialogueLine(speaker: .character, text: "她靠在你肩上：「这样就好。我们不急。」")
            ], "温柔刹车 · 信任↑")
        case .soft, .advance:
            character.stats.affection += beat.deltaAffection
            character.stats.trust += beat.deltaTrust
            character.stats.arousal += beat.deltaArousal + (choice.kind == .soft ? -4 : 2)
            character.stats.mood += beat.deltaMood
            character.stats.energy += beat.deltaEnergy
            character.stats.clamp()
            if let outfit = beat.outfitHint, outfit.isUnlocked(stats: character.stats) {
                character.outfit = outfit
            }
            character.currentRoom = .bedroom
            session.beatsCompleted += 1

            // 门控：兴奋/档位不够则拒绝进入下一步
            if let next = beat.step.next {
                let tierOK = character.stats.intimacyTier >= next.requiredTier
                let arousalOK = character.stats.arousal >= next.minArousal - 5
                if choice.kind == .advance && (!tierOK || !arousalOK) {
                    session.refused = true
                    session.finished = true
                    return ([
                        DialogueLine(speaker: .player, text: choice.title),
                        DialogueLine(speaker: .character, text: beat.herLine),
                        DialogueLine(speaker: .character, text: refusalLine(character: character, step: next))
                    ], "她想慢一点")
                }
                if choice.kind == .advance || (choice.kind == .soft && beat.step != .climax) {
                    if choice.kind == .advance {
                        session.step = next
                    } else if beat.step == .undressAssist && !OutfitState.underwear.isUnlocked(stats: character.stats) {
                        session.finished = true
                    } else if beat.step == .climax {
                        session.finished = true
                    } else {
                        // soft 也可小步前进
                        session.step = next
                    }
                }
            } else {
                session.finished = true
            }

            if beat.step == .climax && (choice.kind == .advance || choice.id == "x1") {
                session.finished = true
                character.stats.arousal = min(100, character.stats.arousal + 5)
                character.stats.affection += 2
                character.stats.clamp()
            }

            var lines = [
                DialogueLine(speaker: .player, text: choice.title),
                DialogueLine(speaker: .system, text: beat.narration),
                DialogueLine(speaker: .character, text: beat.herLine)
            ]
            if session.finished && beat.step == .climax {
                lines.append(DialogueLine(speaker: .system, text: "缠绵结束。你们相拥着喘气。关系更近了。（风格化演出完成）"))
            }
            return (lines, "亲密：\(beat.step.displayName)")
        }
    }
}
