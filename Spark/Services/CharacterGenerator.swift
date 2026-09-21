import Foundation

enum CharacterGenerator {
    private static let names = [
        "林晚晴", "苏念", "陈可儿", "周予安", "沈星澜",
        "顾清欢", "叶知夏", "许温柔", "江眠", "白露",
        "程一诺", "韩若溪", "赵晚棠", "梁心悦", "宋清涟"
    ]

    private static let occupations = [
        "插画师", "咖啡师", "产品经理", "瑜伽教练", "独立写作",
        "室内设计师", "摄影师", "律师助理", "独立游戏策划", "花艺师",
        "营养师", "博物馆讲解员", "自由翻译", "美妆顾问", "心理咨询师"
    ]

    private static let likePool = [
        "手冲咖啡", "雨天窗边", "深夜电影", "猫咪", "徒步",
        "烘焙", "爵士乐", "温泉旅行", "读诗", "居家香氛",
        "摄影", "拼图", "日料", "复古胶片", "夜跑"
    ]

    private static let dislikePool = [
        "迟到", "嘈杂的环境", "过度甜食", "粗鲁的玩笑", "被催促",
        "烟味", "突然的惊吓", "冷气过猛", "不守承诺", "过度拥挤"
    ]

    static func generate() -> Character {
        let name = names.randomElement()!
        let age = Int.random(in: 22...32)
        let occupation = occupations.randomElement()!
        let traits = Array(PersonalityTrait.allCases.shuffled().prefix(3))
        let likes = Array(likePool.shuffled().prefix(3))
        let dislikes = Array(dislikePool.shuffled().prefix(2))
        let appearance = AppearancePalette.defaults.randomElement()!

        var stats = CharacterStats.starter
        // 轻微随机起步
        stats.mood += Double.random(in: -10...15)
        stats.affection += Double.random(in: -5...10)
        stats.trust += Double.random(in: -5...10)
        stats.clamp()

        return Character(
            name: name,
            age: age,
            occupation: occupation,
            personalityTraits: traits,
            likes: likes,
            dislikes: dislikes,
            stats: stats,
            outfit: .casual,
            appearance: appearance,
            currentRoom: .livingRoom,
            relationshipDays: 1
        )
    }
}
