import Foundation

/// 轻量 TOML 解析/生成器，支持 Codex CLI 的 config.toml 格式
/// 支持: flat key-value, [table], [[array_of_tables]], inline table, 基本类型
/// 使用 class 实现引用语义，支持嵌套表的就地修改
final class CodexTomlParser {

    // MARK: - TOML Value 类型 (class 实现引用语义)

    class TomlValue: CustomStringConvertible {
        var description: String { "TomlValue" }

        func clone() -> TomlValue { TomlValue() }
    }

    final class TomlString: TomlValue {
        let value: String
        init(_ value: String) { self.value = value }
        override var description: String { "\"\(value)\"" }
        override func clone() -> TomlValue { TomlString(value) }
    }

    final class TomlBool: TomlValue {
        let value: Bool
        init(_ value: Bool) { self.value = value }
        override var description: String { value ? "true" : "false" }
        override func clone() -> TomlValue { TomlBool(value) }
    }

    final class TomlInt: TomlValue {
        let value: Int
        init(_ value: Int) { self.value = value }
        override var description: String { "\(value)" }
        override func clone() -> TomlValue { TomlInt(value) }
    }

    final class TomlDouble: TomlValue {
        let value: Double
        init(_ value: Double) { self.value = value }
        override var description: String { "\(value)" }
        override func clone() -> TomlValue { TomlDouble(value) }
    }

    final class TomlArray: TomlValue {
        var items: [TomlValue]
        init(_ items: [TomlValue] = []) { self.items = items }
        override var description: String { "[\(items.map { $0.description }.joined(separator: ", "))]" }
        override func clone() -> TomlValue { TomlArray(items.map { $0.clone() }) }
    }

    final class TomlTable: TomlValue {
        var entries: [String: TomlValue]

        init(_ entries: [String: TomlValue] = [:]) {
            self.entries = entries
        }

        override var description: String {
            let pairs = entries.sorted(by: { $0.key < $1.key }).map { "\($0.key) = \($0.value.description)" }
            return "{ \(pairs.joined(separator: ", ")) }"
        }

        override func clone() -> TomlValue {
            TomlTable(entries.mapValues { $0.clone() })
        }

        subscript(_ key: String) -> TomlValue? {
            get { entries[key] }
            set { entries[key] = newValue }
        }
    }

    final class TomlArrayTable: TomlValue {
        var rows: [TomlTable]

        init(_ rows: [TomlTable] = []) { self.rows = rows }

        override var description: String {
            rows.map { row in
                let pairs = row.entries.sorted(by: { $0.key < $1.key }).map { "\($0.key) = \($0.value.description)" }
                return "[[\(pairs.joined(separator: ", "))]]"
            }.joined(separator: "\n")
        }

        override func clone() -> TomlValue {
            TomlArrayTable(rows.map { $0.clone() as! TomlTable })
        }

        /// 添加新行并返回
        @discardableResult
        func addRow() -> TomlTable {
            let row = TomlTable()
            rows.append(row)
            return row
        }

        /// 获取最后一行（可变）
        var lastRow: TomlTable? {
            rows.last
        }
    }

    // MARK: - 解析

