import Foundation

struct ActionResult {
    var updatedCharacter: Character
    var lines: [DialogueLine]
    var banner: String?
}

/// 规则 + 模板对话引擎（v1.0：性格 / 亲密 / 时段 / 房间感知）
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
        if c.personalityTraits.contains(.witty) {
            return "哟，新同居人到货～我是\(c.name)。规矩只有一条：冰箱里的布丁先问过我。"
        }
        if c.personalityTraits.contains(.independent) {
            return "我是\(c.name)。各自空间我会尊重，你也一样就好。需要合作的时候再说。"
        }
        return "你好，我是\(c.name)。今天开始一起住，希望我们相处愉快。"
    }

    func chat(topic: ChatTopic, character: Character, timeOfDay: TimeOfDay = .afternoon) -> ActionResult {
        var c = character
        var deltaMood = 4.0
        var deltaAff = 2.0
        var deltaTrust = 1.5
        var deltaEnergy = -3.0

        switch timeOfDay {
        case .morning: deltaMood += 2; deltaEnergy += 1
        case .afternoon: break
        case .evening: deltaAff += 1; deltaMood += 1
        case .night: deltaTrust += 1; deltaEnergy -= 2
        }

        let reply: String
        switch topic.category {
        case .daily:
            reply = dailyReply(c, time: timeOfDay)
            deltaMood += c.personalityTraits.contains(.cheerful) ? 3 : 0
        case .hobby:
            if c.likes.contains(where: { topic.title.contains($0) }) {
                reply = likeHitReply(c, topic: topic.title)
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
            reply = feelingsReply(c, time: timeOfDay)
            deltaTrust += 3
            deltaAff += 2
        case .past:
            reply = pastReply(c)
            deltaTrust += 2
        case .flirt:
            reply = flirtReply(&c, time: timeOfDay, deltaAff: &deltaAff, deltaMood: &deltaMood)
        }

        apply(&c, mood: deltaMood, affection: deltaAff, trust: deltaTrust, energy: deltaEnergy, hunger: 2)
        return ActionResult(
            updatedCharacter: c,
            lines: [
                DialogueLine(speaker: .player, text: topic.title),
                DialogueLine(speaker: .character, text: reply)
            ],
            banner: "好感 +\(Int(max(0, deltaAff)))"
        )
    }

    func resolveCareAction(
        _ action: CareAction,
        character: Character,
        giftsLeft: Int,
        timeOfDay: TimeOfDay = .afternoon
    ) -> ActionResult {
        var c = character
        switch action {
        case .chat:
            let topic = ChatTopic.dailyTopics(for: timeOfDay).first
                ?? ChatTopic(id: "free", title: "随便聊聊今天过得怎么样", category: .daily)
            return chat(topic: topic, character: c, timeOfDay: timeOfDay)

        case .cook:
            apply(&c, mood: 8, affection: 4, trust: 2, energy: 5, hunger: -35, arousal: 0)
            c.currentRoom = .kitchen
            let text: String
            if c.personalityTraits.contains(.caring) {
                text = timeOfDay == .morning
                    ? "早餐的香气……你做的？我来摆盘。新的一天从一起吃开始。"
                    : "好香……你做的？我来帮忙摆盘。一起吃吧，感觉整个人都活过来了。"
            } else if c.personalityTraits.contains(.witty) {
                text = "厨师大人驾到？那我负责夸奖与光盘行动。"
            } else {
                text = "有人做饭的感觉真好。谢谢你，今天心情瞬间亮了。"
            }
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .player, text: "我去做饭了。"),
                DialogueLine(speaker: .character, text: text)
            ], banner: "心情↑ 饥饿↓ · 厨房")

        case .gift:
            if giftsLeft <= 0 {
                return ActionResult(updatedCharacter: c, lines: [
                    DialogueLine(speaker: .system, text: "礼物用完了，明天再补充。")
                ], banner: "没有礼物了")
            }
            let gift = c.likes.randomElement() ?? "小礼物"
            apply(&c, mood: 10, affection: 7, trust: 3, energy: -2, hunger: 0, arousal: 2)
            let thanks: String
            if c.personalityTraits.contains(.shy) {
                thanks = "真、真的吗？你记得我喜欢\(gift)……我收着，会好好珍惜。"
            } else if c.personalityTraits.contains(.playful) {
                thanks = "欸嘿～\(gift)！你是不是偷偷观察我很久了？奖励你一个笑脸。"
            } else {
                thanks = "真的吗？你记得我喜欢\(gift)……我好开心。会好好珍惜的。"
            }
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .player, text: "送给你——和「\(gift)」相关的小礼物。"),
                DialogueLine(speaker: .character, text: thanks)
            ], banner: "好感大幅提升")

        case .rest:
            apply(&c, mood: 5, affection: 2, trust: 1, energy: 30, hunger: 5, arousal: -5)
            c.currentRoom = .bedroom
            let text = timeOfDay == .night
                ? "关灯吧。今晚就好好睡……你也是。"
                : "嗯……歇一会儿。你也别硬撑，沙发和床都留给疲惫的人。"
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .character, text: text)
            ], banner: "精力恢复 · 卧室")

        case .goOut:
            apply(&c, mood: 6, affection: 3, trust: 2, energy: -15, hunger: 10, arousal: 0)
            c.outfit = .outdoor
            c.currentRoom = .livingRoom
            let text = timeOfDay == .morning
                ? "晨光不错。我们走走，买点新鲜的菜回来？"
                : "走走也好。街上风不大，我们慢慢逛，买点晚饭的材料回来吧。"
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .character, text: text)
            ], banner: "一起出门（抽象场景）")

        case .intimacy:
            return ActionResult(updatedCharacter: c, lines: [
                DialogueLine(speaker: .system, text: "选择一种亲密互动（受好感/信任与时段门控）。")
            ], banner: nil)
        }
    }

    func resolveIntimacy(_ action: IntimacyAction, character: Character, timeOfDay: TimeOfDay = .evening) -> ActionResult {
        var c = character
        let lines: [DialogueLine]
        let nightBonus = (timeOfDay == .night || timeOfDay == .evening) ? 2.0 : 0.0
        switch action {
        case .holdHands:
            apply(&c, mood: 4, affection: 3 + nightBonus / 2, trust: 2, energy: -2, hunger: 0, arousal: 5)
            lines = [
                DialogueLine(speaker: .player, text: "牵一下手，可以吗？"),
                DialogueLine(speaker: .character, text: personalityHoldHands(c))
            ]
        case .hug:
            apply(&c, mood: 6, affection: 5, trust: 3, energy: -4, hunger: 0, arousal: 8 + nightBonus)
            lines = [
                DialogueLine(speaker: .player, text: "抱抱。"),
                DialogueLine(speaker: .character, text: personalityHug(c, time: timeOfDay))
            ]
        case .kiss:
            apply(&c, mood: 8, affection: 6, trust: 3, energy: -6, hunger: 0, arousal: 14 + nightBonus)
            lines = [
                DialogueLine(speaker: .player, text: "想吻你。"),
                DialogueLine(speaker: .character, text: personalityKiss(c))
            ]
        case .caress:
            apply(&c, mood: 5, affection: 5, trust: 2, energy: -8, hunger: 0, arousal: 22 + nightBonus)
            if c.outfit.rank < OutfitState.underwear.rank, OutfitState.underwear.isUnlocked(stats: c.stats) {
                c.outfit = .underwear
            }
            lines = [
                DialogueLine(speaker: .player, text: "轻轻触碰她。"),
                DialogueLine(speaker: .character, text: intimacyGatedLine(c, level: .caress))
            ]
        case .makeLove:
            apply(&c, mood: 10, affection: 8, trust: 4, energy: -25, hunger: 8, arousal: 35 + nightBonus)
            if OutfitState.nude.isUnlocked(stats: c.stats) {
                c.outfit = .nude
            } else if OutfitState.underwear.isUnlocked(stats: c.stats) {
                c.outfit = .underwear
            }
            c.currentRoom = .bedroom
            lines = [
                DialogueLine(speaker: .player, text: "今晚，想更靠近你。"),
                DialogueLine(speaker: .character, text: intimacyGatedLine(c, level: .makeLove)),
                DialogueLine(speaker: .system, text: "亲密互动完成。关系更近一步。（风格化演出，无写实器官特写）")
            ]
        }
        return ActionResult(updatedCharacter: c, lines: lines, banner: "亲密：\(action.displayName)")
    }

    func outfitRejected(for c: Character, outfit: OutfitState) -> String {
        if c.personalityTraits.contains(.shy) {
            return "等、等一下……「\(outfit.displayName)」对我来说太早了。我们再多相处几天好吗？"
        }
        if c.personalityTraits.contains(.independent) {
            return "服装的事我想自己决定进度。再等等「\(outfit.displayName)」吧。"
        }
        return "现在还不太想换成「\(outfit.displayName)」。等我更信任你一点。"
    }

    func outfitAccepted(for c: Character, outfit: OutfitState) -> String {
        switch outfit {
        case .outdoor: return "好，出门装穿上了。钥匙带了吗？"
        case .casual: return "便装最舒服。我们就这样待着吧。"
        case .home: return "换上居家服了……整个人都松下来了。"
        case .underwear: return c.personalityTraits.contains(.shy)
            ? "你看着我……有点害羞，但我不讨厌这种感觉。"
            : "只给你看的距离。别太紧张，我也不想逃。"
        case .nude: return "……只留给你看的样子。灯光柔一点就好。（剪影演出）"
        }
    }

    func intimacyRejected(for c: Character, action: IntimacyAction) -> String {
        if c.personalityTraits.contains(.shy) {
            return "「\(action.displayName)」……现在还不行。多陪陪我，让我更安心一些。"
        }
        return "「\(action.displayName)」还太早。好感与信任再升温一点，好吗？"
    }

    func timeGatedIntimacy(for c: Character, time: TimeOfDay) -> String {
        "现在是\(time.displayName)……再等等，好吗？我想把更靠近的事留到更合适的时候。"
    }

    func roomEnter(for c: Character, room: RoomScene, time: TimeOfDay) -> String {
        switch room {
        case .livingRoom:
            return c.personalityTraits.contains(.cheerful)
                ? "回客厅啦～要不要放点音乐？"
                : "客厅光线刚好。坐一会儿吧。"
        case .bedroom:
            return time == .night
                ? "卧室里安静些。窗帘我拉上了。"
                : "进卧室了。枕头还是我喜欢的那一侧。"
        case .kitchen:
            return "厨房……冰箱还有余量。要一起准备点什么吗？"
        case .bathroomDoor:
            return "我在梳妆台这边。门就这样半掩着——你在外面等我就好，不用进来。"
        }
    }

    private enum IntimateLevel { case caress, makeLove }

    private func intimacyGatedLine(_ c: Character, level: IntimateLevel) -> String {
        let high = c.stats.affection >= 60 && c.stats.trust >= 55
        switch level {
        case .caress:
            if !high {
                return "呼吸乱了一拍……再慢一点，我还想多感受一会儿。"
            }
            if c.personalityTraits.contains(.romantic) {
                return "你的指尖像在写只有我能读的句子……继续，别停。"
            }
            if c.personalityTraits.contains(.shy) {
                return "唔……好烫。可是，不要收回手。"
            }
            return "身体先于语言答应了你。再近一点也没关系。"
        case .makeLove:
            if c.personalityTraits.contains(.romantic) {
                return "关上门。灯光调暗。把今晚的呼吸，都留在彼此身边。"
            }
            if c.personalityTraits.contains(.playful) {
                return "门锁好了吗？那就……别让我一个人先脸红。"
            }
            return "关上门。两个人的呼吸交织在一起——今晚只属于我们。"
        }
    }

    private func personalityHoldHands(_ c: Character) -> String {
        if c.personalityTraits.contains(.shy) { return "……好。你的手好暖。" }
        if c.personalityTraits.contains(.playful) { return "十指相扣？行啊，不许中途松开哦。" }
        return "嗯。指尖贴在一起的感觉，意外地安心。"
    }

    private func personalityHug(_ c: Character, time: TimeOfDay) -> String {
        if time == .night {
            return "夜里的拥抱格外长……再靠一会儿。"
        }
        if c.personalityTraits.contains(.caring) {
            return "来。今天的疲劳，就先寄存在这里。"
        }
        return "靠过来吧。我在。"
    }

    private func personalityKiss(_ c: Character) -> String {
        if c.personalityTraits.contains(.romantic) {
            return "那就别眨眼……我记住这一秒。"
        }
        if c.personalityTraits.contains(.shy) {
            return "唇……轻轻的。我心跳好大声，你有没有听到？"
        }
        return "唇瓣轻轻碰在一起。世界好像安静了一会儿。"
    }

    private func likeHitReply(_ c: Character, topic: String) -> String {
        if c.personalityTraits.contains(.cheerful) {
            return "说到\(topic)……我超喜欢！你也懂啊，好开心！"
        }
        if c.personalityTraits.contains(.witty) {
            return "\(topic)！你这是精准投喂。印象分直接拉满。"
        }
        return "你记得我喜欢\(topic)……比收到礼物还开心。"
    }

    private func flirtReply(
        _ c: inout Character,
        time: TimeOfDay,
        deltaAff: inout Double,
        deltaMood: inout Double
    ) -> String {
        if c.stats.affection < 30 {
            deltaAff += 1
            deltaMood -= 1
            return "你……突然这样说话，我有点不习惯。我们再多了解一下好吗？"
        }
        if c.personalityTraits.contains(.shy) {
            deltaAff += 4
            deltaArousal(&c, 6)
            return time == .night
                ? "夜、夜里说这种话……我耳朵都热了。但，继续说给我听也没关系。"
                : "你、你别盯着我看啦……不过，听到你这么说，心里暖暖的。"
        }
        if c.personalityTraits.contains(.romantic) || c.personalityTraits.contains(.playful) {
            deltaAff += 5
            deltaArousal(&c, 8)
            return "哦？今天这么主动？那我可要认真回应你了～"
        }
        if c.stats.affection >= 55 {
            deltaAff += 4
            deltaArousal(&c, 10)
            return time == .night
                ? "你这样说话……身体先答应了。今晚灯可以再暗一点。"
                : "胸口有点热。你要是想更近，我不会逃。"
        }
        deltaAff += 3
        deltaArousal(&c, 4)
        return "谢谢你愿意对我说这些。靠近一点也没关系。"
    }

    private func dailyReply(_ c: Character, time: TimeOfDay) -> String {
        let moodLine: String
        switch c.stats.mood {
        case ..<35: moodLine = "今天有点提不起劲……能陪我说说话就好。"
        case ..<65: moodLine = "还行啦。\(c.occupation)的工作告一段落，想听听你的事。"
        default: moodLine = "心情不错～你呢？要不要一起计划今晚？"
        }
        switch time {
        case .morning:
            return c.personalityTraits.contains(.independent)
                ? "早。我先泡咖啡。你的日程紧不紧？"
                : "早上好。阳光爬到地板上了……\(moodLine)"
        case .afternoon:
            return moodLine
        case .evening:
            return "傍晚的家最安静。\(moodLine)"
        case .night:
            return c.stats.trust >= 40
                ? "这么晚还聊……我并不讨厌。\(moodLine)"
                : "夜深了，说一点就好。\(moodLine)"
        }
    }

    private func hobbyReply(_ c: Character, topic: String) -> String {
        "「\(topic)」啊。我最近喜欢\(c.likes.first ?? "安静地待着")，有机会一起试试？"
    }

    private func feelingsReply(_ c: Character, time: TimeOfDay) -> String {
        if c.stats.trust < 30 {
            return "感情的事……我还在观察。不过你愿意问，我已经觉得被重视了。"
        }
        if time == .night {
            return "夜里话更真心一点。和你住在一起之后，家里好像多了一点温度。"
        }
        return "和你住在一起之后，家里好像多了一点温度。这种感觉，挺珍贵的。"
    }

    private func pastReply(_ c: Character) -> String {
        if c.personalityTraits.contains(.independent) {
            return "以前习惯什么都自己扛。\(c.age) 岁这年，我想试试把肩膀借给可信的人。"
        }
        return "以前一个人住久了，习惯把情绪收起来。\(c.age) 岁这年，我想试试更坦诚一点。"
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
