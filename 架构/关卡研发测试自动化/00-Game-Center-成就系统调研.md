---
title: Game Center 成就系统调研
---

# Game Center 成就系统调研

> 源自飞书文档 · 最后同步：2026-09-11

##  一、能力与限制

### 1.1 成就限制

| 项目 | 限制 |
| --- | --- |
| 单个 App 的成就数量 | 最多 100 个 |
| 单个成就分值 | 1～100 分，最高 100 分 |
| 全部成就总分 | 最高 1000 分 |
| 成就进度 | `0`～`100`，使用 `Double` 百分比 |

Apple 仍要求在 App Store Connect 中配置成就分值，但当前 iOS Game Center 不向玩家展示 App 的成就总分。分值主要是 Game Center 成就元数据的一部分，不应在客户端自行实现另一套总分同步逻辑。

### 1.2 成就配置的不可逆性

- 成就的 `Achievement ID` 是永久标识，不能后续编辑。
- 成就对任意 App 版本可用后：
- 不能删除；
- 不能修改分值；
- 不应改变 ID 对应的触发语义。
- 处于开发或尚未对玩家可用状态的成就，App Store Connect 可能允许删除。因此测试成就不要直接使用正式 App 的真实配置，尤其不要把 `test`、`temp` 等临时成就发布到正式配置中。
- 已上线成就可以 Archive：
- 从 Game Center 相关用户界面移除；
- 不再通过 `GKAchievement` 返回；
- 之后可以 Unarchive；
- 对玩家生效最长可能需要 24 小时。
- Archive 是隐藏/停用，不是删除。
### 1.3 成就属性

App Store Connect 中的主要成就属性：

| 属性 | 说明 |
| --- | --- |
| Reference Name | App Store Connect 内部名称 |
| Achievement ID | 客户端通过 GameKit 使用的唯一标识，最多 100 个字符，永久设置 |
| Point Value | 完成成就获得的分值，1～100 |
| Hidden | 玩家完成前是否隐藏成就 |
| Achievable More Than Once | 是否允许重复获得 |
| Display Name | Game Center 中显示的本地化名称 |
| Earned Description | 完成后的本地化描述 |
| Pre-earned Description | 未完成时的本地化描述 |
| Image | 完成成就后的图片 |

图片要求：`.jpeg`、`.jpg` 或 `.png`，1024 × 1024 像素，至少 72 ppi，RGB 色彩空间。

## 二、接入前置配置

### 2.1 Xcode Capability

在目标 Target 中添加 Game Center Capability：

```
Target
→ Signing & Capabilities
→ + Capability
→ Game Center
```

启用后，Xcode 会为 App ID 增加 Game Center entitlement。构建时应检查签名后的 App 是否包含对应 entitlement，避免本地配置正确但 TestFlight 包缺少能力。

### 2.2 GameKit Bundle

- Xcode 16.3 及以后可以通过模板创建 GameKit Bundle：
```
File
→ New
→ File from Template
→ Other
→ GameKit Bundle
```

- GameKit Bundle 可以配置：
- achievements；
- leaderboards；
- leaderboard sets；
- activities；
- challenges；
- 配置同步规则：
- 在 GameKit Bundle 中选择 `Pull from App Store Connect`，可以拉取已有配置；
- 本地配置推送到 App Store Connect 后，从本地文件删除资源不会同步删除 App Store Connect 中的资源；
- 已经上线的成就必须在 App Store Connect 中 Archive，不能通过删除本地配置来移除。
### 2.3 App Store Connect 与 App 版本

- 需要在 App Store Connect 中完成：
1. 创建或启用 Game Center；
1. 创建 achievement；
1. 配置至少一种语言；
1. 配置名称、描述、图片和分值；
1. 将 achievement 添加到目标 App 版本；
1. 按 Game Center 组件流程提交审核。
- 常见状态：
- `Prepare for Submission`：仍在准备元数据；
- `Ready for Review`：已准备好但尚未提交；
- `Waiting for Review`：已提交等待审核；
- `In Review`：审核中；
- `Accepted`：组件已接受，但提交中可能仍有其他项目未接受；
- `Live`：已接受并可分发；
- `Rejected`：审核未通过；
- `Developer Rejected`：开发者主动从审核中移除。
## 三、初始化 Game Center

在调用 GameKit API 或 Game Center 服务前，需要初始化本地玩家。推荐在 App 启动阶段设置 `GKLocalPlayer.local.authenticateHandler`。

```
import GameKit

final class GameCenterAuthenticator {
    func authenticate(
        present: @escaping (UIViewController) -> Void
    ) {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let viewController {
                present(viewController)
                return
            }

            if let error {
                // Game Center 不可用时，调用方继续执行核心流程。
                print("Game Center authentication failed: \(error)")
                return
            }

            print("Game Center authenticated: \(GKLocalPlayer.local.isAuthenticated)")
        }
    }
}
```

