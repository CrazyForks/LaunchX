import Foundation

/// 轻量 TOML 解析/编辑器
/// 仅支持 LaunchX 需要操作的子集：顶层键值对、[section]、[nested.section]
/// 保留非管理段的内容和注释
final class TomlDocument {
    /// 原始行数据，用于语法保留编辑
    private var lines: [TomlLine]

    init() {
        lines = []
    }

    init(content: String) {
        lines = TomlParser.parse(content)
    }

    // MARK: - 读取

    /// 获取顶层字符串值
    func getString(_ key: String) -> String? {
        for line in lines {
            if case .keyValue(let k, let v) = line.kind, k == key {
                return v.unquotedValue
            }
        }
        return nil
    }

    /// 获取指定 section 下的字符串值
    func getString(_ key: String, in section: String) -> String? {
        var inSection = false
        for line in lines {
            if case .section(let name) = line.kind, name == section {
                inSection = true
                continue
            }
            if case .section = line.kind { inSection = false; continue }
            if inSection, case .keyValue(let k, let v) = line.kind, k == key {
                return v.unquotedValue
            }
        }
        return nil
    }

    /// 获取指定 section 下的所有键值对
    func getAllKeyValues(in section: String) -> [String: String] {
        var result: [String: String] = [:]
        var inSection = false
        for line in lines {
            if case .section(let name) = line.kind {
                inSection = (name == section)
                continue
            }
            if inSection, case .keyValue(let k, let v) = line.kind {
                result[k] = v.unquotedValue
            }
        }
        return result
    }

    /// 获取指定 section 下的所有键值对（类型化）
    /// 与 getAllKeyValues 不同，数组 / 内联表 / 布尔 / 数字会被解析为对应的 Swift 类型，
    /// 而不是一律当作字符串。支持跨多行的数组与内联表。
    func getAllTypedValues(in section: String) -> [String: Any] {
        let (_, values) = TomlValueParser.parseTable(sectionBodyText(in: section))
        return values
    }

    /// 提取指定 section 的原始表体文本（不含表头，多行用 \n 连接）
    private func sectionBodyText(in section: String) -> String {
        var inSection = false
        var body: [String] = []
        for line in lines {
            if case .section(let name) = line.kind {
                inSection = (name == section)
                continue
            }
            if inSection {
                body.append(line.raw)
            }
        }
        return body.joined(separator: "\n")
    }

    /// 获取匹配前缀的所有 section 名
    func sectionsWithPrefix(_ prefix: String) -> [String] {
        lines.compactMap { line in
            if case .section(let name) = line.kind, name.hasPrefix(prefix) {
                return name
            }
            return nil
        }
    }

    // MARK: - 写入

    /// 设置顶层字符串值
    func set(_ key: String, value: String) {
        let quoted = value.tomlQuoted
        for i in lines.indices {
            if case .keyValue(let k, _) = lines[i].kind, k == key {
                lines[i] = TomlLine(kind: .keyValue(key, quoted), raw: "\(key) = \(quoted)")
                return
            }
        }
        // 新增：找到第一个 section 前面插入
        let insertIndex = lines.firstIndex(where: { if case .section = $0.kind { return true } else { return false } }) ?? lines.endIndex
        let newLine = TomlLine(kind: .keyValue(key, quoted), raw: "\(key) = \(quoted)")
        lines.insert(newLine, at: insertIndex)
    }

    /// 设置指定 section 下的字符串值
    func set(_ key: String, value: String, in section: String) {
        let quoted = value.tomlQuoted
        var sectionIndex: Int?
        var nextSectionIndex: Int?

        for i in lines.indices {
            if case .section(let name) = lines[i].kind {
                if name == section { sectionIndex = i }
                else if sectionIndex != nil && nextSectionIndex == nil { nextSectionIndex = i }
            }
        }

        guard let si = sectionIndex else {
            // section 不存在，追加
            let sectionLine = TomlLine(kind: .section(section), raw: "[\(section)]")
            let kvLine = TomlLine(kind: .keyValue(key, quoted), raw: "\(key) = \(quoted)")
            let blankLine = TomlLine(kind: .blank, raw: "")
            lines.append(blankLine)
            lines.append(sectionLine)
            lines.append(kvLine)
            return
        }

        let endIndex = nextSectionIndex ?? lines.endIndex

        for i in (si + 1)..<endIndex {
            if case .keyValue(let k, _) = lines[i].kind, k == key {
                lines[i] = TomlLine(kind: .keyValue(key, quoted), raw: "\(key) = \(quoted)")
                return
            }
        }

        // key 不存在于 section 中，在 section 末尾插入
        let kvLine = TomlLine(kind: .keyValue(key, quoted), raw: "\(key) = \(quoted)")
        lines.insert(kvLine, at: endIndex)
    }

