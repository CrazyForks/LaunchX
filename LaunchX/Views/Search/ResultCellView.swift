import AppKit

// MARK: - Result Cell View

/// 优化版 Cell：用 isHidden 控制元素可见性替代频繁约束切换，减少每次 configure 的 layout 开销
class ResultCellView: NSView {
    // MARK: - Subviews

    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let aliasBadgeView = NSView()
    private let aliasLabel = NSTextField(labelWithString: "")
    private let pathLabel = NSTextField(labelWithString: "")
    private let backgroundView = NSView()

    // 右侧装饰元素容器（箭头/统计/链接），用 StackView 自动管理，isHidden 时自动折叠
    private let rightAccessoryStack = NSStackView()

    private let arrowIndicator = NSImageView()
    private let linkIndicator = NSImageView()
    private let portLabel = NSTextField(labelWithString: "")
    private let cpuIcon = NSImageView()
    private let cpuLabel = NSTextField(labelWithString: "")
    private let memoryIcon = NSImageView()
    private let memoryLabel = NSTextField(labelWithString: "")

    // MARK: - 常量约束引用（只设置一次，不切换）

    private var nameLabelToAccessoryConstraint: NSLayoutConstraint!

    var onIconClick: (() -> Void)?

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    @objc private func iconClicked() {
        onIconClick?()
    }

    // MARK: - Setup

    private func setupViews() {
        // Background
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 8
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        // Icon
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let iconClickGesture = NSClickGestureRecognizer(target: self, action: #selector(iconClicked))
        iconView.addGestureRecognizer(iconClickGesture)
        addSubview(iconView)

        // Name label
        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addSubview(nameLabel)

        // Alias badge
        aliasBadgeView.wantsLayer = true
        aliasBadgeView.layer?.cornerRadius = 6
        aliasBadgeView.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.25).cgColor
        aliasBadgeView.translatesAutoresizingMaskIntoConstraints = false
        aliasBadgeView.isHidden = true
        addSubview(aliasBadgeView)

        aliasLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        aliasLabel.textColor = .secondaryLabelColor
        aliasLabel.translatesAutoresizingMaskIntoConstraints = false
        aliasLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(aliasLabel)

        // Path label
        pathLabel.font = .systemFont(ofSize: 11)
        pathLabel.textColor = .secondaryLabelColor
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pathLabel)

        // Right accessory stack — all right-side elements go here
        rightAccessoryStack.translatesAutoresizingMaskIntoConstraints = false
        rightAccessoryStack.isHidden = true
        rightAccessoryStack.orientation = .horizontal
        rightAccessoryStack.spacing = 6
        rightAccessoryStack.alignment = .centerY
        rightAccessoryStack.distribution = .fill
        addSubview(rightAccessoryStack)

        // Arrow indicator
        arrowIndicator.image = NSImage(
            systemSymbolName: "arrow.right.to.line",
            accessibilityDescription: "Tab to open")
        arrowIndicator.contentTintColor = .secondaryLabelColor
        arrowIndicator.translatesAutoresizingMaskIntoConstraints = false
        arrowIndicator.widthAnchor.constraint(equalToConstant: 16).isActive = true
        arrowIndicator.heightAnchor.constraint(equalToConstant: 16).isActive = true
        rightAccessoryStack.addArrangedSubview(arrowIndicator)

        // Link indicator
        linkIndicator.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Has URL")
        linkIndicator.contentTintColor = .systemBlue
        linkIndicator.translatesAutoresizingMaskIntoConstraints = false
        linkIndicator.widthAnchor.constraint(equalToConstant: 13).isActive = true
        linkIndicator.heightAnchor.constraint(equalToConstant: 13).isActive = true
        rightAccessoryStack.addArrangedSubview(linkIndicator)

        // Port label
        portLabel.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        portLabel.textColor = .secondaryLabelColor
        portLabel.translatesAutoresizingMaskIntoConstraints = false
        portLabel.setContentHuggingPriority(.required, for: .horizontal)
        portLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        portLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        rightAccessoryStack.addArrangedSubview(portLabel)

