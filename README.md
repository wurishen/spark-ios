# Spark（居家养成）

成人向（**18+**）2D 居家养成 / 恋爱互动模拟。v0.1 可玩脚手架：年龄门 → 随机成年室友 → 客厅/卧室互动（聊天、照顾、换装、亲密）。

**仓库：** [wurishen/spark-ios](https://github.com/wurishen/spark-ios)  
**Bundle ID：** `com.wurishen.spark`  
**平台：** iOS 17+ · SwiftUI · 竖屏优先

---

## 18+ 政策（必须阅读）

- 本游戏仅面向 **年满 18 周岁** 的玩家。首次启动有明确年龄门与内容警告。
- **所有角色均为成年人（22–32 岁）**。禁止未成年、炼铜、年龄操作（aging-up）或校园未成年叙事。
- 包含服装分层与亲密关系进程；画面为**风格化 2D 分层占位**（几何色块 / 软性剪影），**不含写实器官特写或摄影级色情素材**。
- 正式立绘接入时仍须遵守：无未成年人形象；裸身层可用艺术剪影，写实器官特写资产可标为 `TODO`。

---

## 概念与核心循环

1. **首次启动**：通过 18+ 年龄门 → 随机生成成年女性室友/伴侣（姓名、职业、性格、喜好/厌恶、心情/好感/信任/亲密等数值）。
2. **居家场景**：客厅 / 卧室（SwiftUI 2D，非 SpriteKit）。
3. **对话**：基于性格特质 + 心情 + 亲密度的规则模板回复（v0.1 无 LLM API）。
4. **照顾行动**：聊天、做饭、送礼、休息、出门（抽象）、亲密（受好感/信任门控）。
5. **换装**：外出装 → 便装 → 居家服 → 内衣 → 裸身剪影；脱衣渐进且门控。
6. **存档**：Documents 下 JSON + UserDefaults 双写。

---

## 如何在 Xcode 中运行

1. 用 **Xcode 15+**（建议 16）克隆本仓库：
   ```bash
   git clone https://github.com/wurishen/spark-ios.git
   cd spark-ios
   open Spark.xcodeproj
   ```
2. 选择 Target **Spark**，Signing 选择你的 Team（个人免费账号即可跑模拟器）。
3. 模拟器选 **iPhone 15 / 16** 等 iOS 17+ 机型，竖屏。
4. 点击 Run（⌘R）。

### 预期流程

1. 年龄门：勾选「我已年满 18 岁」→ 进入游戏  
2. 「随机生成角色」→ 进入客厅主界面  
3. 可见立绘占位、数值条、对话面板  
4. 底部按钮：聊天 / 做饭 / 送礼 / 休息 / 出门 / 亲密，以及换装、切换房间  

---

## 当前功能（v0.1）

| 模块 | 状态 |
|------|------|
| 18+ 年龄门 | ✅ |
| 随机角色生成（22–32） | ✅ |
| 客厅 / 卧室切换 | ✅ |
| 规则对话 + 话题选择 | ✅ |
| 照顾行动（饭/礼/休/出门） | ✅ |
| 换装分层 + 门控 | ✅ |
| 亲密行动门控 | ✅ |
| 程序化分层立绘 | ✅ 色块占位 |
| Codable 持久化 | ✅ |
| 真实立绘 / 多存档 / LLM | ❌ 后续 |

### 工程结构

```
Spark/
  SparkApp.swift
  ContentView.swift
  Models/      Character, Stats, Outfit, GameState, Dialogue
  Services/    CharacterGenerator, DialogueEngine, PersistenceService
  Views/       AgeGate, Intro, Home, Portrait, OutfitSheet, ActionBar, ChatPanel
  Assets.xcassets
  Info.plist
Spark.xcodeproj/
README.md
```

---

## 下一步建议

1. **真实立绘**：按层导出 PNG（`body` / `underwear` / `clothes_outdoor|casual|home` / `hair` / `face`），在 `CharacterPortraitView` 用 `Image` 按 z-order 叠放；保留门控逻辑。裸身层用艺术剪影，写实器官特写标 `TODO_ASSET`。
2. **更多场景**：厨房、浴室门口（非偷窥未成年）、阳台约会事件。
3. **多存档槽**：3 槽位 + 导出/导入 JSON。
4. **可选 LLM**：在本地规则引擎旁加 Provider 协议，默认仍离线。
5. **音效与 BGM**、日历事件、好感里程碑 CG。

---

## 许可与声明

私人开发脚手架。请勿将本项目用于任何涉及未成年人的内容。作者与贡献者须遵守当地法律与平台审核规则。
