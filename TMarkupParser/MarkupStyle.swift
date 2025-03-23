import Foundation
import UIKit

extension NSAttributedString.Key {
    static let mentionUserId = NSAttributedString.Key("mentionUserId")
}

// MARK: - Style Attribute
struct StyleAttribute: Equatable {
    let key: String
    let value: String
}

//// MARK: - Style Protocol
//protocol MarkupStyleType {
//    /// 用於匹配輸入文本的正則表達式模式
//    var patterns: String { get }
//    var name: String { get }
//    /// 用於生成輸出文本的標準格式
//    var standardOpeningTag: String { get }
//    var standardClosingTag: String { get }
//    func createAttributes() -> [NSAttributedString.Key: Any]
//}
//
//// MARK: - Fixed Styles
//enum FixedStyle: MarkupStyleType {
//    case bold
//    case italic
//    case strikethrough
//    case link(url: String)
//    case quote
//    case code
//    case codeBlock(language: String?)
//    case bulletList(level: Int)
//    case numberList(start: Int?, level: Int)
//    case bulletListItem(level: Int)
//    case numberListItem(number: Int?, level: Int)
//    case mention(userId: String, displayName: String)
//    
//    var patterns: String {
//        switch self {
//        case .bold:
//            return "(\\*{2,})([^\\*]+)\\1"
//        case .italic:
//            return "_([^_]|_(?!_))*?_(?!_)"
//        case .strikethrough:
//            return "~~([^~]+)~~"
//        case .link:
//            return "\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
//        case .quote:
//            return "(^|\\n)>\\s*([^\\n]*(\\n>\\s*[^\\n]*)*)"
//        case .code:
//            return "(?<!`)`(?!`)([^`]|(?<!`)`(?!`))+?(?<!`)`(?!`)"
//        case .codeBlock:
//            return "```([^\\n]*?)\\n([\\s\\S]*?)```"
//        case .bulletList:
//            return "(?:^([ ]*)[-*]\\s+(.+)$\\n?)+"
//        case .numberList:
//            return "(?:^([ ]*)\\d+\\.\\s+(.+)$\\n?)+"
//        case .bulletListItem:
//            return "^([ ]*)[-*]\\s+(.+)$"
//        case .numberListItem:
//            return "^([ ]*)([0-9]+)\\.\\s+(.+)$"
//        case .mention:
//            return "@\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
//        }
//    }
//    
//    var name: String {
//        switch self {
//        case .bold: return "bold"
//        case .italic: return "italic"
//        case .strikethrough: return "strikethrough"
//        case .link: return "link"
//        case .quote: return "quote"
//        case .code: return "code"
//        case .codeBlock: return "codeblock"
//        case .bulletList: return "bulletlist"
//        case .numberList: return "numberlist"
//        case .bulletListItem: return "bulletlistitem"
//        case .numberListItem: return "numberlistitem"
//        case .mention: return "mention"
//        }
//    }
//    
//    var standardOpeningTag: String {
//        switch self {
//        case .bold: return "**"
//        case .italic: return "_"
//        case .strikethrough: return "~~"
//        case .link: return "["
//        case .quote: return "> "
//        case .code: return "`"
//        case .codeBlock(let language):
//            return "```\(language ?? "")\n"
//        case .bulletList(let level):
//            return String(repeating: "  ", count: level) + "- "
//        case .numberList(let start, let level):
//            return String(repeating: "  ", count: level) + "\(start ?? 1). "
//        case .bulletListItem(let level):
//            return String(repeating: "  ", count: level) + "- "
//        case .numberListItem(let number, let level):
//            return String(repeating: "  ", count: level) + "\(number ?? 1). "
//        case .mention(_, let displayName):
//            return "@[\(displayName)]("
//        }
//    }
//    
//    var standardClosingTag: String {
//        switch self {
//        case .bold: return "**"
//        case .italic: return "_"
//        case .strikethrough: return "~~"
//        case .link(let url): return "](\(url))"
//        case .quote: return "\n"
//        case .code: return "`"
//        case .codeBlock: return "\n```"
//        case .bulletList: return ""
//        case .numberList: return ""
//        case .bulletListItem: return ""
//        case .numberListItem: return ""
//        case .mention(let userId, _): return "\(userId))"
//        }
//    }
//    
//    func createAttributes() -> [NSAttributedString.Key: Any] {
//        var attributes: [NSAttributedString.Key: Any] = [:]
//        
//        switch self {
//        case .bold:
//            attributes[.font] = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
//        case .italic:
//            attributes[.font] = UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)
//        case .strikethrough:
//            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
//        case .link(let url):
//            attributes[.link] = url
//            attributes[.foregroundColor] = UIColor.systemBlue
//        case .quote:
//            attributes[.backgroundColor] = UIColor.systemGray6
//            attributes[.paragraphStyle] = {
//                let style = NSMutableParagraphStyle()
//                style.headIndent = 20
//                style.firstLineHeadIndent = 20
//                return style
//            }()
//        case .code, .codeBlock:
//            attributes[.font] = UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular)
//            attributes[.backgroundColor] = UIColor.systemGray6
//        case .bulletList(let level), .numberList(_, let level):
//            let paragraphStyle = NSMutableParagraphStyle()
//            let indent = CGFloat(level * 20)
//            paragraphStyle.headIndent = indent + 20
//            paragraphStyle.firstLineHeadIndent = indent
//            paragraphStyle.paragraphSpacing = 4
//            attributes[.paragraphStyle] = paragraphStyle
//        case .bulletListItem(let level):
//            let paragraphStyle = NSMutableParagraphStyle()
//            let indent = CGFloat(level * 20)
//            paragraphStyle.headIndent = indent + 20
//            paragraphStyle.firstLineHeadIndent = indent
//            paragraphStyle.paragraphSpacing = 4
//            attributes[.paragraphStyle] = paragraphStyle
//        case .numberListItem(_, let level):
//            let paragraphStyle = NSMutableParagraphStyle()
//            let indent = CGFloat(level * 20)
//            paragraphStyle.headIndent = indent + 20
//            paragraphStyle.firstLineHeadIndent = indent
//            paragraphStyle.paragraphSpacing = 4
//            attributes[.paragraphStyle] = paragraphStyle
//        case .mention(let userId, _):
//            attributes[.foregroundColor] = UIColor.systemBlue
//            attributes[.font] = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .semibold)
//            // 添加自定義屬性來標識 mention
//            attributes[.mentionUserId] = userId
//        }
//        
//        return attributes
//    }
//}
//
//// MARK: - Dynamic Styles
//struct FontStyle: MarkupStyleType {
//    let attributes: [StyleAttribute]
//    
//    var patterns: String {
//        return "\\{\\{font\\s+([^\\}]+)\\}\\}([^\\{]+)\\{\\{/font\\}\\}"
//    }
//    
//    var name: String { return "font" }
//    
//    var standardOpeningTag: String {
//        let attributesString = attributes.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
//        return "{{font \(attributesString)}}"
//    }
//    
//    var standardClosingTag: String { return "{{/font}}" }
//    
//    func createAttributes() -> [NSAttributedString.Key: Any] {
//        return MarkupStyle.convertToNSAttributes(attributes)
//    }
//}
//
//// MARK: - Custom Dynamic Style
//struct CustomStyle: MarkupStyleType {
//    let name: String
//    let attributes: [StyleAttribute]
//    
//    var patterns: String {
//        return "\\{\\{\(name)\\s*([^\\}]*)\\}\\}([^\\{]+)\\{\\{/\(name)\\}\\}"
//    }
//    
//    var standardOpeningTag: String {
//        let attributesString = attributes.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
//        return "{{\(name) \(attributesString)}}"
//    }
//    
//    var standardClosingTag: String { return "{{/\(name)}}" }
//    
//    func createAttributes() -> [NSAttributedString.Key: Any] {
//        return MarkupStyle.convertToNSAttributes(attributes)
//    }
//}