    /// 删除指定 section
    func removeSection(_ section: String) {
        var sectionRange: Range<Int>?
        var start: Int?

        for i in lines.indices {
            if case .section(let name) = lines[i].kind {
                if name == section { start = i }
                else if start != nil {
                    sectionRange = start!..<(i)
                    break
                }
            }
        }
        if let s = start, sectionRange == nil {
            sectionRange = s..<lines.endIndex
        }

        if let range = sectionRange {
            lines.removeSubrange(range)
        }
    }

    /// 删除指定 section 下的某个 key
    func removeKey(_ key: String, in section: String) {
        var inSection = false
        var removeIndices: [Int] = []

        for i in lines.indices {
            if case .section(let name) = lines[i].kind {
                inSection = (name == section)
                continue
            }
            if inSection, case .keyValue(let k, _) = lines[i].kind, k == key {
                removeIndices.append(i)
            }
        }

        for i in removeIndices.reversed() {
            lines.remove(at: i)
        }
    }

    /// 设置指定 section 下的键值对（批量），移除不在 newKeys 中的键
    func setKeyValues(_ newKeyValues: [String: String], in section: String) {
        // 先删除 section 中现有的键
        var inSection = false
        var existingKeys: [String] = []

        for line in lines {
            if case .section(let name) = line.kind {
                inSection = (name == section)
                continue
            }
            if inSection, case .keyValue(let k, _) = line.kind {
                existingKeys.append(k)
            }
        }

        for key in existingKeys where newKeyValues[key] == nil {
            removeKey(key, in: section)
        }

        for (key, value) in newKeyValues {
            set(key, value: value, in: section)
        }
    }

    /// 设置指定 section 下的原始 TOML 值（不自动加引号，用于数组、内联表等）
    func setRaw(_ key: String, value: String, in section: String? = nil) {
        if let section = section {
            var sectionIndex: Int?
            var nextSectionIndex: Int?

            for i in lines.indices {
                if case .section(let name) = lines[i].kind {
                    if name == section { sectionIndex = i }
                    else if sectionIndex != nil && nextSectionIndex == nil { nextSectionIndex = i }
                }
            }

            guard let si = sectionIndex else {
                let sectionLine = TomlLine(kind: .section(section), raw: "[\(section)]")
                let kvLine = TomlLine(kind: .keyValue(key, value), raw: "\(key) = \(value)")
                let blankLine = TomlLine(kind: .blank, raw: "")
                lines.append(blankLine)
                lines.append(sectionLine)
                lines.append(kvLine)
                return
            }

            let endIndex = nextSectionIndex ?? lines.endIndex

            for i in (si + 1)..<endIndex {
                if case .keyValue(let k, _) = lines[i].kind, k == key {
                    lines[i] = TomlLine(kind: .keyValue(key, value), raw: "\(key) = \(value)")
                    return
                }
            }

            let kvLine = TomlLine(kind: .keyValue(key, value), raw: "\(key) = \(value)")
            lines.insert(kvLine, at: endIndex)
        } else {
            // 顶层
            for i in lines.indices {
                if case .keyValue(let k, _) = lines[i].kind, k == key {
                    lines[i] = TomlLine(kind: .keyValue(key, value), raw: "\(key) = \(value)")
                    return
                }
            }
            let insertIndex = lines.firstIndex(where: { if case .section = $0.kind { return true } else { return false } }) ?? lines.endIndex
            let newLine = TomlLine(kind: .keyValue(key, value), raw: "\(key) = \(value)")
            lines.insert(newLine, at: insertIndex)
        }
    }

    /// 获取顶层原始值（不含引号处理）
    func getRaw(_ key: String) -> String? {
        for line in lines {
            if case .keyValue(let k, let v) = line.kind, k == key {
                return v
            }
        }
        return nil
    }

    /// 获取指定 section 下的原始值
    func getRaw(_ key: String, in section: String) -> String? {
        var inSection = false
        for line in lines {
            if case .section(let name) = line.kind, name == section {
                inSection = true
                continue
            }
            if case .section = line.kind { inSection = false; continue }
            if inSection, case .keyValue(let k, let v) = line.kind, k == key {
                return v
            }
        }
        return nil
    }

