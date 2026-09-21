# Spark（居家养成）

成人向（**18+**）2D 居家养成 / 恋爱互动模拟。**v1.0** 可玩：年龄门 → 随机成年室友 → 四房间互动（聊天、照顾、换装、亲密）+ 日漫立ち絵 live idle 动效。

**仓库：** [wurishen/spark-ios](https://github.com/wurishen/spark-ios)  
**Bundle ID：** `com.wurishen.spark`  
**平台：** iOS 17+ · SwiftUI · 竖屏优先 · 版本 **1.0.0**

---

## 18+ 政策（必须阅读）

- 本游戏仅面向 **年满 18 周岁** 的玩家。首次启动有明确年龄门与内容警告。
- **所有角色均为成年人（22–32 岁）**。禁止未成年、炼铜、年龄操作（aging-up）或校园未成年叙事。
- 包含服装分层与亲密关系进程；画面为**日漫二次元 / galgame 立ち絵**（cel-shade、大眼）+ 风格化 Canvas 分层回退，**不含写实器官特写或摄影级色情素材**。
- 裸身层为艺术剪影；写实器官特写资产可标为 `TODO`。

---

## v1.0 功能

| 模块 | 状态 |
|------|------|
| 18+ 年龄门 | ✅ |
| 随机角色生成（22–32） | ✅ |
| 房间：客厅 / 卧室 / 厨房 / 浴室门口 | ✅ |
| 日时段（早/午/晚/夜）影响心情与可用行动 | ✅ |
| 性格 / 亲密 / 时段感知对话 | ✅ |
| 照顾行动（饭/礼/休/出门） | ✅ |
| 换装分层 + 门控 | ✅ |
| 亲密行动门控 | ✅ |
| 多步亲密场景（吻→抚→宽衣→缠绵） | ✅ |
| 内衣日漫立ち絵 + 裸身柔和剪影 | ✅ |
| 日漫立ち絵（便装/居家）+ SwiftUI live idle | ✅ |
| Canvas 分层回退（外出/内衣/裸身剪影） | ✅ |
| Codable 持久化 | ✅ |
| CI 未签名 IPA → GitHub Releases | ✅ |
| 真 Live2D Cubism（.model3.json） | ❌ 后续 milestone |

### Live idle（v1）

立绘使用 SwiftUI 原生动效（**不是** Live2D Cubism SDK）：

1. 缓慢呼吸缩放（约 1.0–1.015）
2. 每隔 3–5 秒眨眼遮罩
3. 轻微左右摆动（±2°）
4. 角色发言时点头 / 嘴部暗示
5. 脚下轻浮阴影

若日后提供 `.model3.json` + 纹理，可再接入官方 Cubism SDK 作为独立 milestone。

### 美术方向

- **经典日漫 / galgame 立ち絵**：cel-shade、大眼、二次元比例
- 便装/居家：`PortraitCasual` / EmbeddedPortrait.casual
- 内衣：`PortraitLingerie` / EmbeddedPortrait.lingerie
- 裸身：程序化二次元柔和剪影（无写实器官特写）
- 不使用半写实或摄影风立绘

---

## 概念与核心循环

1. **首次启动**：通过 18+ 年龄门 → 随机生成成年女性室友（姓名、职业、性格、喜好、数值）。
2. **居家场景**：客厅 / 卧室 / 厨房 / 浴室门口（梳妆台与半掩门，非偷窥）。
3. **时段**：早晨 / 午后 / 傍晚 / 夜晚 — 影响心情、话题与行动可用性（例如夜晚不可出门/做饭）。
4. **对话**：性格 + 心情 + 亲密度 + 时段的规则模板（无 LLM）。
5. **照顾 / 换装 / 亲密**：门控渐进。
6. **存档**：Documents JSON + UserDefaults。

---

## 如何在 Xcode 中运行

1. 用 **Xcode 15+**（建议 16）克隆本仓库：
   ```bash
   git clone https://github.com/wurishen/spark-ios.git
   cd spark-ios
   open Spark.xcodeproj
   ```
2. 选择共享 scheme **Spark**，Signing 选择你的 Team。
3. 模拟器选 **iPhone 15 / 16** 等 iOS 17+ 机型，竖屏。
4. Run（⌘R）。

---

## 下载（CI 构建）

每次推送到 `main` 且构建成功后，GitHub Actions 会自动发布一个 **pre-release**，并把 IPA 挂到仓库 Releases 页：

👉 https://github.com/wurishen/spark-ios/releases

- 附件文件名：`Spark-unsigned.ipa`
- 标签形如 `build-<run_number>`，发布备注里写明来源 commit 与分支
- ⚠️ 均为**未签名（开发用）产物**，无法直接安装到真机；请下载后本地用 Xcode 重新签名（方法见下节），或下载同名的 Actions Artifact `.xcarchive` 在本机补签名

---

## 构建与打包（IPA）

仓库未配置签名证书，CI 产出的是**未签名（开发用）产物**，无法直接通过正常途径安装到真机。

### 当前 CI 产物（Actions Artifacts）

推送到 `main` 后，GitHub Actions（`.github/workflows/ios.yml`）会依次执行：

1. Simulator 快速编译检查（`xcodebuild -scheme Spark`，`CODE_SIGNING_ALLOWED=NO`）；
2. `xcodebuild archive`（`generic/platform=iOS`，未签名）；
3. 尝试无证书导出 IPA；失败则**自动回退**为 Payload zip → `Spark-unsigned.ipa`；
4. 上传 artifact：`Spark-xcarchive-unsigned`、`Spark-ipa`；
5. 发布 **GitHub Release**（pre-release，标签 `build-<run_number>`）：附件 `Spark-unsigned.ipa`。

> ⚠️ **当前 CI 无签名证书，产出的是未签名/开发用产物，真机安装需本地用 Xcode 签名。** 未签名 IPA 可用于验证包体结构、配合 sideload 工具自行重签名，或下载 `.xcarchive` 后在本机 Xcode 里补签名再导出。

### 用 Xcode（推荐）

1. 打开 `Spark.xcodeproj`；
2. Target **Spark** → **Signing & Capabilities** → Team；
3. **Product → Archive** → Organizer → **Distribute App**。

### 命令行（需本机签名）

```sh
xcodebuild archive \
  -project Spark.xcodeproj \
  -scheme Spark \
  -destination 'generic/platform=iOS' \
  -archivePath build/Spark.xcarchive

xcodebuild -exportArchive \
  -archivePath build/Spark.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist exportOptions.plist
```

### 编译验证（模拟器）

```sh
xcodebuild build \
  -project Spark.xcodeproj \
  -scheme Spark \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

---

## 工程结构

```
Spark.xcodeproj/          含共享 scheme Spark
Spark/
  SparkApp.swift / ContentView.swift
  Models/         Character, Stats, Outfit, GameState, Dialogue
  Services/       CharacterGenerator, DialogueEngine, PersistenceService, EmbeddedPortrait
  Views/          AgeGate, Intro, Home, Portrait(live idle), Outfit, ActionBar, ChatPanel
  Assets.xcassets PortraitCasual（可选槽）+ 颜色
  Info.plist      UILaunchScreen / 竖屏 / 1.0.0
.github/workflows/ios.yml
README.md
```

---

## 下一步建议

1. 多套服装 PNG 层（outdoor / underwear）叠放。
2. 真 Live2D：用户提供 `.model3.json` 后接入 Cubism。
3. 多存档槽、音效 BGM、可选 LLM Provider。

---

## 许可与声明

私人开发。请勿用于任何涉及未成年人的内容。须遵守当地法律与平台审核规则。
