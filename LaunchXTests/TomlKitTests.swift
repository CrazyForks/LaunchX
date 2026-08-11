import XCTest
@testable import LaunchX

final class TomlKitTests: XCTestCase {

    // MARK: - 解析测试

    func testParseTopLevelKeyValue() {
        let doc = TomlDocument(content: "model = \"gpt-4\"\n")
        XCTAssertEqual(doc.getString("model"), "gpt-4")
    }

    func testParseSection() {
        let content = """
        model = "gpt-4"

        [model_providers.myapi]
        name = "MyAPI"
        base_url = "https://api.example.com/v1"
        """
        let doc = TomlDocument(content: content)
        XCTAssertEqual(doc.getString("base_url", in: "model_providers.myapi"), "https://api.example.com/v1")
        XCTAssertEqual(doc.getString("name", in: "model_providers.myapi"), "MyAPI")
    }

    func testParseNestedSection() {
        let content = """
        [mcp_servers.filesystem]
        command = "npx"
        args = "something"
        """
        let doc = TomlDocument(content: content)
        XCTAssertEqual(doc.getString("command", in: "mcp_servers.filesystem"), "npx")
    }

    func testParsePreservesComments() {
        let content = """
        # This is a comment
        model = "gpt-4"

        # Provider section
        [model_providers.test]
        base_url = "http://localhost"
        """
        let doc = TomlDocument(content: content)
        let output = doc.serialize()
        XCTAssertTrue(output.contains("# This is a comment"))
        XCTAssertTrue(output.contains("# Provider section"))
    }

    func testParseEmptyContent() {
        let doc = TomlDocument(content: "")
        XCTAssertEqual(doc.serialize(), "")
    }

    // MARK: - 写入测试

    func testSetTopLevelValue() {
        let content = "model = \"old\"\n"
        let doc = TomlDocument(content: content)
        doc.set("model", value: "new-model")
        XCTAssertTrue(doc.serialize().contains("model = \"new-model\""))
    }

    func testSetNewTopLevelValue() {
        let doc = TomlDocument(content: "")
        doc.set("model", value: "gpt-4")
        let output = doc.serialize()
        XCTAssertTrue(output.contains("model = \"gpt-4\""))
    }

    func testSetSectionValue() {
        let content = """
        [model_providers.test]
        base_url = "http://old.com"
        """
        let doc = TomlDocument(content: content)
        doc.set("base_url", value: "http://new.com/v1", in: "model_providers.test")
        let output = doc.serialize()
        XCTAssertTrue(output.contains("base_url = \"http://new.com/v1\""))
        XCTAssertFalse(output.contains("old.com"))
    }

    func testSetNewSection() {
        let doc = TomlDocument(content: "model = \"gpt-4\"\n")
        doc.set("base_url", value: "http://api.com", in: "model_providers.newapi")
        let output = doc.serialize()
        XCTAssertTrue(output.contains("[model_providers.newapi]"))
        XCTAssertTrue(output.contains("base_url = \"http://api.com\""))
    }

    // MARK: - 删除测试

    func testRemoveSection() {
        let content = """
        model = "gpt-4"

        [model_providers.old]
        name = "Old"
        """
        let doc = TomlDocument(content: content)
        doc.removeSection("model_providers.old")
        let output = doc.serialize()
        XCTAssertFalse(output.contains("[model_providers.old]"))
        XCTAssertFalse(output.contains("name = \"Old\""))
        XCTAssertTrue(output.contains("model = \"gpt-4\""))
    }

    func testRemoveKeyInSection() {
        let content = """
        [model_providers.test]
        name = "Test"
        base_url = "http://test.com"
        """
        let doc = TomlDocument(content: content)
        doc.removeKey("base_url", in: "model_providers.test")
        let output = doc.serialize()
        XCTAssertFalse(output.contains("base_url"))
        XCTAssertTrue(output.contains("name = \"Test\""))
    }

    // MARK: - 语法保留测试

    func testPreservesUnmanagedContent() {
        let content = """
        # User comment
        model = "gpt-4"
        custom_flag = true

        [user_section]
        foo = "bar"

        [model_providers.managed]
        base_url = "http://api.com"
        """
        let doc = TomlDocument(content: content)
        doc.set("base_url", value: "http://new-api.com", in: "model_providers.managed")
        let output = doc.serialize()
        XCTAssertTrue(output.contains("# User comment"))
        XCTAssertTrue(output.contains("custom_flag = true"))
        XCTAssertTrue(output.contains("[user_section]"))
        XCTAssertTrue(output.contains("foo = \"bar\""))
    }

    // MARK: - Section 查询测试

    func testSectionsWithPrefix() {
        let content = """
        [mcp_servers.server1]
        command = "a"
        [mcp_servers.server2]
        command = "b"
        [other_section]
        """
        let doc = TomlDocument(content: content)
        let sections = doc.sectionsWithPrefix("mcp_servers.")
        XCTAssertEqual(sections, ["mcp_servers.server1", "mcp_servers.server2"])
    }