    /// 检查指定 section 是否存在
    func hasSection(_ section: String) -> Bool {
        lines.contains { if case .section(let name) = $0.kind, name == section { return true } else { return false } }
    }

    // MARK: - 输出

    /// 序列化为 TOML 字符串
    func serialize() -> String {
        lines.map { $0.raw }.joined(separator: "\n")
    }
}

// MARK: - 内部类型

private struct TomlLine {
    enum Kind {
        case blank
        case comment(String)
        case section(String)
        case keyValue(String, String)  // key, rawValue
    }

    let kind: Kind
    var raw: String
}

private enum TomlParser {
    static func parse(_ content: String) -> [TomlLine] {
        content.components(separatedBy: "\n").map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                return TomlLine(kind: .blank, raw: line)
            }

            if trimmed.hasPrefix("#") {
                return TomlLine(kind: .comment(trimmed), raw: line)
            }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let name = String(trimmed.dropFirst().dropLast())
                return TomlLine(kind: .section(name), raw: line)
            }

            if let eqRange = trimmed.range(of: "=", options: .literal) {
                let key = trimmed[..<eqRange.lowerBound].trimmingCharacters(in: .whitespaces)
                let value = trimmed[eqRange.upperBound...].trimmingCharacters(in: .whitespaces)
                return TomlLine(kind: .keyValue(key, value), raw: line)
            }

            return TomlLine(kind: .blank, raw: line)
        }
    }
}

// MARK: - String Helpers

extension String {
    var tomlQuoted: String {
        "\"\(replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    /// 去除 TOML 引号获取实际值
    var unquotedValue: String {
        let trimmed = trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            return String(trimmed.dropFirst().dropLast())
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")
        }
        return trimmed
    }
}

// MARK: - 类型化 TOML 值解析

/// 类型化 TOML 值解析入口
/// 支持 MCP 配置所需的子集：基础/字面字符串、布尔、整数、浮点、数组、内联表。
enum TomlValueParser {
    /// 解析单个 TOML 值（去除首尾空白）
    static func parse(_ raw: String) -> Any? {
        var scanner = TomlValueScanner(raw)
        return scanner.parseValue()
    }

    /// 解析 TOML 表体文本，返回 (表头名?, 类型化键值)
    /// 文本可包含一个可选的 [section] 表头；键值可跨多行（数组/内联表）。
    static func parseTable(_ text: String) -> (header: String?, values: [String: Any]) {
        var scanner = TomlValueScanner(text)
        scanner.skipTrivia()
        var header: String? = nil
        if scanner.peek() == "[" {
            let line = scanner.readUntilNewline()
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                header = String(trimmed.dropFirst().dropLast())
            }
        }
        let values = scanner.parseTableBody()
        return (header, values)
    }
}