public class MarkupStyle {
    let style: MarkupStyleType
    
    public init(style: MarkupStyleType) {
        self.style = style
    }
    
    var patterns: String { return style.patterns }
    var name: String { return style.name }
    var standardOpeningTag: String { return style.standardOpeningTag }
    var standardClosingTag: String { return style.standardClosingTag }
    var nsAttributes: [NSAttributedString.Key: Any] { return style.createAttributes() }
    
    // MARK: - 預定義樣式
    static let bold = MarkupStyle(style: BoldStyle())
    static let italic = MarkupStyle(style: ItalicStyle())
    static let strikethrough = MarkupStyle(style: StrikethroughStyle())
    static func link(url: String) -> MarkupStyle {
        return MarkupStyle(style: LinkStyle(url: url))
    }
    static let quote = MarkupStyle(style: QuoteStyle())
    static let code = MarkupStyle(style: CodeStyle())
    static func codeBlock(language: String? = nil) -> MarkupStyle {
        return MarkupStyle(style: CodeBlockStyle(language: language))
    }
    static let horizontalRule = MarkupStyle(style: HorizontalRuleStyle())
    static func bulletList(level: Int) -> MarkupStyle {
        return MarkupStyle(style: BulletListStyle(level: level))
    }
    static func numberList(start: Int? = nil, level: Int) -> MarkupStyle {
        return MarkupStyle(style: NumberListStyle(start: start, level: level))
    }
    static func bulletListItem(level: Int) -> MarkupStyle {
        return MarkupStyle(style: BulletListItemStyle(level: level))
    }
    static func numberListItem(number: Int? = nil, level: Int) -> MarkupStyle {
        return MarkupStyle(style: NumberListItemStyle(number: number, level: level))
    }
    static func mention(userId: String, displayName: String) -> MarkupStyle {
        return MarkupStyle(style: MentionStyle(userId: userId, displayName: displayName))
    }
    static func font(attributes: [StyleAttribute]) -> MarkupStyle {
        return MarkupStyle(style: FontStyle(attributes: attributes))
    }
    static func custom(name: String, attributes: [StyleAttribute]) -> MarkupStyle {
        return MarkupStyle(style: CustomStyle(name: name, attributes: attributes))
    }
    
