import Foundation
import UIKit

// MARK: - 基本样式类型
public protocol MarkupStyleType {
    /// 用於匹配輸入文本的正則表達式模式
    var patterns: String { get }
    var name: String { get }
    /// 用於生成輸出文本的標準格式
    var standardOpeningTag: String { get }
    var standardClosingTag: String { get }
    func createAttributes() -> [NSAttributedString.Key: Any]
}

// MARK: - 粗体样式
struct BoldStyle: MarkupStyleType {
    var patterns: String { return "(\\*{2,})([^\\*]+)\\1" }
    var name: String { return "bold" }
    var standardOpeningTag: String { return "**" }
    var standardClosingTag: String { return "**" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        return [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
    }
}

// MARK: - 斜体样式
struct ItalicStyle: MarkupStyleType {
    var patterns: String { return "_([^_]|_(?!_))*?_(?!_)" }
    var name: String { return "italic" }
    var standardOpeningTag: String { return "_" }
    var standardClosingTag: String { return "_" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        return [.font: UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)]
    }
}

// MARK: - 删除线样式
struct StrikethroughStyle: MarkupStyleType {
    var patterns: String { return "~~([^~]+)~~" }
    var name: String { return "strikethrough" }
    var standardOpeningTag: String { return "~~" }
    var standardClosingTag: String { return "~~" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        return [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
    }
}

// MARK: - 链接样式
struct LinkStyle: MarkupStyleType {
    let url: String
    
    var patterns: String { return "\\[([^\\]]+)\\]\\(([^\\)]+)\\)" }
    var name: String { return "link" }
    var standardOpeningTag: String { return "[" }
    var standardClosingTag: String { return "](\(url))" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        return [
            .link: url,
            .foregroundColor: UIColor.systemBlue
        ]
    }
}

// MARK: - 引用样式
struct QuoteStyle: MarkupStyleType {
    let level: Int
    
    init(level: Int = 0) {
        self.level = level
    }
    
    var patterns: String { return "(^|\\n)(>+\\s*[^\\n]*(?:\\n>+\\s*[^\\n]*)*)" }
    var name: String { return "quote" }
    var standardOpeningTag: String { return String(repeating: "> ", count: level + 1) }
    var standardClosingTag: String { return "\n" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        let baseIndent: CGFloat = 20.0
        let levelIndent = CGFloat(level + 1) * baseIndent
        
        paragraphStyle.headIndent = levelIndent
        paragraphStyle.firstLineHeadIndent = levelIndent
        
        return [
            .backgroundColor: UIColor.systemGray6.withAlphaComponent(CGFloat(level + 1) * 0.2),
            .paragraphStyle: paragraphStyle
        ]
    }
}

// MARK: - 行内代码样式
struct CodeStyle: MarkupStyleType {
    var patterns: String { return "(?<!`)`(?!`)([^`]|(?<!`)`(?!`))+?(?<!`)`(?!`)" }
    var name: String { return "code" }
    var standardOpeningTag: String { return "`" }
    var standardClosingTag: String { return "`" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular),
            .backgroundColor: UIColor.systemGray6
        ]
    }
}

// MARK: - 代码块样式
struct CodeBlockStyle: MarkupStyleType {
    let language: String?
    
    var patterns: String { return "```([^\\n]*?)\\n([\\s\\S]*?)```" }
    var name: String { return "codeblock" }
    
    var standardOpeningTag: String {
        return "```\(language ?? "")\n"
    }
    
    var standardClosingTag: String { return "\n```" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular),
            .backgroundColor: UIColor.systemGray6
        ]
    }
}

// MARK: - 项目符号列表样式
struct BulletListStyle: MarkupStyleType {
    let level: Int
    
    var patterns: String { return "(?:^([ ]*)[-*]\\s+(.+)$\\n?)+" }
    var name: String { return "bulletlist" }
    
    var standardOpeningTag: String {
        return String(repeating: "  ", count: level) + "- "
    }
    
    var standardClosingTag: String { return "" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        let indent = CGFloat(level * 20)
        paragraphStyle.headIndent = indent + 20
        paragraphStyle.firstLineHeadIndent = indent
        paragraphStyle.paragraphSpacing = 4
        return [.paragraphStyle: paragraphStyle]
    }
}

// MARK: - 项目符号列表项样式
struct BulletListItemStyle: MarkupStyleType {
    let level: Int
    
    var patterns: String { return "^([ ]*)[-*]\\s+(.+)$" }
    var name: String { return "bulletlistitem" }
    
    var standardOpeningTag: String {
        return String(repeating: "  ", count: level) + "- "
    }
    
    var standardClosingTag: String { return "" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
        paragraphStyle.defaultTabInterval = 20
        paragraphStyle.headIndent = CGFloat(level * 20) + 20
        paragraphStyle.firstLineHeadIndent = CGFloat(level * 20)
        paragraphStyle.paragraphSpacing = 4
        return [.paragraphStyle: paragraphStyle]
    }
}