/// 字符级 TOML 扫描器（仅文件内使用）
fileprivate struct TomlValueScanner {
    private let chars: [Character]
    private(set) var index: Int

    init(_ s: String) {
        self.chars = Array(s)
        self.index = 0
    }

    private var count: Int { chars.count }

    fileprivate func peek(_ offset: Int = 0) -> Character? {
        let i = index + offset
        return i < count ? chars[i] : nil
    }

    /// 跳过空格、制表符、换行、回车以及行内注释
    fileprivate mutating func skipTrivia() {
        while index < count {
            let c = chars[index]
            if c == " " || c == "\t" || c == "\n" || c == "\r" {
                index += 1
            } else if c == "#" {
                while index < count, chars[index] != "\n" { index += 1 }
            } else {
                break
            }
        }
    }

    /// 读取直到换行（不含换行），并推进索引
    fileprivate mutating func readUntilNewline() -> String {
        var line = ""
        while let c = peek(), c != "\n" {
            line.append(c)
            index += 1
        }
        return line
    }

    // MARK: - 值

    fileprivate mutating func parseValue() -> Any? {
        skipTrivia()
        guard let c = peek() else { return nil }
        switch c {
        case "\"": return parseBasicString()
        case "'":  return parseLiteralString()
        case "[":  return parseArray()
        case "{":  return parseInlineTable()
        default:   return parseBareValue()
        }
    }

    private mutating func parseBasicString() -> String? {
        // 当前位于开头的 "
        index += 1
        var result = ""
        while index < count {
            let c = chars[index]
            if c == "\\" {
                index += 1
                guard index < count else { return nil }
                let esc = chars[index]
                switch esc {
                case "\"": result.append("\"")
                case "\\": result.append("\\")
                case "n":  result.append("\n")
                case "t":  result.append("\t")
                case "r":  result.append("\r")
                case "b":  result.append("\u{08}")
                case "f":  result.append("\u{0C}")
                case "/":  result.append("/")
                case "u", "U":
                    let len = esc == "u" ? 4 : 8
                    index += 1
                    guard let scalar = consumeHex(length: len) else { return nil }
                    result.append(scalar)
                    continue
                default:
                    // 未知转义：按字面保留
                    result.append(esc)
                }
                index += 1
            } else if c == "\"" {
                index += 1
                return result
            } else {
                result.append(c)
                index += 1
            }
        }
        return nil  // 未闭合
    }

    private mutating func consumeHex(length: Int) -> String? {
        guard index + length <= count else { return nil }
        let hex = String(chars[index..<(index + length)])
        guard let code = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(code) else { return nil }
        index += length
        return String(scalar)
    }

    private mutating func parseLiteralString() -> String? {
        index += 1  // 开头的 '
        var result = ""
        while index < count {
            let c = chars[index]
            if c == "'" {
                index += 1
                return result
            }
            result.append(c)
            index += 1
        }
        return nil
    }

    private mutating func parseArray() -> [Any]? {
        index += 1  // [
        var arr: [Any] = []
        while true {
            skipTrivia()
            guard let c = peek() else { return nil }  // 未闭合
            if c == "]" {
                index += 1
                return arr
            }
            guard let v = parseValue() else { return nil }
            arr.append(v)
            skipTrivia()
            guard let c2 = peek() else { return nil }
            if c2 == "," {
                index += 1
                continue
            } else if c2 == "]" {
                index += 1
                return arr
            } else {
                return nil
            }
        }
    }

    private mutating func parseInlineTable() -> [String: Any]? {
        index += 1  // {
        var dict: [String: Any] = [:]
        while true {
            skipTrivia()
            guard let c = peek() else { return nil }
            if c == "}" {
                index += 1
                return dict
            }
            guard let key = parseKey() else { return nil }
            skipTrivia()
            guard peek() == "=" else { return nil }
            index += 1
            guard let v = parseValue() else { return nil }
            dict[key] = v
            skipTrivia()
            guard let c2 = peek() else { return nil }
            if c2 == "," {
                index += 1
                continue
            } else if c2 == "}" {
                index += 1
                return dict
            } else {
                return nil
            }
        }
    }

    private mutating func parseKey() -> String? {
        skipTrivia()
        guard let c = peek() else { return nil }
        if c == "\"" { return parseBasicString() }
        if c == "'" { return parseLiteralString() }
        // 裸键：A-Za-z0-9_-
        var key = ""
        while let cc = peek(), cc.isLetter || cc.isNumber || cc == "_" || cc == "-" {
            key.append(cc)
            index += 1
        }
        return key.isEmpty ? nil : key
    }

    private mutating func parseBareValue() -> Any? {
        let stopChars: Set<Character> = [",", "]", "}", "#"]
        var token = ""
        while let c = peek() {
            if c == " " || c == "\t" || c == "\n" || c == "\r" || stopChars.contains(c) { break }
            token.append(c)
            index += 1
        }
        if token == "true" { return true }
        if token == "false" { return false }
        // 整数/浮点（支持下划线数字分隔符）
        let cleaned = token.replacingOccurrences(of: "_", with: "")
        if Self.isIntegerLiteral(cleaned), let int = Int(cleaned) { return int }
        if let dbl = Double(cleaned) { return dbl }
        // 无法识别：当作字符串保留
        return token
    }

    private static func isIntegerLiteral(_ s: String) -> Bool {
        var t = s
        if t.hasPrefix("+") || t.hasPrefix("-") { t.removeFirst() }
        return !t.isEmpty && t.allSatisfy { $0.isNumber }
    }

    // MARK: - 表体

    /// 解析多行 key = value 键值表，value 可跨行（数组/内联表）
    fileprivate mutating func parseTableBody() -> [String: Any] {
        var result: [String: Any] = [:]
        while true {
            skipTrivia()
            if peek() == nil { break }
            guard let key = parseKey() else {
                // 无法识别为键，跳过本行
                _ = readUntilNewline()
                continue
            }
            // 等号前只允许空格/制表符
            while let c = peek(), c == " " || c == "\t" { index += 1 }
            guard peek() == "=" else {
                _ = readUntilNewline()
                continue
            }
            index += 1  // 消耗 =
            if let value = parseValue() {
                result[key] = value
            }
            // 跳过值之后的同行残留（注释等）
            _ = readUntilNewline()
        }
        return result
    }
}