注意：

- `authenticateHandler` 可能回调一个需要展示的 ViewController；
- `present` 必须由当前可见的 UIKit 宿主控制器执行；
- SwiftUI 需要通过 UIKit bridge 或自定义 presentation 层展示该控制器；
- 认证失败、用户拒绝登录或网络不可用时，不应阻塞 App 主流程；
- Game Center 不是自有账号系统，也不是单点登录服务。
如果服务端需要识别 Game Center 玩家，应使用 GameKit 提供的身份验证签名流程，而不是把 `GKPlayer.displayName` 当作稳定用户 ID。

## 四、成就进度 API

### 4.1 加载已有进度

```
let achievements = try await GKAchievement.loadAchievements()
```

返回的是当前玩家此前已经上报过进度的成就。某个成就不在返回数组中，表示当前玩家还没有上报过该成就，需要使用 App Store Connect 中的 ID 创建新的 `GKAchievement`。

### 4.2 创建并上报成就

```
import GameKit

func reportAchievement(
    identifier: String,
    percentComplete: Double
) async {
    guard GKLocalPlayer.local.isAuthenticated else {
        return
    }

    do {
        let current = try await GKAchievement.loadAchievements()
        let achievement = current.first {
            $0.identifier == identifier
        } ?? GKAchievement(identifier: identifier)

        achievement.percentComplete = min(
            max(percentComplete, 0),
            100
        )

        try await GKAchievement.report([achievement])
    } catch {
        print("Failed to report achievement: \(error)")
    }
}
```

对应的 completion-handler 写法：

```
let achievement = GKAchievement(identifier: "achievement_complete_tutorial")
achievement.percentComplete = 100

GKAchievement.report([achievement]) { error in
    if let error {
        print("Failed to report achievement: \(error)")
    }
}
```

### 4.3 上报行为

- `GKAchievement.report` 的重要规则：
- `percentComplete` 取值为 `0`～`100`；
- 只有新值大于当前值时，Game Center 才更新进度；
- 上报 `100.0` 后，成就被标记为完成；
- 隐藏成就上报进度后可能变为可见；
- 一次可以传入多个成就，适合批量上报；
- 完成成就后，Game Center 可能显示系统完成 Banner；
- `showsCompletionBanner = false` 可以关闭默认完成 Banner；
- 进度上报失败时，业务侧应记录并重试，不应回滚已经完成的业务事件。
- 批量上报示例：
```
let achievements = [
    GKAchievement(identifier: "achievement_first_session"),
    GKAchievement(identifier: "achievement_complete_tutorial")
]

achievements[0].percentComplete = 100
achievements[1].percentComplete = 50

try await GKAchievement.report(achievements)
```

### 4.4 重置进度

```
try await GKAchievement.resetAchievements()
```

该方法会重置当前本地玩家所有成就的完成进度，适合开发测试或明确的测试数据清理场景。不要在普通用户流程中调用。

## 五、读取成就描述和图片

- 如果 App 需要在自己的 UI 中展示成就，可加载 App Store Connect 配置的本地化描述：
```
let descriptions = try await GKAchievementDescription
    .loadAchievementDescriptions()
```

- 每个 `GKAchievementDescription` 可以读取：
- `identifier`；
- `title`；
- `unachievedDescription`；
- `achievedDescription`；
- `maximumPoints`；
- `isHidden`；
- `isReplayable`。
- 加载成就图片：
```
let image = try await description.loadImage()
```

- 如果只需要系统标准展示，不必复制成就元数据到 App 自己的配置文件，可以直接使用 Game Center Dashboard 或 access point。
## 六、展示 Game Center Dashboard

- Game Center 的系统界面可以展示成就、排行榜等内容。若 App 只需要提供入口，可以使用 GameKit 的 Dashboard / access point 能力，而不必实现完整的成就详情页。
- 如果需要自定义成就列表，则使用 `GKAchievementDescription` 加载描述和图片；用户完成状态则来自 `GKAchievement.loadAchievements()`。两者应通过 `identifier` 关联。
- 自定义列表要处理以下情况：
- App Store Connect 中已归档的成就不再返回；
- 配置中存在但玩家尚未上报的成就没有 `GKAchievement` 进度对象；
- 成就描述加载失败时显示降级状态；
- 本地列表不要把缺少进度对象误判为配置错误，应显示为 `0%` 未完成。
## 七、推荐代码分层

- Game Center 应作为独立适配层，业务层只产生事件：
```
业务事件
  ↓
AchievementRuleEngine
  ↓
AchievementReportRequest
  ↓
GameCenterReporter
  ↓
GameKit
```

