import Foundation

struct ActionResult {
    var updatedCharacter: Character
    var lines: [DialogueLine]
    var banner: String?
}

/// 规则 + 模板对话引擎（v0.1 无 LLM）
struct DialogueEngine {

    func greeting(for c: Character) -> String {
        if c.personalityTraits.contains(.shy) {
            return "啊……你来了。我是\(c.name)，以后请多关照。沙发可以坐，不用拘束。"
        }
        if c.personalityTraits.contains(.cheerful) {
            return "嗨！你就是新室友吧？我是\(c.name)，\(c.occupation)。今天天气不错，要不要先喝点什么？"
        }
        if c.personalityTraits.contains(.gentle) {
            return "欢迎回家。我是\(c.name)，很高兴终于见面了。有什么需要随时跟我说。"
        }
        return "你好，我是\(c.name)。今天开始一起住，希望我们相处愉快。"
    }

    func chat(topic: ChatTopic, character: Character) -> ActionResult {
        var c = character
        var deltaMood = 4.0
        var deltaAff = 2.0
        var deltaTrust = 1.5
        var deltaEnergy = -3.0

        let reply: String
        switch topic.category {
        case .daily:
            reply = dailyReply(c)
            deltaMood += c.personalityTraits.contains(.cheerful) ? 3 : 0
        case .hobby:
            if topic.title.contains(where: { ch in c.likes.joined().contains(ch) }) ||
                c.likes.contains(where: { topic.title.contains($0) }) {
                reply = "说到\(topic.title)……我超喜欢！你也懂啊，好开心。"
                deltaAff += 4
                deltaTrust += 2
            } else if c.dislikes.contains(where: { topic.title.contains($0) }) {
                reply = "呃……\(topic.title)我其实不太感兴趣，能聊聊别的吗？"
                deltaMood -= 2
                deltaAff -= 1
            } else {
                reply = hobbyReply(c, topic: topic.title)
                deltaAff += 2
            }
        case .feelings:
            reply = feelingsReply(c)
            deltaTrust += 3
            deltaAff += 2
        case .past:
            reply = pastReply(c)
            deltaTrust += 2
        case .flirt:
            if c.stats.affection < 30 {
                reply = "你……突然这样说话，我有点不习惯。我们再多了解一下好吗？"
                deltaAff += 1
                deltaMood -= 1
            } else if c.personalityTraits.contains(.shy) {
                reply = "你、你别盯着我看啦……不过，听到你这么说，心里暖暖的。"
                deltaAff += 4
                deltaArousal(&c, 6)
            } else if c.personalityTraits.contains(.romantic) || c.personalityTraits.contains(.playful) {
                reply = "哦？今天这么主动？那我可要认真回应你了～"
                deltaAff += 5
                deltaArousal(&c, 8)
            } else {
                reply = "谢谢你愿意对我说这些。靠近一点也没关系。"
                deltaAff += 3
                deltaArousal(&c, 4)
            }
        }

        apply(&c, mood: deltaMood, affection: deltaAff, trust: deltaTrust, energy: deltaEnergy, hunger: 2)
        return ActionResult(
            updatedCharacter: c,
            lines: [
                DialogueLine(speaker: .player, text: topic.title),
                DialogueLine(speaker: .character, text: reply)
            ],
            banner: "好感 +\(Int(deltaAff))"
        )
    }

