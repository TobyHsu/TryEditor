import Foundation
import UIKit

public protocol MarkupVisitor {
    associatedtype Result
    
    func visit(text: TextNode) -> Result
    func visit(style: StyleNode) -> Result
    func visit(root: RootNode) -> Result
}

// MARK: - NSAttributedString Visitor
class AttributedStringVisitor: MarkupVisitor {
    typealias Result = NSAttributedString
    
    private var baseFont: UIFont
    private var defaultBulletSymbol: String
    
    init(baseFont: UIFont = .systemFont(ofSize: UIFont.systemFontSize),
         defaultBulletSymbol: String = "•") {
        self.baseFont = baseFont
        self.defaultBulletSymbol = defaultBulletSymbol
    }
    
    func visit(text: TextNode) -> NSAttributedString {
        return NSAttributedString(string: text.text)
    }
    
    func visit(style: StyleNode) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // 處理列表樣式
        switch style.style.style {
        case is BulletListStyle:
            // 整個列表容器不添加前缀，由列表項處理
            break
            
        case is NumberListStyle:
            // 整個列表容器不添加前缀，由列表項處理
            break
            
        case let bulletItem as BulletListItemStyle:
            // 處理項目符號列表項 - 使用制表符实现缩进
            let indentPrefix = String(repeating: "\t", count: bulletItem.level)
            let prefixText = NSMutableAttributedString(string: "\(indentPrefix)\(defaultBulletSymbol) ")
            // 应用段落样式到前缀文本
            prefixText.addAttributes(style.style.nsAttributes, range: NSRange(location: 0, length: prefixText.length))
            result.append(prefixText)
            
        case let numberItem as NumberListItemStyle:
            // 處理數字列表項 - 使用制表符实现缩进
            let indentPrefix = String(repeating: "\t", count: numberItem.level)
            let prefixText = NSMutableAttributedString(string: "\(indentPrefix)\(numberItem.number ?? 1). ")
            // 应用段落样式到前缀文本
            prefixText.addAttributes(style.style.nsAttributes, range: NSRange(location: 0, length: prefixText.length))
            result.append(prefixText)
            
        case is HorizontalRuleStyle:
            // 处理分隔线样式
            let horizontalRule = NSMutableAttributedString(string: "\n\u{2500}\u{2500}\u{2500}\n")
            horizontalRule.addAttributes(style.style.nsAttributes, range: NSRange(location: 0, length: horizontalRule.length))
            result.append(horizontalRule)
            return result
            
        default:
            // 不处理其他样式的前缀
            break
        }
        
        // 处理子节点
        for (index, child) in style.children.enumerated() {
            let childResult = child.accept(self)
            let mutable = NSMutableAttributedString(attributedString: childResult)
            
            // 应用样式属性
            if style.style.style is BulletListItemStyle || style.style.style is NumberListItemStyle {
                // 对于列表项，我们需要确保子节点也应用了正确的段落样式
                // 但是不要覆盖子节点可能已有的其他样式（如粗体、斜体等）
                if let paragraphStyle = style.style.nsAttributes[.paragraphStyle] as? NSParagraphStyle {
                    // 创建一个新的属性字典，只包含段落样式
                    var paragraphAttributes: [NSAttributedString.Key: Any] = [:]
                    paragraphAttributes[.paragraphStyle] = paragraphStyle
                    
                    // 应用段落样式到子节点
                    mutable.addAttributes(paragraphAttributes, range: NSRange(location: 0, length: mutable.length))
                }
                
                // 应用其他样式属性（除了段落样式）
                for (key, value) in style.style.nsAttributes {
                    if key != .paragraphStyle {
                        mutable.addAttributes([key: value], range: NSRange(location: 0, length: mutable.length))
                    }
                }
            } else {
                // 对于其他样式，需要特殊处理字体属性的合并
                let range = NSRange(location: 0, length: mutable.length)
                
                // 遍历当前样式的所有属性
                for (key, value) in style.style.nsAttributes {
                    // 特殊处理字体属性
                    if key == .font {
                        // 检查子节点是否已有字体属性
                        if let existingFont = mutable.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
                            let newFont = value as! UIFont
                            
                            // 合并字体属性
                            let mergedFont = mergeFonts(existingFont: existingFont, newFont: newFont)
                            mutable.addAttribute(.font, value: mergedFont, range: range)
                        } else {
                            // 如果子节点没有字体属性，直接应用当前样式的字体
                            mutable.addAttribute(key, value: value, range: range)
                        }
                    } else {
                        // 其他属性直接应用
                        mutable.addAttribute(key, value: value, range: range)
                    }
                }
            }
            
            // 添加到结果中
            result.append(mutable)
            
            // 如果是列表容器或引用样式且不是最后一个子节点，添加换行符
            if (style.style.style is BulletListStyle || 
                style.style.style is NumberListStyle || 
                style.style.style is QuoteStyle) && 
               index < style.children.count - 1 {
                let newline = NSAttributedString(string: "\n")
                result.append(newline)
            }
        }
        
        // 如果是引用样式，在最后添加换行符
        if style.style.style is QuoteStyle {
            let newline = NSAttributedString(string: "\n")
            result.append(newline)
        }
        
        return result
    }
    
    // 实现visit(root:)方法
    func visit(root: RootNode) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // 遍历处理所有子节点
        for child in root.children {
            let childResult = child.accept(self)
            result.append(childResult)
        }
        
        return result
    }
    
    // 合并两个字体的属性
    private func mergeFonts(existingFont: UIFont, newFont: UIFont) -> UIFont {
        // 保留现有字体的大小（如果新字体没有指定大小）
        let size = newFont.pointSize != UIFont.systemFontSize ? newFont.pointSize : existingFont.pointSize
        
        // 确定字体特性
        let hasSymbolicTraits = existingFont.fontDescriptor.symbolicTraits
        var newTraits = newFont.fontDescriptor.symbolicTraits
        
        // 合并字体特性
        if hasSymbolicTraits.contains(.traitBold) {
            newTraits.insert(.traitBold)
        }
        if hasSymbolicTraits.contains(.traitItalic) {
            newTraits.insert(.traitItalic)
        }
        
        // 创建新的字体描述符
        if let newDescriptor = newFont.fontDescriptor.withSymbolicTraits(newTraits) {
            return UIFont(descriptor: newDescriptor, size: size)
        }
        
        // 如果无法创建新的描述符，使用新字体但保留大小
        return newFont.withSize(size)
    }
}

