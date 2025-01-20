// RouterHub.Swift
// https://github.com/kumatt/Connector
// RouterHub is a lightweight routing tool designed for inter-module communication and navigation in modular Swift applications. It aims to decouple dependencies between modules, enhancing the scalability and maintainability of projects. By enabling route registration, path mapping, and dynamic parameter passing, it provides an efficient and intuitive approach to modular development.
// MARK: - 路由集线器，1对1的绑定

import Foundation

/// 路由的命名空间 RouterNavigator
public enum RouterNavigator { }

/// 普通路由，直接获取目标值
public protocol AnyDirectRouter {
    /// 注册路由
    @MainActor static func register(context: RouterHub, _ gotoHandle: @escaping (Self) -> Any?)
    /// 注销路由
    @MainActor static func unregister(context: RouterHub)
    /// 获取路由值对应的对象
    @MainActor static func resolve<T>(context: RouterHub, _ route: Self) throws -> T
}

public extension AnyDirectRouter {
    @MainActor static func register(context: RouterHub, _ gotoHandle: @escaping (Self) -> Any?) {
        context.register(gotoHandle)
    }
    
    @MainActor static func unregister(context: RouterHub) {
        context.unregister(Self.self)
    }
    
    @MainActor static func resolve<T>(context: RouterHub, _ route: Self) throws -> T {
        try context.resolve(route)
    }
}

/// 支持并发的路由
public protocol AnyConcurrentRouter {
    /// 注册路由
    @MainActor static func register(context: RouterHub, _ gotoHandle: @escaping (Self) async -> Any?)
    /// 注销路由
    @MainActor static func unregister(context: RouterHub)
    /// 获取路由值对应的对象
    @MainActor static func resolve<T>(context: RouterHub, _ route: Self) async throws -> T
}

public extension AnyConcurrentRouter {
    @MainActor static func register(context: RouterHub, _ gotoHandle: @escaping (Self) async -> Any?) {
        context.register(gotoHandle)
    }
    
    @MainActor static func unregister(context: RouterHub) {
        context.unregister(Self.self)
    }
    
    @MainActor static func resolve<T>(context: RouterHub, _ route: Self) async throws -> T {
        try await context.resolve(route)
    }
}

/// 路由集线器
@MainActor
public final class RouterHub {
    
    public static let `default` = RouterHub()
    /// 路由映射，返回goto的对象
    private var gotoMappings: [ObjectIdentifier: any AnyReducer] = [:]
    
    /// 初始化方法
    public init() { }
}

// MARK: - Direct goto
private extension RouterHub {
    /// 注册路由，绑定和重定向
    /// 将路由与对应的目标（页面、控制器、回调等）绑定。
    /// - Parameter gotoHandles: 路由响应
    func register<R>(_ gotoHandles: @escaping (R) -> Any?) {
        gotoMappings[ObjectIdentifier(R.self)] = DirectReducer(block: gotoHandles)
    }
    
    /// 获取目标对象
    /// - Parameter rawValue: 类型
    /// - Returns: 指定类型的返回值
    func resolve<R, T>(_ route: R) throws -> T {
        guard let reducer = gotoMappings[ObjectIdentifier(R.self)] as? RouterHub.DirectReducer<R> else {
            throw Reason.unRegisterEnumType
        }
        guard let value = reducer(route) else {
            throw Reason.rawMaterialUnqualified
        }
        guard let result = value as? T else {
            throw Reason.valueTypeConversionError
        }
        return result
    }
}

// MARK: - Concurrent goto
private extension RouterHub {
    /// 注册路由
    /// - Parameter gotoHandles: 路由响应
    func register<R>(_ gotoHandles: @escaping (R) async -> Any?) {
        gotoMappings[ObjectIdentifier(R.self)] = ConcurrentReducer(block: gotoHandles)
    }
    
    /// 开始产出产品
    /// - Parameter enumType: 类型
    /// - Returns: 指定类型的返回值
    func resolve<R, T>(_ rawValue: R) async throws -> T {
        guard let reducer = gotoMappings[ObjectIdentifier(R.self)] as? RouterHub.ConcurrentReducer<R> else {
            throw Reason.unRegisterEnumType
        }
        guard let value = await reducer(rawValue) else {
            throw Reason.rawMaterialUnqualified
        }
        guard let result = value as? T else {
            throw Reason.valueTypeConversionError
        }
        return result
    }
}

// MARK: - unregister
private extension RouterHub {
    /// 注销路由
    /// - Parameter type: 数据类型
    func unregister<R>(_ type: R.Type) {
        gotoMappings[ObjectIdentifier(type)] = nil
    }
}

// MARK: - RouterHub.Reason
extension RouterHub {
    /// 失败原因
    public enum Reason: Error {
        /// 类型没有注册
        case unRegisterEnumType
        /// 值未做处理
        case rawMaterialUnqualified
        /// 值的类型不是指定返回类型
        case valueTypeConversionError
    }
}

// MARK: - RouterHub.DirectReducer
private extension RouterHub {
    struct DirectReducer<R>: AnyReducer {
        let block: (R) -> Any?
        
        func callAsFunction(_ rawValue: R) -> Any? {
            block(rawValue)
        }
    }
}

// MARK: - RouterHub.ConcurrentReducer
private extension RouterHub {
    struct ConcurrentReducer<R>: AnyReducer {
        let block: (R) async -> Any?
        
        func callAsFunction(_ rawValue: R) async -> Any? {
            await block(rawValue)
        }
    }
}