    func resolveCareAction(_ action: CareAction, character: Character, giftsLeft: Int) -> ActionResult {
        var c = character
        switch action {
        case .chat:
            let topic = ChatTopic(id: "free", title: "随便聊聊今天过得怎么样", category: .daily)
            return chat(topic: topic, character: c)

        case .cook:
            apply(&c, mood: 8, affection: 4, trust: 2, energy: 5, hunger: -35, arousal: 0)
            let text: String
            if c.personalityTraits.contains(.caring) {
                text = "好香……你做的？我来帮忙摆盘。一起吃吧，感觉整个人都活过来了。"
            } else {
                text = "哇，有人做饭的感觉真好。谢谢你，今天心情瞬间亮了。"
            }
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .player, text: "我去做饭了。"),
                DialogueLine(speaker: .character, text: text)
            ], banner: "心情↑ 饥饿↓")

        case .gift:
            if giftsLeft <= 0 {
                return ActionResult(updatedCharacter: c, lines: [
                    DialogueLine(speaker: .system, text: "礼物用完了，明天再补充。")
                ], banner: "没有礼物了")
            }
            let gift = c.likes.randomElement() ?? "小礼物"
            apply(&c, mood: 10, affection: 7, trust: 3, energy: -2, hunger: 0, arousal: 2)
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .player, text: "送给你——和「\(gift)」相关的小礼物。"),
                DialogueLine(speaker: .character, text: "真的吗？你记得我喜欢\(gift)……我好开心。会好好珍惜的。")
            ], banner: "好感大幅提升")

        case .rest:
            apply(&c, mood: 5, affection: 2, trust: 1, energy: 30, hunger: 5, arousal: -5)
            c.currentRoom = .bedroom
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .character, text: "嗯……歇一会儿。你也别硬撑，沙发和床都留给疲惫的人。")
            ], banner: "精力恢复")

        case .goOut:
            apply(&c, mood: 6, affection: 3, trust: 2, energy: -15, hunger: 10, arousal: 0)
            c.outfit = .outdoor
            c.currentRoom = .livingRoom
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .character, text: "走走也好。街上风不大，我们慢慢逛，买点晚饭的材料回来吧。")
            ], banner: "一起出门（抽象场景）")

        case .intimacy:
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .system, text: "选择一种亲密互动（受好感/信任门控）。")
            ], banner: nil)
        }
    }

    func resolveIntimacy(_ action: IntimacyAction, character: Character) -> ActionResult {
        var c = character
        let lines: [DialogueLine]
        switch action {
        case .holdHands:
            apply(&c, mood: 4, affection: 3, trust: 2, energy: -2, hunger: 0, arousal: 5)
            lines = [
                DialogueLine(speaker: .player, text: "牵一下手，可以吗？"),
                DialogueLine(speaker: .character, text: c.personalityTraits.contains(.shy)
                    ? "……好。你的手好暖。"
                    : "嗯。指尖贴在一起的感觉，意外地安心。")
            ]
        case .hug:
            apply(&c, mood: 6, affection: 5, trust: 3, energy: -4, hunger: 0, arousal: 8)
            lines = [
                DialogueLine(speaker: .player, text: "抱抱。"),
                DialogueLine(speaker: .character, text: "靠过来吧。今天的疲劳，就先寄存在这里。")
            ]
        case .kiss:
            apply(&c, mood: 8, affection: 6, trust: 3, energy: -6, hunger: 0, arousal: 14)
            lines = [
                DialogueLine(speaker: .player, text: "想吻你。"),
                DialogueLine(speaker: .character, text: c.personalityTraits.contains(.romantic)
                    ? "那就别眨眼……我记住这一秒。"
                    : "唇瓣轻轻碰在一起。世界好像安静了一会儿。")
            ]
        case .caress:
            apply(&c, mood: 5, affection: 5, trust: 2, energy: -8, hunger: 0, arousal: 22)
            if c.outfit.rank < OutfitState.underwear.rank, OutfitState.underwear.isUnlocked(stats: c.stats) {
                c.outfit = .underwear
            }
            lines = [
                DialogueLine(speaker: .player, text: "轻轻触碰她。"),
                DialogueLine(speaker: .character, text: "呼吸乱了一拍……再慢一点，我还想多感受一会儿。")
            ]
        case .makeLove:
            apply(&c, mood: 10, affection: 8, trust: 4, energy: -25, hunger: 8, arousal: 35)
            if OutfitState.nude.isUnlocked(stats: c.stats) {
                c.outfit = .nude
            } else if OutfitState.underwear.isUnlocked(stats: c.stats) {
                c.outfit = .underwear
            }
            c.currentRoom = .bedroom
            lines = [
                DialogueLine(speaker: .player, text: "今晚，想更靠近你。"),
                DialogueLine(speaker: .character, text: "关上门。灯光调暗。两个人的呼吸交织在一起——（亲密场景用风格化演出，无写实器官特写）"),
                DialogueLine(speaker: .system, text: "亲密互动完成。关系更近一步。")
            ]
        }
        return ActionResult(updatedCharacter: c, lines: lines, banner: "亲密：\(action.displayName)")
    }

    func outfitRejected(for c: Character, outfit: OutfitState) -> String {
        if c.personalityTraits.contains(.shy) {
            return "等、等一下……「\(outfit.displayName)」对我来说太早了。我们再多相处几天好吗？"
        }
        return "现在还不太想换成「\(outfit.displayName)」。等我更信任你一点。"
    }

    func outfitAccepted(for c: Character, outfit: OutfitState) -> String {
        switch outfit {
        case .outdoor: return "好，出门装穿上了。钥匙带了吗？"
        case .casual: return "便装最舒服。我们就这样待着吧。"
        case .home: return "换上居家服了……整个人都松下来了。"
        case .underwear: return "你看着我……有点害羞，但我不讨厌这种感觉。"
        case .nude: return "……只留给你看的样子。灯光柔一点就好。"
        }
    }

    func intimacyRejected(for c: Character, action: IntimacyAction) -> String {
        "「\(action.displayName)」……现在还不行。多陪陪我，让我更安心一些。"
    }

    private func dailyReply(_ c: Character) -> String {
        switch c.stats.mood {
        case ..<35: return "今天有点提不起劲……能陪我说说话就好。"
        case ..<65: return "还行啦。\(c.occupation)的工作告一段落，想听听你的事。"
        default: return "心情不错～你呢？要不要一起计划今晚？"
        }
    }

    private func hobbyReply(_ c: Character, topic: String) -> String {
        "「\(topic)」啊。我最近喜欢\(c.likes.first ?? "安静地待着")，有机会一起试试？"
    }

    private func feelingsReply(_ c: Character) -> String {
        if c.stats.trust < 30 {
            return "感情的事……我还在观察。不过你愿意问，我已经觉得被重视了。"
        }
        return "和你住在一起之后，家里好像多了一点温度。这种感觉，挺珍贵的。"
    }

    private func pastReply(_ c: Character) -> String {
        "以前一个人住久了，习惯把情绪收起来。\(c.age) 岁这年，我想试试更坦诚一点。"
    }

    private func deltaArousal(_ c: inout Character, _ v: Double) {
        c.stats.arousal += v
        c.stats.clamp()
    }

    private func apply(
        _ c: inout Character,
        mood: Double,
        affection: Double,
        trust: Double,
        energy: Double,
        hunger: Double,
        arousal: Double = 0
    ) {
        c.stats.mood += mood
        c.stats.affection += affection
        c.stats.trust += trust
        c.stats.energy += energy
        c.stats.hunger += hunger
        c.stats.arousal += arousal
        c.stats.clamp()
    }
}
