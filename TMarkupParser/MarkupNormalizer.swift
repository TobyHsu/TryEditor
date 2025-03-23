import Foundation

public class MarkupNormalizer {
    public init() {}
    public func normalize(_ text: String) -> String {
        var result = text
        
        // 正规化粗体标记（将三个或更多星号正规化为两个星号）
        result = normalizeBoldMarkers(result)
        
        return result
    }
    
    /// 将三个或更多星号正规化为两个星号
    private func normalizeBoldMarkers(_ text: String) -> String {
        // 匹配三个或更多星号包围的内容
        let pattern = "(\\*{3,})([^\\*]+?)(\\*{3,})"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        
        var result = text
        var offset = 0
        
        // 获取所有匹配
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            // 调整偏移量后的范围
            let adjustedRange = NSRange(
                location: match.range.location - offset,
                length: match.range.length
            )
            
            // 获取内容
            let openingMarkers = nsText.substring(with: match.range(at: 1))
            let content = nsText.substring(with: match.range(at: 2))
            let closingMarkers = nsText.substring(with: match.range(at: 3))
            
            // 创建替换文本
            let replacement = "**\(content)**"
            
            // 计算偏移量变化
            let oldLength = adjustedRange.length
            let newLength = replacement.count
            offset += oldLength - newLength
            
            // 替换文本
            result = (result as NSString).replacingCharacters(in: adjustedRange, with: replacement)
        }
        
        return result
    }
    
    /// 更复杂的实现可以添加更多的正规化方法
    // func normalizeItalicMarkers(_ text: String) -> String { ... }
    // func normalizeStrikethroughMarkers(_ text: String) -> String { ... }
}

// 扩展：支持自定义正规化规则
protocol NormalizationRule {
    func apply(to text: String) -> String
}

class BoldMarkersRule: NormalizationRule {
    func apply(to text: String) -> String {
        // 匹配三个或更多星号包围的内容
        let pattern = "(\\*{3,})([^\\*]+?)(\\*{3,})"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        
        var result = text
        var offset = 0
        
        // 获取所有匹配
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            // 调整偏移量后的范围
            let adjustedRange = NSRange(
                location: match.range.location - offset,
                length: match.range.length
            )
            
            // 获取内容
            let content = nsText.substring(with: match.range(at: 2))
            
            // 创建替换文本
            let replacement = "**\(content)**"
            
            // 计算偏移量变化
            let oldLength = adjustedRange.length
            let newLength = replacement.count
            offset += oldLength - newLength
            
            // 替换文本
            result = (result as NSString).replacingCharacters(in: adjustedRange, with: replacement)
        }
        
        return result
    }
}

// 可配置的规范化器
class ConfigurableMarkupNormalizer {
    private var rules: [NormalizationRule]
    
    init(rules: [NormalizationRule] = []) {
        self.rules = rules
        if rules.isEmpty {
            registerDefaultRules()
        }
    }
    
    private func registerDefaultRules() {
        rules.append(BoldMarkersRule())
        // 可以添加更多默认规则
    }
    
    func normalize(_ text: String) -> String {
        return rules.reduce(text) { currentText, rule in
            rule.apply(to: currentText)
        }
    }
    
    func addRule(_ rule: NormalizationRule) {
        rules.append(rule)
    }
} 