    // MARK: - 特殊字符测试

    func testQuotedValueWithSpecialChars() {
        let content = """
        [mcp_servers.test]
        url = "https://api.example.com/path?key=val&foo=bar"
        """
        let doc = TomlDocument(content: content)
        XCTAssertEqual(doc.getString("url", in: "mcp_servers.test"), "https://api.example.com/path?key=val&foo=bar")
    }

    func testSetKeyValuesBatch() {
        let content = """
        [mcp_servers.test]
        old_key = "remove_me"
        keep = "yes"
        """
        let doc = TomlDocument(content: content)
        doc.setKeyValues(["keep": "yes", "new_key": "added"], in: "mcp_servers.test")
        let output = doc.serialize()
        XCTAssertTrue(output.contains("keep = \"yes\""))
        XCTAssertTrue(output.contains("new_key = \"added\""))
        XCTAssertFalse(output.contains("old_key"))
    }

    // MARK: - 类型化值解析测试

    func testParseBasicString() {
        XCTAssertEqual(TomlValueParser.parse("\"npx\"") as? String, "npx")
    }

    func testParseStringWithEscapes() {
        XCTAssertEqual(TomlValueParser.parse("\"he said \\\"hi\\\"\"") as? String, "he said \"hi\"")
    }

    func testParseLiteralString() {
        XCTAssertEqual(TomlValueParser.parse("'C:\\\\path'") as? String, "C:\\\\path")
    }

    func testParseBoolean() {
        XCTAssertEqual(TomlValueParser.parse("true") as? Bool, true)
        XCTAssertEqual(TomlValueParser.parse("false") as? Bool, false)
    }

    func testParseInteger() {
        XCTAssertEqual(TomlValueParser.parse("30") as? Int, 30)
        XCTAssertEqual(TomlValueParser.parse("1_000") as? Int, 1000)
    }

    func testParseDouble() {
        XCTAssertEqual(TomlValueParser.parse("1.5") as? Double, 1.5)
    }

    func testParseArray() {
        let value = TomlValueParser.parse(#"["-y", "@upstash/context7-mcp"]"#)
        let arr = value as? [Any]
        XCTAssertEqual(arr?.count, 2)
        XCTAssertEqual(arr?[0] as? String, "-y")
        XCTAssertEqual(arr?[1] as? String, "@upstash/context7-mcp")
    }

    func testParseEmptyArray() {
        let value = TomlValueParser.parse("[]")
        XCTAssertEqual((value as? [Any])?.count, 0)
    }

    func testParseMultilineArray() {
        let body = """
        args = [
          "-y",
          "@modelcontextprotocol/server-filesystem",
        ]
        """
        let (_, values) = TomlValueParser.parseTable(body)
        let arr = values["args"] as? [Any]
        XCTAssertEqual(arr?.count, 2)
        XCTAssertEqual(arr?[0] as? String, "-y")
        XCTAssertEqual(arr?[1] as? String, "@modelcontextprotocol/server-filesystem")
    }

    func testParseInlineTable() {
        let value = TomlValueParser.parse(#"{ API_KEY = "secret", PORT = "8080" }"#)
        let dict = value as? [String: Any]
        XCTAssertEqual(dict?["API_KEY"] as? String, "secret")
        XCTAssertEqual(dict?["PORT"] as? String, "8080")
    }

    // MARK: - 类型化 section 读取测试

    func testGetAllTypedValuesPreservesArray() {
        let content = """
        [mcp_servers.context7]
        command = "npx"
        args = ["-y", "@upstash/context7-mcp"]
        startup_timeout_sec = 30
        enabled = true
        """
        let doc = TomlDocument(content: content)
        let values = doc.getAllTypedValues(in: "mcp_servers.context7")

        XCTAssertEqual(values["command"] as? String, "npx")
        XCTAssertEqual(values["startup_timeout_sec"] as? Int, 30)
        XCTAssertEqual(values["enabled"] as? Bool, true)

        // 数组必须保留为数组，而不是退化成字符串
        let args = values["args"] as? [Any]
        XCTAssertEqual(args?.count, 2)
        XCTAssertEqual(args?[0] as? String, "-y")
        XCTAssertEqual(args?[1] as? String, "@upstash/context7-mcp")
        XCTAssertNil(values["args"] as? String)
    }

    func testParseTableExtractsHeaderName() {
        let text = """
        [mcp_servers.context7]
        command = "npx"
        args = ["-y", "@upstash/context7-mcp"]
        """
        let (header, values) = TomlValueParser.parseTable(text)
        XCTAssertEqual(header, "mcp_servers.context7")
        XCTAssertEqual(values["command"] as? String, "npx")
        XCTAssertEqual((values["args"] as? [Any])?.count, 2)
    }

    func testParseTableBodyWithoutHeader() {
        let text = """
        command = "node"
        args = ["server.js"]
        """
        let (header, values) = TomlValueParser.parseTable(text)
        XCTAssertNil(header)
        XCTAssertEqual(values["command"] as? String, "node")
    }
}
