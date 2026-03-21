import Foundation

// MARK: - 磁盘写入优化设置

/// 磁盘写入优化配置
/// 用于管理所有磁盘写入优化的开关和参数
struct DiskWriteOptimizationSettings: Codable {
    // MARK: - 单例和缓存

    private static var cachedSettings: DiskWriteOptimizationSettings?
    private static let cacheQueue = DispatchQueue(label: "com.launchx.settings.cache")

    /// 获取共享实例（带缓存）
    static var shared: DiskWriteOptimizationSettings {
        return cacheQueue.sync {
            if let cached = cachedSettings {
                return cached
            }
            let settings = load()
            cachedSettings = settings
            return settings
        }
    }

    /// 清除缓存（在保存新配置后调用）
    private static func clearCache() {
        cacheQueue.sync {
            cachedSettings = nil
        }
    }

    // MARK: - 配置属性

    // 剪贴板防抖动优化
    var debounceClipboardSaveEnabled: Bool
    var clipboardDebounceInterval: Double  // 秒

    // SQLite WAL 优化
    var walOptimizationEnabled: Bool
    var walAutoCheckpointPages: Int  // 页数（默认 10000）
    var walMaxSizeMB: Int  // WAL 文件最大大小（MB），超过则强制 checkpoint

    // FSEvents 批量处理
    var fsEventsBatchProcessingEnabled: Bool
    var fsEventsBatchInterval: Double  // 秒（默认 0.5）
    var fsEventsMaxQueueSize: Int  // 队列最大大小

    // 启动优化
    var delayedFSEventsStartEnabled: Bool
    var fsEventsStartDelay: Double  // 秒（默认 5.0）

    // 空闲 checkpoint
    var idleCheckpointEnabled: Bool
    var idleCheckpointInterval: Double  // 秒（默认 300 = 5分钟）

    // 性能监控
    var performanceLoggingEnabled: Bool

    static let `default` = DiskWriteOptimizationSettings(
        debounceClipboardSaveEnabled: true,
        clipboardDebounceInterval: 2.0,
        walOptimizationEnabled: true,
        walAutoCheckpointPages: 10000,
        walMaxSizeMB: 100,
        fsEventsBatchProcessingEnabled: true,
        fsEventsBatchInterval: 0.5,
        fsEventsMaxQueueSize: 1000,
        delayedFSEventsStartEnabled: true,
        fsEventsStartDelay: 5.0,
        idleCheckpointEnabled: true,
        idleCheckpointInterval: 300.0,
        performanceLoggingEnabled: false
    )

    static func load() -> DiskWriteOptimizationSettings {
        if let data = UserDefaults.standard.data(forKey: "diskWriteOptimizationSettings"),
           let settings = try? JSONDecoder().decode(DiskWriteOptimizationSettings.self, from: data)
        {
            return settings
        }
        return .default
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "diskWriteOptimizationSettings")
            // 清除缓存，下次访问时会重新加载
            DiskWriteOptimizationSettings.clearCache()
        }
    }

    // MARK: - 便捷方法

    /// 获取 WAL 最大大小（字节）
    var walMaxSizeBytes: Int64 {
        return Int64(walMaxSizeMB) * 1024 * 1024
    }

    /// 获取空闲 checkpoint 间隔（秒）
    var idleCheckpointIntervalSeconds: TimeInterval {
        return idleCheckpointInterval
    }
}
