# Connector

Connector 是一个轻量级的 Swift 事件总线和路由工具，专为 iOS 应用模块化开发设计。它提供了两个核心功能模块：

- **ActionBus** - 实现模块间的多对多事件通信
- **RouterHub** - 轻量级路由器，用于处理1对1的模块间导航

## 特性

- ✨ 轻量级自定义事件订阅机制
- 🔄 支持同步/异步路由
- 🎯 类型安全的API设计
- 🛡️ 线程安全（所有操作都在主线程执行）
- 🎨 简洁优雅的链式调用
- 💡 简单易用的API

## 设计思路

### ActionBus 设计

ActionBus 采用发布-订阅模式，主要包含以下核心组件：

1. `AnyAction` 协议：定义事件的基本行为
   - `send`: 发送事件
   - `sink`: 订阅事件

2. `ActionBus` 类：
   - 使用 `[String: Set<Reducer>]` 管理事件订阅关系
   - 确保线程安全（@MainActor）
   - 支持对象绑定的事件监听
   - 使用 AnyCancellable 管理订阅的生命周期

### RouterHub 设计

RouterHub 采用职责链模式，包含以下核心组件：

1. `AnyDirectRouter` 协议：同步路由
2. `AnyConcurrentRouter` 协议：异步路由
3. `RouterHub` 类：路由注册和解析中心

## 安装

### Swift Package Manager

`https://github.com/kumatt/Connector.git`

### ActionBus 使用示例

#### 1. 定义事件：

```swift
import Connector

extension ActionCenter {
    enum UserAction: AnyAction {
        case login(userId: String)
        case logout
    }
}
```

#### 2. 订阅事件：

```swift
let cancellable = ActionCenter.UserAction.sink(context: .default) { action in
    switch action {
        case .login(let userId):
            print("用户登录：userId)") case .logout: print("用户登出") 
    } 
}
```

#### 3. 发送事件：

```swift
ActionCenter.UserAction.send(context: .default, .login(userId: "12345")) 
```

### RouterHub 使用示例 

#### 1. 定义路由： 

```swift 
extension RouterNavigator { 
    enum UserRouter: AnyDirectRouter { 
        case profile(userId: String) 
        case settings 
    } 
} 
``` 

#### 2. 注册路由处理： 

```swift 
RouterNavigator.UserRouter.register(context: .default) { route in switch route { case .profile(let userId): return UserProfileViewController(userId: userId) case .settings: return SettingsViewController() } } 
```

#### 3. 使用路由： 

##### 同步路由示例

```swift 
do {
    let profileVC: UIViewController = try RouterNavigator.UserRouter.resolve(
        context: .default,
        .profile(userId: "12345")
    )
    navigationController.pushViewController(profileVC, animated: true)
} catch {
    print("路由错误：\(error)")
}
``` 

##### 异步路由示例 
```swift 
extension RouterNavigator {
    enum AsyncRouter: AnyConcurrentRouter {
        case fetchUserData(userId: String)
    }
}

// 注册异步路由
RouterNavigator.AsyncRouter.register(context: .default) { route async -> Any? in
    switch route {
    case .fetchUserData(let userId):
        return await fetchUserDataFromServer(userId: userId)
    }
}

// 使用异步路由
Task {
    do {
        let userData: UserData = try await RouterNavigator.AsyncRouter.resolve(
            context: .default,
            .fetchUserData(userId: "12345")
        )
        print("获取到用户数据：\(userData)")
    } catch {
        print("获取数据失败：\(error)")
    }
}
``` 
