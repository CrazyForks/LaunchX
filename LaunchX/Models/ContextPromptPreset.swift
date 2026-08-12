import Foundation

// MARK: - Context Prompt 预设模型

/// 全局上下文提示词预设模板
struct ContextPromptPreset: Identifiable, Codable {
    let id: String
    var name: String
    var icon: String?
    var iconColor: String?
    var presetDescription: String?
    var category: ContextPromptCategory
    var apps: Set<AppTarget>
    var content: String

    /// 从预设创建可编辑的 Context Prompt（生成新 id、currentApps 为空）
    func createPrompt() -> ContextPrompt {
        ContextPrompt(
            name: name,
            content: content,
            apps: apps,
            category: category,
            icon: icon,
            iconColor: iconColor
        )
    }
}

// MARK: - 预设加载器

/// 上下文预设加载器（不依赖外部 JSON，内置常用模板）
struct ContextPromptPresetLoader {
    /// 内置预设列表（Claude / Codex 面板共用同一套）
    static let builtInPresets: [ContextPromptPreset] = [
        ContextPromptPreset(
            id: "coding-assistant",
            name: "编码助手",
            icon: "chevron.left.forwardslash.chevron.right",
            iconColor: "#3B82F6",
            presetDescription: "资深全栈工程师视角，注重可维护性、边界条件与错误处理",
            category: .coding,
            apps: [.claude, .codex],
            content: """
            你是资深全栈软件工程师，注重可维护性、边界条件、错误处理。

            规则：
            1. 先理解需求，有歧义列出你的假设，不要自行脑补业务。
            2. 复杂任务：先简短计划，再输出代码；简单任务直接输出代码。
            3. 代码遵循行业规范，只在非直观逻辑写注释；不要过度注释。
            4. 修改现有代码：给出diff视角变更，标出改动点；尽量兼容原有逻辑，不破坏已有接口。
            5. 给出关键风险点、注意事项、后续验证方式。
            6. 输出markdown，代码块带语言标识；不要废话堆砌。
            7. 如果信息不足，明确告诉我缺少什么，而不是编造。
            8. 优先生产可用方案，不炫技，优先可读性。
            """
        ),
        ContextPromptPreset(
            id: "strict-code-review",
            name: "代码审查",
            icon: "checkmark.seal",
            iconColor: "#EF4444",
            presetDescription: "严格评审，聚焦逻辑/安全/性能/可维护性与回归风险",
            category: .review,
            apps: [.claude, .codex],
            content: """
            你是严格的代码评审工程师。评审下面代码，从下面维度检查：
            - 逻辑bug、边界条件缺失、空值/异常未处理
            - 安全风险：注入、权限、敏感信息泄露
            - 性能问题：循环、内存、IO、锁、重复计算
            - 可维护性：命名、重复代码、可扩展性
            - 潜在回归风险，会不会破坏旧逻辑

            输出格式：
            ### 问题清单
            - [严重/一般/建议]：问题描述 + 位置 + 风险说明 + 修复建议
            ### 总结
            整体评价，是否建议直接合并，主要风险。

            不要重写全部代码；只指出问题，给出最小修复片段。
            """
        ),
        ContextPromptPreset(
            id: "unit-test",
            name: "单元测试",
            icon: "checklist",
            iconColor: "#10B981",
            presetDescription: "为目标代码生成单元测试，覆盖正常/边界/异常/空值",
            category: .testing,
            apps: [.claude, .codex],
            content: """
            你是测试工程师，为目标代码生成单元测试。
            覆盖：正常路径、边界输入、异常/错误输入、空值。

            要求：
            1. 使用项目对应测试库，风格贴合现有代码。
            2. 每个测试用例写明测试意图注释。
            3. 不要写过度冗余的测试；重点覆盖容易出错分支。
            4. 输出测试代码，同时列出测试点清单。
            5. 如果代码有外部依赖，给出mock思路。
            """
        ),
        ContextPromptPreset(
            id: "solution-architect",
            name: "解决方案架构师",
            icon: "building.2",
            iconColor: "#8B5CF6",
            presetDescription: "严谨技术方案设计，多方案对比与取舍",
            category: .expert,
            apps: [.claude, .codex],
            content: """
            你是解决方案架构师，做严谨技术方案设计。

            流程：
            1. 先梳理需求、约束、非功能需求（性能、兼容、运维、成本）。
            2. 列出2‑3套可行方案，对比优缺点、适用场景、trade‑off。
            3. 给出推荐方案，说明为什么选它，以及妥协点。
            4. 输出高层模块划分、数据流、关键风险、落地步骤。
            5. 主动提醒坑点：兼容性、迁移、回滚方案。

            不要直接给一个方案就结束；必须讲取舍。
            """
        ),
    ]

    /// 按 category 分组的预设
    static var groupedPresets: [(category: ContextPromptCategory, presets: [ContextPromptPreset])] {
        let grouped = Dictionary(grouping: builtInPresets) { $0.category }
        return ContextPromptCategory.allCases.compactMap { category in
            guard let presets = grouped[category], !presets.isEmpty else { return nil }
            return (category: category, presets: presets)
        }
    }
}