    // MARK: - Helper Methods
    static func convertToNSAttributes(_ attributes: [StyleAttribute]) -> [NSAttributedString.Key: Any] {
        var result: [NSAttributedString.Key: Any] = [:]
        
        for attribute in attributes {
            switch attribute.key {
            case "color":
                if let color = UIColor(hexString: attribute.value) {
                    result[.foregroundColor] = color
                }
            case "decoration":
                switch attribute.value {
                case "underline":
                    result[.underlineStyle] = NSUnderlineStyle.single.rawValue
                case "strikethrough":
                    result[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                default:
                    break
                }
            case "size":
                if let size = Float(attribute.value) {
                    result[.font] = UIFont.systemFont(ofSize: CGFloat(size))
                }
            case "font-weight":
                if let weight = Float(attribute.value) {
                    result[.font] = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: UIFont.Weight(rawValue: CGFloat(weight)))
                }
            default:
                break
            }
        }
        
        return result
    }
    
    // MARK: - Style Creation from Match
    static func from(match: NSTextCheckingResult, in text: String) -> MarkupStyle? {
        let fullMatch = (text as NSString).substring(with: match.range)
        
        // 檢查固定樣式
        if fullMatch.hasPrefix("*") {
            // 計算開頭和結尾的星號數量
            var startCount = 0
            var endCount = 0
            
            for char in fullMatch {
                if char == "*" {
                    startCount += 1
                } else {
                    break
                }
            }
            
            for char in fullMatch.reversed() {
                if char == "*" {
                    endCount += 1
                } else {
                    break
                }
            }
            
            // 如果開頭和結尾的星號數量相等且大於等於 2，則為粗體
            if startCount == endCount && startCount >= 2 {
                return MarkupStyle.bold
            } else if startCount == 1 && endCount == 1 {
                return MarkupStyle.italic
            }
        } else if fullMatch.hasPrefix("_") {
            return MarkupStyle.italic
        } else if fullMatch.hasPrefix("~~") {
            return MarkupStyle.strikethrough
        } else if fullMatch.hasPrefix("[") {
            let urlRange = match.range(at: 2)
            let url = (text as NSString).substring(with: urlRange)
            return MarkupStyle.link(url: url)
        } else if fullMatch.hasPrefix(">") {
            return MarkupStyle.quote
        } else if fullMatch.hasPrefix("`") {
            if fullMatch.hasPrefix("```") {
                let languageRange = match.range(at: 1)
                let language = (text as NSString).substring(with: languageRange)
                return MarkupStyle.codeBlock(language: language.isEmpty ? nil : language)
            }
            return MarkupStyle.code
        }
        
        // 檢查動態樣式
        if fullMatch.hasPrefix("{{") {
            let content = (text as NSString).substring(with: match.range(at: 1))
            let components = content.components(separatedBy: .whitespaces)
            guard let name = components.first else { return nil }
            
            var attributes: [StyleAttribute] = []
            for component in components.dropFirst() {
                let keyValue = component.components(separatedBy: "=")
                guard keyValue.count == 2 else { continue }
                attributes.append(StyleAttribute(key: keyValue[0], value: keyValue[1]))
            }
            
            switch name {
            case "font":
                return MarkupStyle.font(attributes: attributes)
            default:
                return MarkupStyle.custom(name: name, attributes: attributes)
            }
        }
        
        return nil
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init?(hexString: String) {
        var hex = hexString
        if hex.hasPrefix("#") {
            hex = String(hex.dropFirst())
        }
        
        guard hex.count == 6 else { return nil }
        
        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
} 