        // CPU icon
        cpuIcon.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "CPU")
        cpuIcon.contentTintColor = .secondaryLabelColor
        cpuIcon.translatesAutoresizingMaskIntoConstraints = false
        cpuIcon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        cpuIcon.heightAnchor.constraint(equalToConstant: 12).isActive = true
        rightAccessoryStack.addArrangedSubview(cpuIcon)

        // CPU label
        cpuLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        cpuLabel.textColor = .secondaryLabelColor
        cpuLabel.translatesAutoresizingMaskIntoConstraints = false
        cpuLabel.widthAnchor.constraint(equalToConstant: 45).isActive = true
        rightAccessoryStack.addArrangedSubview(cpuLabel)

        // Memory icon
        memoryIcon.image = NSImage(systemSymbolName: "memorychip", accessibilityDescription: "Memory")
        memoryIcon.contentTintColor = .secondaryLabelColor
        memoryIcon.translatesAutoresizingMaskIntoConstraints = false
        memoryIcon.widthAnchor.constraint(equalToConstant: 12).isActive = true
        memoryIcon.heightAnchor.constraint(equalToConstant: 12).isActive = true
        rightAccessoryStack.addArrangedSubview(memoryIcon)

        // Memory label
        memoryLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        memoryLabel.textColor = .secondaryLabelColor
        memoryLabel.translatesAutoresizingMaskIntoConstraints = false
        memoryLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        rightAccessoryStack.addArrangedSubview(memoryLabel)

        // 固定约束 — 只设置一次，后续用 isHidden 控制
        nameLabelToAccessoryConstraint = nameLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: rightAccessoryStack.leadingAnchor, constant: -12)

        NSLayoutConstraint.activate([
            // Background
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            backgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            // Icon
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            // Name label
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabelToAccessoryConstraint,

            // Name trailing fallback
            nameLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor, constant: -20),

            // Alias badge
            aliasBadgeView.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            aliasBadgeView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),

            aliasLabel.leadingAnchor.constraint(equalTo: aliasBadgeView.leadingAnchor, constant: 6),
            aliasLabel.trailingAnchor.constraint(equalTo: aliasBadgeView.trailingAnchor, constant: -6),
            aliasLabel.topAnchor.constraint(equalTo: aliasBadgeView.topAnchor, constant: 2),
            aliasLabel.bottomAnchor.constraint(equalTo: aliasBadgeView.bottomAnchor, constant: -2),

            // Right accessory stack
            rightAccessoryStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            rightAccessoryStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Path label
            pathLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            pathLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            pathLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor, constant: -20),
        ])
    }

    // MARK: - Configure

    func configure(with item: SearchResult, isSelected: Bool, hideArrow: Bool = false) {
        // 分组标题特殊处理
        if item.isSectionHeader {
            configureSectionHeader(with: item)
            return
        }

        // 恢复普通模式
        iconView.isHidden = false
        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = .labelColor

        // ---- 左侧内容 ----
        nameLabel.stringValue = item.name

        if let alias = item.displayAlias, !alias.isEmpty {
            aliasLabel.stringValue = alias
            aliasBadgeView.isHidden = false
        } else {
            aliasLabel.stringValue = ""
            aliasBadgeView.isHidden = true
        }

        // ---- 图标 ----
        configureIcon(for: item, isSelected: isSelected)

        // ---- 路径标签（仅文件/文件夹显示） ----
        let isApp = item.path.hasSuffix(".app")
        let isEntry = item.isBookmarkEntry || item.is2FAEntry || item.isMemeEntry
            || item.isFavoriteEntry
        let hasProcessStats = item.processStats != nil && !item.processStats!.isEmpty
        let isReminder = item.isReminder
        let showPath =
            !isApp && !item.isWebLink && !item.isUtility && !item.isSystemCommand
            && !isEntry && !hasProcessStats && !isReminder && !item.isClaudeCodeItem

        pathLabel.isHidden = !showPath
        pathLabel.stringValue = showPath ? item.path : ""

        // 名称字体：高级条目加粗加大
        let isPremiumItem =
            isApp || item.isWebLink || item.isUtility || item.isSystemCommand
            || isEntry || hasProcessStats || isReminder || item.isClaudeCodeItem
        nameLabel.font = isPremiumItem
            ? .systemFont(ofSize: 14, weight: .medium)
            : .systemFont(ofSize: 13, weight: .medium)

        // ---- 右侧装饰：用 StackView 的 isHidden 控制，无需切换约束 ----
        configureRightAccessories(
            item: item, isSelected: isSelected, hideArrow: hideArrow,
            hasProcessStats: hasProcessStats, isReminder: isReminder)

        // ---- 选中样式 ----
        applySelectionStyle(isSelected: isSelected, isReminder: isReminder)
    }

    // MARK: - Private helpers

    private func configureIcon(for item: SearchResult, isSelected: Bool) {
        if item.isReminder {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            iconView.image = item.icon.withSymbolConfiguration(config)
            let color: NSColor = item.reminderColor ?? .systemOrange
            iconView.contentTintColor = isSelected ? .white : color
        } else {
            iconView.image = item.icon
            if item.isClaudeCodeItem && item.path == "active" {
                iconView.contentTintColor = isSelected ? .white : nil
            } else {
                iconView.contentTintColor = nil
            }
        }
    }

    private func configureRightAccessories(
        item: SearchResult, isSelected: Bool, hideArrow: Bool,
        hasProcessStats: Bool, isReminder: Bool
    ) {
        // 分组标题下隐藏所有装饰
        guard !item.isSectionHeader else {
            setRightAccessories(hidden: true)
            return
        }

        // 决定显示哪些元素
        let isIDE = IDEType.detect(from: item.path) != nil
        let isFolder = item.isDirectory && !item.path.hasSuffix(".app")
        let isQueryWebLink = item.isWebLink && item.supportsQueryExtension
        let isEntry = item.isBookmarkEntry || item.is2FAEntry || item.isMemeEntry
            || item.isFavoriteEntry || item.isClaudeCodeItem

        let showArrow =
            !hideArrow && !hasProcessStats
            && (isIDE || isFolder || isQueryWebLink || item.isUtility || isEntry)

        // 链接指示器
        if isReminder {
            let hasLink = item.reminderURL != nil
            linkIndicator.isHidden = !hasLink
            linkIndicator.contentTintColor = isSelected
                ? .white.withAlphaComponent(0.9) : .systemBlue
        } else {
            linkIndicator.isHidden = true
        }

        // 箭头
        arrowIndicator.isHidden = !showArrow

        // 进程统计
        if hasProcessStats && !isReminder {
            let stats = item.processStats!
            let parts = stats.components(separatedBy: "|")
            if parts.count >= 3 {
                portLabel.stringValue = parts[0]
                cpuLabel.stringValue = parts[1]
                memoryLabel.stringValue = parts[2]
            } else if parts.count == 2 {
                portLabel.stringValue = ""
                cpuLabel.stringValue = parts[0]
                memoryLabel.stringValue = parts[1]
            }
            portLabel.isHidden = false
            cpuIcon.isHidden = false
            cpuLabel.isHidden = false
            memoryIcon.isHidden = false
            memoryLabel.isHidden = false
        } else if isReminder, let stats = item.processStats {
            // 提醒事项用 portLabel 显示日期/列表
            portLabel.isHidden = false
            portLabel.stringValue = stats
            portLabel.alignment = .right
            portLabel.lineBreakMode = .byTruncatingTail
            portLabel.textColor = isSelected
                ? .white.withAlphaComponent(0.9) : .secondaryLabelColor
            portLabel.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
            portLabel.setContentHuggingPriority(.required, for: .horizontal)
            cpuIcon.isHidden = true
            cpuLabel.isHidden = true
            memoryIcon.isHidden = true
            memoryLabel.isHidden = true
        } else {
            portLabel.isHidden = true
            cpuIcon.isHidden = true
            cpuLabel.isHidden = true
            memoryIcon.isHidden = true
            memoryLabel.isHidden = true
        }

        // 整体显示/隐藏：有任何子元素可见就显示整个 Stack
        let anyAccessoryVisible = !arrowIndicator.isHidden || !linkIndicator.isHidden
            || !portLabel.isHidden || !cpuLabel.isHidden || !memoryLabel.isHidden
        setRightAccessories(hidden: !anyAccessoryVisible)
    }

    /// 控制右侧装饰 Stack 和名称约束（用 isHidden 触发 Stack 自动折叠）
    private func setRightAccessories(hidden: Bool) {
        rightAccessoryStack.isHidden = hidden
    }

    private func applySelectionStyle(isSelected: Bool, isReminder: Bool) {
        if isSelected {
            backgroundView.layer?.backgroundColor =
                NSColor.controlAccentColor.withAlphaComponent(0.85).cgColor
            nameLabel.textColor = .white
            pathLabel.textColor = .white.withAlphaComponent(0.8)
            arrowIndicator.contentTintColor = .white.withAlphaComponent(0.8)
            linkIndicator.contentTintColor = .white.withAlphaComponent(0.9)
            portLabel.textColor = isReminder
                ? .white.withAlphaComponent(0.8) : .white.withAlphaComponent(0.9)
            cpuIcon.contentTintColor = .white.withAlphaComponent(0.7)
            cpuLabel.textColor = .white.withAlphaComponent(0.8)
            memoryIcon.contentTintColor = .white.withAlphaComponent(0.7)
            memoryLabel.textColor = .white.withAlphaComponent(0.8)
            aliasLabel.textColor = .white.withAlphaComponent(0.9)
            aliasBadgeView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.2).cgColor
        } else {
            backgroundView.layer?.backgroundColor = NSColor.clear.cgColor
            nameLabel.textColor = .labelColor
            pathLabel.textColor = .secondaryLabelColor
            arrowIndicator.contentTintColor = .secondaryLabelColor
            linkIndicator.contentTintColor = .systemBlue
            portLabel.textColor = .secondaryLabelColor
            cpuIcon.contentTintColor = .tertiaryLabelColor
            cpuLabel.textColor = .secondaryLabelColor
            memoryIcon.contentTintColor = .tertiaryLabelColor
            memoryLabel.textColor = .secondaryLabelColor
            aliasLabel.textColor = .secondaryLabelColor
            aliasBadgeView.layer?.backgroundColor =
                NSColor.systemGray.withAlphaComponent(0.25).cgColor
        }
    }

    private func configureSectionHeader(with item: SearchResult) {
        iconView.isHidden = true
        aliasBadgeView.isHidden = true
        aliasLabel.stringValue = ""
        pathLabel.isHidden = true
        setRightAccessories(hidden: true)
        backgroundView.layer?.backgroundColor = NSColor.clear.cgColor

        nameLabel.stringValue = item.name
        nameLabel.font = .systemFont(ofSize: 11, weight: .medium)
        nameLabel.textColor = .secondaryLabelColor
    }
}