- 建议组件：
```
AchievementDefinition
AchievementEvent
AchievementRuleEngine
AchievementReporter
GameCenterAuthenticator
```

- 职责划分：
- `AchievementDefinition`：维护 ID、触发条件和进度计算；
- `AchievementEvent`：表示业务已发生的事件；
- `AchievementRuleEngine`：将事件转换为成就进度；
- `AchievementReporter`：批量上报、失败重试和幂等处理；
- `GameCenterAuthenticator`：维护 Game Center 认证状态和登录 UI。
- 建议：
- 成就进度只增不减；
- 业务事件处理和 Game Center 上报幂等；
- 上报放到异步任务，不阻塞主线程；
- 认证失败和上报失败只影响成就同步，不影响核心业务；
- 通过 ID 常量或集中配置避免字符串散落；
- 发布后不修改 ID 的含义。
## 八、测试

### 8.1 Game Center 预发布测试环境

Apple 的 Game Center 预发布测试使用与正式游戏相同的服务器环境，减少 Sandbox 和 Production 的行为差异。测试数据可能对测试账号的 Game Center 好友可见，即使游戏版本尚未正式发布。

因此建议：

- 使用独立 Game Center 测试账号；
- 不使用开发者个人正式账号测试大量成就；
- 测试账号谨慎添加好友；
- 测试完成后清理排行榜测试数据；
- 真机验证，不只依赖模拟器。
### 8.2 Game Progress Manager

- 本地测试步骤：
1. `Product → Scheme → Edit Scheme`；
1. 选择 `Run → Options`；
1. 勾选 `Enable Debug Mode`；
1. `Debug → GameKit → Manage Game Progress`；
1. 选择实际测试设备和项目。
- Game Progress Manager 可以模拟：
- achievement 进度；
- leaderboard 分数；
- activity deep link；
- 资源重置。
该工具的测试数据保存在本地，不依赖 App Store Connect。重置后，之前的资源状态不能继续访问。

### 8.3 TestFlight 验证

TestFlight 阶段重点确认：

- 归档包包含 Game Center entitlement；
- App ID、Bundle ID 和 App Store Connect App 记录匹配；
- Game Center 已启用到目标 App 版本；
- Achievement ID 与客户端代码完全一致；
- 成就处于正确的 App Store Connect 状态；
- 认证界面、成就上报和系统 Banner 在真机上正常；
- App 升级后历史成就进度仍能读取。
### 8.4 测试矩阵

| 场景 | 验证点 |
| --- | --- |
| 未登录 Game Center | 核心功能不受影响 |
| 首次上报 `0%` | 不显示为完成 |
| 上报中间进度 | 进度正确显示 |
| 上报 `100%` | 完成状态和 Banner 正常 |
| 重复上报旧进度 | 进度不会回退 |
| 批量上报多个成就 | 批量接口正常 |
| 断网上报失败 | 业务成功，成就可重试 |
| 恢复网络 | 待上报事件能同步 |
| App 升级 | ID 和历史进度保持一致 |
| 换设备登录同一玩家 | Game Center 数据可同步 |
| 归档成就 | App 不把缺失资源当成崩溃条件 |
| TestFlight 构建 | entitlement 和后台配置正确 |

## 九、待确认事项

接入前需要结合项目实际情况确认：

- 最低支持 iOS 版本与当前 GameKit async API 可用性；
- App 是否只使用系统 Dashboard，还是需要自定义成就页；
- 是否需要服务端保存业务成就状态；
- 是否需要将 Game Center 玩家与自有账号绑定；
- 成就是按一次性完成上报，还是需要多阶段百分比进度；
- 是否需要多端共享成就定义；
- 首发成就 ID、分值、隐藏状态和本地化资源。
## 十、官方资料

- [Rewarding players with achievements](https://developer.apple.com/documentation/gamekit/rewarding-players-with-achievements)
- [GKAchievement](https://developer.apple.com/documentation/gamekit/gkachievement)
- [GKAchievementDescription](https://developer.apple.com/documentation/gamekit/gkachievementdescription)
- [`report(_:withCompletionHandler:)`](https://developer.apple.com/documentation/gamekit/gkachievement/report(_:withcompletionhandler:))
- [Initializing and configuring Game Center](https://developer.apple.com/documentation/gamekit/initializing-and-configuring-game-center)
- [Manage achievements](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-achievements/)
- [Achievements reference](https://developer.apple.com/help/app-store-connect/reference/game-center/achievements/)
- [Overview of testing Game Center](https://developer.apple.com/help/app-store-connect/configure-game-center/overview-of-testing-game-center/)
