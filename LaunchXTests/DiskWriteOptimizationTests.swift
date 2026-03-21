import XCTest
@testable import LaunchX

/// 磁盘写入优化功能的单元测试
final class DiskWriteOptimizationTests: XCTestCase {

    // MARK: - 磁盘写入监控测试

    func testDiskWriteMonitor_RecordWrite() {
        // Given: 重置监控器
        let monitor = DiskWriteMonitor.shared
        monitor.reset()

        // When: 记录写入
        let bytesToWrite: Int64 = 1024 * 100  // 100 KB
        monitor.recordWrite(bytes: bytesToWrite)

        // Then: 验证总写入量
        let stats = monitor.getStatistics()
        XCTAssertEqual(stats.totalBytes, bytesToWrite, "总写入量应该等于记录的字节数")
    }

    func testDiskWriteMonitor_WriteRateCalculation() {
        // Given: 重置监控器
        let monitor = DiskWriteMonitor.shared
        monitor.reset()

        // When: 在短时间内记录多次写入
        let bytesPerWrite: Int64 = 1024 * 10  // 10 KB
        let writeCount = 5

        for _ in 0..<writeCount {
            monitor.recordWrite(bytes: bytesPerWrite)
            Thread.sleep(forTimeInterval: 0.1)  // 100ms间隔
        }

        // Then: 验证写入速率被正确计算
        let stats = monitor.getStatistics()
        XCTAssertGreaterThan(stats.currentRateBytesPerSecond, 0, "当前写入速率应该大于0")
        XCTAssertGreaterThan(stats.averageRateBytesPerSecond, 0, "平均写入速率应该大于0")
    }

    func testDiskWriteMonitor_HealthScore() {
        // Given: 重置监控器
        let monitor = DiskWriteMonitor.shared
        monitor.reset()

        // When: 模拟低写入量（健康状态）
        monitor.recordWrite(bytes: 1024 * 10)  // 10 KB
        Thread.sleep(forTimeInterval: 1.0)

        // Then: 验证健康度评分
        let stats = monitor.getStatistics()
        XCTAssertGreaterThanOrEqual(stats.healthScore, 80, "低写入量应该有高健康度评分")
        XCTAssertEqual(stats.healthStatus, "优秀", "健康状态应该是优秀")
    }

    func testDiskWriteMonitor_Reset() {
        // Given: 记录一些写入
        let monitor = DiskWriteMonitor.shared
        monitor.recordWrite(bytes: 1024 * 100)

        // When: 重置监控器
        monitor.reset()

        // Then: 验证统计被清零
        let stats = monitor.getStatistics()
        XCTAssertEqual(stats.totalBytes, 0, "重置后总写入量应该为0")
    }

    // MARK: - 配置管理测试

    func testDiskWriteOptimizationSettings_DefaultValues() {
        // Given: 加载默认配置
        let settings = DiskWriteOptimizationSettings.default

        // Then: 验证默认值
        XCTAssertTrue(settings.debounceClipboardSaveEnabled, "防抖动保存应该默认启用")
        XCTAssertEqual(settings.clipboardDebounceInterval, 2.0, "防抖动间隔应该是2秒")
        XCTAssertTrue(settings.walOptimizationEnabled, "WAL优化应该默认启用")
        XCTAssertEqual(settings.walAutoCheckpointPages, 10000, "WAL checkpoint阈值应该是10000页")
        XCTAssertTrue(settings.fsEventsBatchProcessingEnabled, "FSEvents批量处理应该默认启用")
    }

    func testDiskWriteOptimizationSettings_SharedCache() {
        // Given: 获取共享实例
        let settings1 = DiskWriteOptimizationSettings.shared
        let settings2 = DiskWriteOptimizationSettings.shared

        // Then: 验证是同一个实例（缓存生效）
        XCTAssertEqual(settings1.debounceClipboardSaveEnabled, settings2.debounceClipboardSaveEnabled)
        XCTAssertEqual(settings1.walOptimizationEnabled, settings2.walOptimizationEnabled)
    }

    func testDiskWriteOptimizationSettings_SaveAndLoad() {
        // Given: 创建自定义配置
        var settings = DiskWriteOptimizationSettings.default
        settings.debounceClipboardSaveEnabled = false
        settings.clipboardDebounceInterval = 3.0

        // When: 保存配置
        settings.save()

        // Then: 重新加载并验证
        let loadedSettings = DiskWriteOptimizationSettings.load()
        XCTAssertEqual(loadedSettings.debounceClipboardSaveEnabled, false, "保存的配置应该被正确加载")
        XCTAssertEqual(loadedSettings.clipboardDebounceInterval, 3.0, "保存的间隔应该被正确加载")

        // Cleanup: 恢复默认配置
        DiskWriteOptimizationSettings.default.save()
    }

    // MARK: - 统计数据结构测试

    func testDiskWriteStatistics_FormattedValues() {
        // Given: 创建统计数据
        let stats = DiskWriteStatistics(
            totalBytes: 1024 * 1024 * 100,  // 100 MB
            currentRateBytesPerSecond: 1024 * 50,  // 50 KB/s
            averageRateBytesPerSecond: 1024 * 30,  // 30 KB/s
            uptimeSeconds: 3661,  // 1小时1分1秒
            startTime: Date()
        )

        // Then: 验证格式化输出
        XCTAssertTrue(stats.formattedTotalBytes.contains("MB"), "总写入量应该以MB为单位")
        XCTAssertTrue(stats.formattedCurrentRate.contains("KB"), "当前速率应该以KB/s为单位")
        XCTAssertTrue(stats.formattedUptime.contains("h"), "运行时长应该包含小时")
    }