// MARK: - Raw Text Visitor
class RawTextVisitor: MarkupVisitor {
    typealias Result = String
    private var defaultBulletSymbol: String
    
    init(defaultBulletSymbol: String = "•") {
        self.defaultBulletSymbol = defaultBulletSymbol
    }
    
    func visit(text: TextNode) -> String {
        return text.text
    }
    
    func visit(style: StyleNode) -> String {
        // 处理特殊样式
        switch style.style.style {
        case is CustomStyle where style.style.name == "plain":
            return style.children.map { $0.accept(self) }.joined()
            
        case is QuoteStyle:
            // 处理引用样式
            let childrenText = style.children.map { $0.accept(self) }.joined()
            let lines = childrenText.components(separatedBy: "\n")
            let quotedLines = lines.map { line in
                return style.style.standardOpeningTag + line
            }
            return quotedLines.joined(separator: "\n")
            
        case is BulletListStyle:
            // 列表容器需要确保每个列表项之间有换行
            return style.children.map { $0.accept(self) }.joined(separator: "\n")
            
        case is NumberListStyle:
            // 列表容器需要确保每个列表项之间有换行
            return style.children.map { $0.accept(self) }.joined(separator: "\n")
            
        case let bulletItem as BulletListItemStyle:
            // 处理项目符号列表项
            return formatListItem(
                content: processListItemContent(style.children),
                prefix: "- ",
                indentLevel: bulletItem.level
            )
            
        case let numberItem as NumberListItemStyle:
            // 处理数字列表项
            return formatListItem(
                content: processListItemContent(style.children),
                prefix: "\(numberItem.number ?? 1). ",
                indentLevel: numberItem.level
            )
            
        case is HorizontalRuleStyle:
            // 处理分隔线样式
            return "\n***\n"
            
        default:
            // 其他样式使用标准标记
            let childrenText = style.children.map { $0.accept(self) }.joined()
            return style.style.standardOpeningTag + childrenText + style.style.standardClosingTag
        }
    }
    
    // 实现visit(root:)方法
    func visit(root: RootNode) -> String {
        // 合并所有子节点的文本
        return root.children.map { $0.accept(self) }.joined()
    }
    
    // 格式化列表项，處理縮進和換行
    private func formatListItem(content: String, prefix: String, indentLevel: Int) -> String {
        let indent = String(repeating: "  ", count: indentLevel)
        let lines = content.components(separatedBy: "\n")
        
        // 處理第一行（包含列表標記）
        let firstLine = "\(indent)\(prefix)\(lines[0])"
        
        // 如果只有一行，直接返回
        if lines.count == 1 {
            return firstLine
        }
        
        // 處理後續行（保持縮進但不添加列表標記）
        let continuationIndent = indent + String(repeating: " ", count: prefix.count)
        let continuationLines = lines[1...].map { line in
            return line.isEmpty ? "" : "\(continuationIndent)\(line)"
        }
        
        // 組合所有行
        return ([firstLine] + continuationLines).joined(separator: "\n")
    }
    
    // 处理列表项内容，移除前缀符号
    private func processListItemContent(_ nodes: [MarkupNode]) -> String {
        // 如果没有子节点，返回空字符串
        if nodes.isEmpty {
            return ""
        }
        
        // 获取所有子节点的文本
        let fullText = nodes.map { $0.accept(self) }.joined().replacingOccurrences(of: "\t", with: "")
        
        // 检查文本是否以项目符号开头
        if fullText.hasPrefix(defaultBulletSymbol) {
            // 如果以默认项目符号开头，移除它和后面的空格
            let startIndex = fullText.index(fullText.startIndex, offsetBy: defaultBulletSymbol.count)
            let trimmedText = String(fullText[startIndex...]).trimmingCharacters(in: .whitespaces)
            return trimmedText
        } else if fullText.hasPrefix("-") {
            // 如果以连字符开头，移除它和后面的空格
            let startIndex = fullText.index(after: fullText.startIndex)
            let trimmedText = String(fullText[startIndex...]).trimmingCharacters(in: .whitespaces)
            return trimmedText
        } else if fullText.hasPrefix("*") {
            // 如果以星号开头，移除它和后面的空格
            let startIndex = fullText.index(after: fullText.startIndex)
            let trimmedText = String(fullText[startIndex...]).trimmingCharacters(in: .whitespaces)
            return trimmedText
        }
        
        // 检查文本是否以数字编号开头
        let pattern = "^\\d+\\.\\s+"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: fullText, range: NSRange(fullText.startIndex..., in: fullText)),
           let range = Range(match.range, in: fullText) {
            // 如果以数字编号开头，移除它
            return String(fullText[range.upperBound...])
        }
        
        // 如果没有前缀符号，直接返回原文本
        return fullText
    }
} 