    /// 解析 TOML 字符串为顶层表
    func parse(_ toml: String) -> TomlTable {
        let root = TomlTable()
        var currentTarget: TomlTable = root
        var currentArrayTable: TomlArrayTable?
        var currentArrayTableKey: String?

        let lines = toml.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 跳过空行和注释
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // 数组表头 [[xxx.yyy]]
            if trimmed.hasPrefix("[[") && trimmed.hasSuffix("]]") {
                let header = String(trimmed.dropFirst(2).dropLast(2))
                let path = header.split(separator: ".").map(String.init)

                let arrayTable = ensureArrayTable(root, path: path)
                arrayTable.addRow()
                currentTarget = arrayTable.lastRow!
                currentArrayTable = arrayTable
                currentArrayTableKey = path.first
                continue
            }

            // 表头 [xxx.yyy]
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") && !trimmed.hasPrefix("[[") {
                let header = String(trimmed.dropFirst().dropLast())
                let path = header.split(separator: ".").map(String.init)
                currentTarget = ensureTable(root, path: path)
                currentArrayTable = nil
                currentArrayTableKey = nil
                continue
            }

            // key = value
            if let eqIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<eqIndex]).trimmingCharacters(in: .whitespaces)
                let valueStr = String(trimmed[trimmed.index(after: eqIndex)...]).trimmingCharacters(in: .whitespaces)
                let value = parseValue(valueStr)
                currentTarget[key] = value
            }
        }

        return root
    }

    // MARK: - 序列化

    /// 将 TomlTable 序列化为 TOML 字符串
    func serialize(_ table: TomlTable) -> String {
        var lines: [String] = []

        // 先输出 flat key-value
        for (key, value) in table.entries.sorted(by: { $0.key < $1.key }) {
            switch value {
            case is TomlTable, is TomlArrayTable:
                break
            default:
                lines.append("\(key) = \(serializeValue(value))")
            }
        }

        // 输出 [table] 和 [[array_table]] 段
        for (key, value) in table.entries.sorted(by: { $0.key < $1.key }) {
            if let subTable = value as? TomlTable {
                if !lines.isEmpty && !lines.last!.isEmpty {
                    lines.append("")
                }
                lines.append("[\(key)]")
                lines.append(contentsOf: serializeTableEntries(subTable))
            } else if let arrayTable = value as? TomlArrayTable {
                for row in arrayTable.rows {
                    if !lines.isEmpty && !lines.last!.isEmpty {
                        lines.append("")
                    }
                    lines.append("[[\(key)]]")
                    lines.append(contentsOf: serializeTableEntries(row))
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Value 解析

    private func parseValue(_ str: String) -> TomlValue {
        let s = str.trimmingCharacters(in: .whitespaces)

        if s == "true" { return TomlBool(true) }
        if s == "false" { return TomlBool(false) }

        // 字符串
        if s.hasPrefix("\"") && s.hasSuffix("\"") {
            return TomlString(String(s.dropFirst().dropLast()))
        }
        if s.hasPrefix("'") && s.hasSuffix("'") {
            return TomlString(String(s.dropFirst().dropLast()))
        }

        // 内联表
        if s.hasPrefix("{") && s.hasSuffix("}") {
            return parseInlineTable(s)
        }

        // 数组
        if s.hasPrefix("[") && s.hasSuffix("]") {
            return parseArray(s)
        }

        // 数字
        if let intVal = Int(s) { return TomlInt(intVal) }
        if let doubleVal = Double(s) { return TomlDouble(doubleVal) }

        return TomlString(s)
    }

    private func parseInlineTable(_ s: String) -> TomlTable {
        let content = String(s.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        let table = TomlTable()

        guard !content.isEmpty else { return table }

        let pairs = splitByComma(content)
        for pair in pairs {
            let trimmed = pair.trimmingCharacters(in: .whitespaces)
            if let eqIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<eqIndex]).trimmingCharacters(in: .whitespaces)
                let val = String(trimmed[trimmed.index(after: eqIndex)...]).trimmingCharacters(in: .whitespaces)
                table[key] = parseValue(val)
            }
        }

        return table
    }

    private func parseArray(_ s: String) -> TomlArray {
        let content = String(s.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        let array = TomlArray()

        guard !content.isEmpty else { return array }

        let elements = splitByComma(content)
        for element in elements {
            let trimmed = element.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                array.items.append(parseValue(trimmed))
            }
        }

        return array
    }

    private func splitByComma(_ s: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inString = false
        var stringChar: Character = "\""
        var depth = 0

        for char in s {
            if inString {
                current.append(char)
                if char == stringChar { inString = false }
                continue
            }

            if char == "\"" || char == "'" {
                inString = true
                stringChar = char
                current.append(char)
                continue
            }

            if char == "{" || char == "[" {
                depth += 1
                current.append(char)
                continue
            }

            if char == "}" || char == "]" {
                depth -= 1
                current.append(char)
                continue
            }

            if char == "," && depth == 0 {
                result.append(current)
                current = ""
                continue
            }

            current.append(char)
        }

        if !current.isEmpty { result.append(current) }
        return result
    }

    // MARK: - 表/数组表路径操作

    /// 确保路径上的表存在，返回最终表
    private func ensureTable(_ root: TomlTable, path: [String]) -> TomlTable {
        guard !path.isEmpty else { return root }
        var current: TomlTable = root

        for key in path {
            if let existing = current[key] as? TomlTable {
                current = existing
            } else {
                let newTable = TomlTable()
                current[key] = newTable
                current = newTable
            }
        }

        return current
    }

    /// 确保路径上的数组表存在，返回数组表对象
    private func ensureArrayTable(_ root: TomlTable, path: [String]) -> TomlArrayTable {
        guard let firstKey = path.first else { return TomlArrayTable() }

        // 简化：只支持顶层 key 的数组表（Codex 的 [mcp_servers.xxx] 和 [model_providers.xxx] 是顶层段）
        if let existing = root[firstKey] as? TomlArrayTable {
            return existing
        }

        let arrayTable = TomlArrayTable()
        root[firstKey] = arrayTable
        return arrayTable
    }

    // MARK: - 序列化辅助

    private func serializeValue(_ value: TomlValue) -> String {
        switch value {
        case let s as TomlString:
            return "\"\(escapeString(s.value))\""
        case let b as TomlBool:
            return b.value ? "true" : "false"
        case let i as TomlInt:
            return "\(i.value)"
        case let d as TomlDouble:
            let s = "\(d.value)"
            return s.contains(".") ? s : s + ".0"
        case let arr as TomlArray:
            let items = arr.items.map { serializeValue($0) }
            return "[\(items.joined(separator: ", "))]"
        case let table as TomlTable:
            let pairs = table.entries.sorted(by: { $0.key < $1.key }).map { "\($0.key) = \(serializeValue($0.value))" }
            return "{ \(pairs.joined(separator: ", ")) }"
        default:
            return ""
        }
    }

    private func serializeTableEntries(_ table: TomlTable) -> [String] {
        var lines: [String] = []

        for (key, value) in table.entries.sorted(by: { $0.key < $1.key }) {
            switch value {
            case is TomlTable:
                break // 嵌套表在序列化顶层处理
            case is TomlArrayTable:
                break
            default:
                lines.append("\(key) = \(serializeValue(value))")
            }
        }

        return lines
    }

    private func escapeString(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}

// MARK: - 便捷类型查询

extension CodexTomlParser.TomlValue {
    var stringValue: String? { (self as? CodexTomlParser.TomlString)?.value }
    var boolValue: Bool? { (self as? CodexTomlParser.TomlBool)?.value }
    var intValue: Int? { (self as? CodexTomlParser.TomlInt)?.value }
    var doubleValue: Double? { (self as? CodexTomlParser.TomlDouble)?.value }

    var arrayValue: [CodexTomlParser.TomlValue]? { (self as? CodexTomlParser.TomlArray)?.items }
    var tableValue: CodexTomlParser.TomlTable? { self as? CodexTomlParser.TomlTable }
    var arrayTableValue: CodexTomlParser.TomlArrayTable? { self as? CodexTomlParser.TomlArrayTable }
}