    func testDiskWriteStatistics_HealthScoreCalculation() {
        // Test Case 1: 优秀（<= 50 KB/s）
        let excellentStats = DiskWriteStatistics(
            totalBytes: 1024 * 1024,
            currentRateBytesPerSecond: 1024 * 40,  // 40 KB/s
            averageRateBytesPerSecond: 1024 * 40,
            uptimeSeconds: 3600,
            startTime: Date()
        )
        XCTAssertEqual(excellentStats.healthScore, 100, "40 KB/s应该是满分")

        // Test Case 2: 良好（50-80 KB/s范围内，评分70-100）
        // 使用70 KB/s，应该得到约80分
        let goodStats = DiskWriteStatistics(
            totalBytes: 1024 * 1024,
            currentRateBytesPerSecond: 1024 * 70,  // 70 KB/s
            averageRateBytesPerSecond: 1024 * 70,
            uptimeSeconds: 3600,
            startTime: Date()
        )
        // 70 KB/s: ratio = (70-50)/(80-50) = 20/30 = 0.667
        // score = 100 - 0.667 * 30 = 100 - 20 = 80
        XCTAssertEqual(goodStats.healthScore, 80, "70 KB/s应该得到80分")

        // Test Case 3: 警告（80-100 KB/s范围内，评分40-70）
        let warningStats = DiskWriteStatistics(
            totalBytes: 1024 * 1024,
            currentRateBytesPerSecond: 1024 * 90,  // 90 KB/s
            averageRateBytesPerSecond: 1024 * 90,
            uptimeSeconds: 3600,
            startTime: Date()
        )
        // 90 KB/s: ratio = (90-80)/(100-80) = 10/20 = 0.5
        // score = 70 - 0.5 * 30 = 70 - 15 = 55
        XCTAssertEqual(warningStats.healthScore, 55, "90 KB/s应该得到55分")

        // Test Case 4: 严重（> 100 KB/s，评分0-40）
        let criticalStats = DiskWriteStatistics(
            totalBytes: 1024 * 1024,
            currentRateBytesPerSecond: 1024 * 120,  // 120 KB/s
            averageRateBytesPerSecond: 1024 * 120,
            uptimeSeconds: 3600,
            startTime: Date()
        )
        // 120 KB/s: ratio = min((120-100)/100, 1.0) = 0.2
        // score = 40 - 0.2 * 40 = 40 - 8 = 32
        XCTAssertEqual(criticalStats.healthScore, 32, "120 KB/s应该得到32分")

        // Test Case 5: 边界测试 - 50 KB/s（目标值）
        let targetStats = DiskWriteStatistics(
            totalBytes: 1024 * 1024,
            currentRateBytesPerSecond: 1024 * 50,
            averageRateBytesPerSecond: 1024 * 50,
            uptimeSeconds: 3600,
            startTime: Date()
        )
        XCTAssertEqual(targetStats.healthScore, 100, "50 KB/s（目标值）应该是满分")

        // Test Case 6: 边界测试 - 80 KB/s（警告阈值）
        let thresholdStats = DiskWriteStatistics(
            totalBytes: 1024 * 1024,
            currentRateBytesPerSecond: 1024 * 80,
            averageRateBytesPerSecond: 1024 * 80,
            uptimeSeconds: 3600,
            startTime: Date()
        )
        XCTAssertEqual(thresholdStats.healthScore, 70, "80 KB/s（警告阈值）应该得到70分")
    }

    func testDiskWriteStatistics_Recommendations() {
        // Test Case 1: 正常情况
        let normalStats = DiskWriteStatistics(
            totalBytes: 1024 * 1024,
            currentRateBytesPerSecond: 1024 * 30,
            averageRateBytesPerSecond: 1024 * 30,
            uptimeSeconds: 3600,
            startTime: Date()
        )
        XCTAssertFalse(normalStats.recommendations.isEmpty, "应该有建议")
        XCTAssertTrue(normalStats.recommendations.contains { $0.contains("正常") }, "正常情况应该有正面建议")

        // Test Case 2: 高写入速率
        let highRateStats = DiskWriteStatistics(
            totalBytes: 1024 * 1024,
            currentRateBytesPerSecond: 1024 * 110,  // 超过100 KB/s
            averageRateBytesPerSecond: 1024 * 90,   // 超过80 KB/s
            uptimeSeconds: 3600,
            startTime: Date()
        )
        XCTAssertGreaterThan(highRateStats.recommendations.count, 1, "高写入速率应该有多条建议")
    }

    // MARK: - 性能测试

    func testPerformance_DiskWriteMonitor_RecordWrite() {
        let monitor = DiskWriteMonitor.shared
        monitor.reset()

        // 测试记录1000次写入的性能
        let startTime = Date()
        for _ in 0..<1000 {
            monitor.recordWrite(bytes: 1024)
        }
        let duration = Date().timeIntervalSince(startTime)

        // 验证性能：1000次写入应该在1秒内完成
        XCTAssertLessThan(duration, 1.0, "记录1000次写入应该在1秒内完成，实际耗时: \(duration)秒")
    }

    func testPerformance_DiskWriteMonitor_GetStatistics() {
        let monitor = DiskWriteMonitor.shared

        // 先记录一些数据
        for _ in 0..<100 {
            monitor.recordWrite(bytes: 1024)
        }

        // 测试获取统计数据的性能
        let startTime = Date()
        for _ in 0..<100 {
            _ = monitor.getStatistics()
        }
        let duration = Date().timeIntervalSince(startTime)

        // 验证性能：100次获取统计应该在0.1秒内完成
        XCTAssertLessThan(duration, 0.1, "获取100次统计应该在0.1秒内完成，实际耗时: \(duration)秒")
    }
}