// MARK: - 数字列表样式
struct NumberListStyle: MarkupStyleType {
    let start: Int?
    let level: Int
    
    var patterns: String { return "(?:^([ ]*)\\d+\\.\\s+(.+)$\\n?)+" }
    var name: String { return "numberlist" }
    
    var standardOpeningTag: String {
        return String(repeating: "  ", count: level) + "\(start ?? 1). "
    }
    
    var standardClosingTag: String { return "" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
        paragraphStyle.defaultTabInterval = 20
        paragraphStyle.headIndent = CGFloat(level * 20) + 20
        paragraphStyle.firstLineHeadIndent = CGFloat(level * 20)
        paragraphStyle.paragraphSpacing = 4
        return [.paragraphStyle: paragraphStyle]
    }
}

// MARK: - 数字列表项样式
struct NumberListItemStyle: MarkupStyleType {
    let number: Int?
    let level: Int
    
    var patterns: String { return "^([ ]*)([0-9]+)\\.\\s+(.+)$" }
    var name: String { return "numberlistitem" }
    
    var standardOpeningTag: String {
        return String(repeating: "  ", count: level) + "\(number ?? 1). "
    }
    
    var standardClosingTag: String { return "" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
        paragraphStyle.defaultTabInterval = 20
        paragraphStyle.headIndent = CGFloat(level * 20) + 20
        paragraphStyle.firstLineHeadIndent = CGFloat(level * 20)
        paragraphStyle.paragraphSpacing = 4
        return [.paragraphStyle: paragraphStyle]
    }
}

// MARK: - 提及样式
struct MentionStyle: MarkupStyleType {
    let userId: String
    let displayName: String
    
    var patterns: String { return "@\\[([^\\]]+)\\]\\(([^\\)]+)\\)" }
    var name: String { return "mention" }
    
    var standardOpeningTag: String {
        return "@[\(displayName)]("
    }
    
    var standardClosingTag: String { return "\(userId))" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .semibold)
        ]
        
        // 添加自定义属性来标识 mention
        attributes[.mentionUserId] = userId
        
        return attributes
    }
}

// MARK: - 字体样式
struct FontStyle: MarkupStyleType {
    let attributes: [StyleAttribute]
    
    var patterns: String {
        return "\\{\\{font\\s+([^\\}]+)\\}\\}([^\\{]+)\\{\\{/font\\}\\}"
    }
    
    var name: String { return "font" }
    
    var standardOpeningTag: String {
        let attributesString = attributes.map { "\($0.key)=\"\($0.value)\"" }.joined(separator: " ")
        return "{{font \(attributesString)}}"
    }
    
    var standardClosingTag: String { return "{{/font}}" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        return MarkupStyle.convertToNSAttributes(attributes)
    }
}

// MARK: - 自定义样式
struct CustomStyle: MarkupStyleType {
    let name: String
    let attributes: [StyleAttribute]
    
    var patterns: String {
        return "\\{\\{\(name)\\s*([^\\}]*)\\}\\}([^\\{]+)\\{\\{/\(name)\\}\\}"
    }
    
    var standardOpeningTag: String {
        let attributesString = attributes.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        return "{{\(name) \(attributesString)}}"
    }
    
    var standardClosingTag: String { return "{{/\(name)}}" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        return MarkupStyle.convertToNSAttributes(attributes)
    }
}

// MARK: - 分隔线样式
struct HorizontalRuleStyle: MarkupStyleType {
    var patterns: String { return "^\\s*(\\*{3,}|\\-{3,}|_{3,})\\s*$" }
    var name: String { return "horizontalrule" }
    var standardOpeningTag: String { return "***" }
    var standardClosingTag: String { return "" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        return [
            .paragraphStyle: paragraphStyle,
            .backgroundColor: UIColor.systemGray5
        ]
    }
}

// MARK: - 標題樣式
struct HeadingStyle: MarkupStyleType {
    let level: Int
    
    init(level: Int) {
        self.level = max(1, min(6, level))  // 確保 level 在 1-6 之間
    }
    
    var patterns: String {
        let prefix = String(repeating: "#", count: level)
        return "^\(prefix)\\s+([^\\n]+)$"
    }
    
    var name: String { return "h\(level)" }
    var standardOpeningTag: String { return String(repeating: "#", count: level) + " " }
    var standardClosingTag: String { return "\n" }
    
    func createAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 10
        paragraphStyle.paragraphSpacingBefore = 10
        
        // 根據標題級別設置字體大小
        let sizes: [CGFloat] = [28, 24, 20, 18, 16, 14]
        let fontSize = sizes[level - 1]
        
        return [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label
        ]
    }
} 
