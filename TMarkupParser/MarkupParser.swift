import Foundation
import UIKit

public class MarkupParser {
    private var styles: [String: MarkupStyle]
    private var patterns: [(NSRegularExpression, (NSTextCheckingResult, String) -> MarkupStyle?)]
    private let normalizer: MarkupNormalizer

    public init(normalizer: MarkupNormalizer = MarkupNormalizer()) {
        self.styles = [:]
        self.patterns = []
        self.normalizer = normalizer
        registerDefaultMarkdownStyles()
    }

    private func registerDefaultMarkdownStyles() {
        // 先註冊標題樣式（最高優先級）
        registerHeadingStyles()
        
        // 先註冊 code block，確保它優先於其他樣式被匹配
        registerCodeBlockStyle()

        // 註冊列表樣式（第二優先級）
        registerListStyles()

        // 註冊引用樣式（第三優先級）
        registerQuoteStyle()

        // 註冊分隔線樣式
        registerHorizontalRuleStyle()

        // 註冊其他固定樣式
        registerFixedStyle(MarkupStyle.bold)
        registerFixedStyle(MarkupStyle.italic)
        registerFixedStyle(MarkupStyle.strikethrough)
        registerFixedStyle(MarkupStyle.code)
        
        // 註冊 mention 樣式
        registerMentionStyle()

        // 最後註冊動態樣式解析器
        registerDynamicStyle()
    }

    private func registerHeadingStyles() {
        // 註冊 H1-H6 標題樣式
        registerFixedStyle(MarkupStyle.h1())
        registerFixedStyle(MarkupStyle.h2())
        registerFixedStyle(MarkupStyle.h3())
        registerFixedStyle(MarkupStyle.h4())
        registerFixedStyle(MarkupStyle.h5())
        registerFixedStyle(MarkupStyle.h6())
    }

    private func registerCodeBlockStyle() {
        let pattern = "```([^\\n]*?)\\n([\\s\\S]*?)```"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            patterns.append((regex, { match, text in
                let nsText = text as NSString
                let language = match.numberOfRanges > 1 ? nsText.substring(with: match.range(at: 1)) : nil
                return MarkupStyle.codeBlock(language: language)
            }))
        }
    }

    private func registerListStyles() {
        // 註冊完整列表結構
        registerCompleteListStructure()
    }
    
    private func registerCompleteListStructure() {
        // 匹配整個項目符號列表結構
        let bulletListPattern = "(?:^([ ]*)[-*]\\s+(.+)$\\n?)+"
        if let regex = try? NSRegularExpression(pattern: bulletListPattern, options: .anchorsMatchLines) {
            patterns.append((regex, { [weak self] match, text in
                return self?.processBulletListStructure(match: match, in: text)
            }))
        }
        
        // 匹配整個數字列表結構
        let numberListPattern = "(?:^([ ]*)\\d+\\.\\s+(.+)$\\n?)+"
        if let regex = try? NSRegularExpression(pattern: numberListPattern, options: .anchorsMatchLines) {
            patterns.append((regex, { [weak self] match, text in
                return self?.processNumberListStructure(match: match, in: text)
            }))
        }
    }
    
    private func processBulletListStructure(match: NSTextCheckingResult, in text: String) -> MarkupStyle? {
        let nsText = text as NSString
        let matchedText = nsText.substring(with: match.range)
        
        // 分析列表結構
        let listItems = matchedText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // 確定列表的基本縮進級別
        var baseIndentLevel = Int.max
        let itemPattern = "^([ ]*)[-*]\\s+(.+)$"
        let itemRegex = try? NSRegularExpression(pattern: itemPattern)
        
        for item in listItems {
            if let itemMatch = itemRegex?.firstMatch(in: item, range: NSRange(location: 0, length: item.count)) {
                let indentRange = itemMatch.range(at: 1)
                let indent = (item as NSString).substring(with: indentRange)
                let level = indent.count / 2
                baseIndentLevel = min(baseIndentLevel, level)
            }
        }
        
        if baseIndentLevel == Int.max {
            baseIndentLevel = 0
        }
        
        return MarkupStyle.bulletList(level: baseIndentLevel)
    }
    
    private func processNumberListStructure(match: NSTextCheckingResult, in text: String) -> MarkupStyle? {
        let nsText = text as NSString
        let matchedText = nsText.substring(with: match.range)
        
        // 分析列表結構
        let listItems = matchedText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // 確定列表的基本縮進級別和起始數字
        var baseIndentLevel = Int.max
        var startNumber: Int? = nil
        let itemPattern = "^([ ]*)([0-9]+)\\.\\s+(.+)$"
        let itemRegex = try? NSRegularExpression(pattern: itemPattern)
        
        for (index, item) in listItems.enumerated() {
            if let itemMatch = itemRegex?.firstMatch(in: item, range: NSRange(location: 0, length: item.count)) {
                let indentRange = itemMatch.range(at: 1)
                let indent = (item as NSString).substring(with: indentRange)
                let level = indent.count / 2
                baseIndentLevel = min(baseIndentLevel, level)
                
                // 獲取第一個項目的數字作為起始數字
                if index == 0 && itemMatch.numberOfRanges > 2 {
                    let numberRange = itemMatch.range(at: 2)
                    let numberStr = (item as NSString).substring(with: numberRange)
                    startNumber = Int(numberStr)
                }
            }
        }
        
        if baseIndentLevel == Int.max {
            baseIndentLevel = 0
        }
        
        return MarkupStyle.numberList(start: startNumber, level: baseIndentLevel)
    }

    private func registerFixedStyle(_ style: MarkupStyle) {
        styles[style.name] = style
        if let regex = try? NSRegularExpression(pattern: style.patterns) {
            patterns.append((regex, { match, text in
                MarkupStyle.from(match: match, in: text)
            }))
        }
    }

    private func registerMentionStyle() {
        let pattern = "@\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            patterns.append((regex, { match, text in
                let nsText = text as NSString
                let displayName = nsText.substring(with: match.range(at: 1))
                let userId = nsText.substring(with: match.range(at: 2))
                return MarkupStyle.mention(userId: userId, displayName: displayName)
            }))
        }
    }

    private func registerDynamicStyle() {
        let pattern = "\\{\\{(\\w+)\\s*([^\\}]*)\\}\\}((?:[^\\{]|\\{(?!\\{))*?)\\{\\{/\\1\\}\\}"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            patterns.append((regex, { [weak self] match, text in
                self?.parseDynamicStyle(match: match, in: text)
            }))
        }
    }

    private func parseDynamicStyle(match: NSTextCheckingResult, in text: String) -> MarkupStyle? {
        let nsText = text as NSString
        guard match.numberOfRanges >= 4 else { return nil }

        let nameRange = match.range(at: 1)
        let name = nsText.substring(with: nameRange)

        let attributesRange = match.range(at: 2)
        let attributesString = nsText.substring(with: attributesRange).trimmingCharacters(in: .whitespaces)

        var attributes: [StyleAttribute] = []
        if !attributesString.isEmpty {
            let pattern = "([\\w-]+)=\"([^\"]*)\""
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let results = regex.matches(in: attributesString, range: NSRange(location: 0, length: attributesString.count))
                for result in results {
                    let keyRange = result.range(at: 1)
                    let valueRange = result.range(at: 2)
                    let key = (attributesString as NSString).substring(with: keyRange)
                    let value = (attributesString as NSString).substring(with: valueRange)
                    attributes.append(StyleAttribute(key: key, value: value))
                }
            }
        }

        switch name {
            case "font":
                return MarkupStyle.font(attributes: attributes)
            default:
                return MarkupStyle.custom(name: name, attributes: attributes)
        }
    }

    private func registerHorizontalRuleStyle() {
        styles[MarkupStyle.horizontalRule.name] = MarkupStyle.horizontalRule
        if let regex = try? NSRegularExpression(pattern: MarkupStyle.horizontalRule.patterns, options: .anchorsMatchLines) {
            patterns.append((regex, { match, text in
                return MarkupStyle.horizontalRule
            }))
        }
    }

    private func registerQuoteStyle() {
        let pattern = "(^|\\n)(>+\\s*[^\\n]*(?:\\n>+\\s*[^\\n]*)*)"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            patterns.append((regex, { match, text in
                let nsText = text as NSString
                let fullMatch = nsText.substring(with: match.range)
                
                // 计算引用层级
                var maxLevel = 0
                let lines = fullMatch.components(separatedBy: .newlines)
                for line in lines where !line.isEmpty {
                    var level = 0
                    for char in line {
                        if char == ">" {
                            level += 1
                        } else {
                            break
                        }
                    }
                    maxLevel = max(maxLevel, level)
                }
                
                return MarkupStyle.quote(level: max(0, maxLevel - 1))
            }))
        }
    }

    func parse(_ text: String) -> MarkupNode {
        // 先对文本进行正规化处理
        let normalizedText = normalizer.normalize(text)
        
        var allMatches: [(NSRange, MarkupStyle)] = []
        let nsText = normalizedText as NSString

        // 收集所有匹配
        for (pattern, styleCreator) in patterns {
            let results = pattern.matches(in: normalizedText, range: NSRange(location: 0, length: nsText.length))
            for match in results {
                if let style = styleCreator(match, normalizedText) {
                    allMatches.append((match.range, style))
                }
            }
        }

        // 按照位置排序匹配结果
        allMatches.sort { $0.0.location < $1.0.location }

        // 找出最外层的匹配
        let outerMatches = findOuterMatches(allMatches)

        // 处理巢狀结构
        return processMatches(outerMatches, in: normalizedText)
    }

    private func findOuterMatches(_ matches: [(NSRange, MarkupStyle)]) -> [(NSRange, MarkupStyle)] {
        // 如果沒有匹配，直接返回空數組
        if matches.isEmpty {
            return []
        }
        
        // 按照位置排序匹配結果
        let sortedMatches = matches.sorted { $0.0.location < $1.0.location }
        
        // 特殊處理：如果只有一個匹配，直接返回
        if sortedMatches.count == 1 {
            return sortedMatches
        }
        
        // 特殊處理：如果有列表樣式，需要優先處理
        // 但不再直接返回第一個列表樣式，而是找出所有不被其他匹配包含的列表樣式
        let listMatches = sortedMatches.filter { 
            $0.1.style is BulletListStyle || $0.1.style is NumberListStyle 
        }
        
        if !listMatches.isEmpty {
            var outerListMatches: [(NSRange, MarkupStyle)] = []
            
            for listMatch in listMatches {
                var isOuter = true
                
                for other in sortedMatches {
                    if listMatch.0 != other.0 && // 不是同一個匹配
                       !(other.1.style is BulletListStyle || other.1.style is NumberListStyle) && // 其他匹配不是列表樣式
                       other.0.location < listMatch.0.location && // 其他匹配開始位置在列表匹配之前
                       NSMaxRange(other.0) > NSMaxRange(listMatch.0) { // 其他匹配結束位置在列表匹配之後
                        isOuter = false
                        break
                    }
                }
                
                if isOuter {
                    outerListMatches.append(listMatch)
                }
            }
            
            // 如果找到了外層列表匹配，返回它們
            if !outerListMatches.isEmpty {
                return outerListMatches.sorted { $0.0.location < $1.0.location }
            }
        }
        
        // 一般處理：找出所有不被其他匹配包含的匹配
        var outerMatches: [(NSRange, MarkupStyle)] = []
        
        for (i, current) in sortedMatches.enumerated() {
            var isOuter = true
            
            for (j, other) in sortedMatches.enumerated() {
                if i != j {
                    let currentRange = current.0
                    let otherRange = other.0
                    
                    // 檢查當前匹配是否被其他匹配完全包含
                    if otherRange.location < currentRange.location &&
                       NSMaxRange(otherRange) > NSMaxRange(currentRange) {
                        isOuter = false
                        break
                    }
                }
            }
            
            if isOuter {
                outerMatches.append(current)
            }
        }
        
        return outerMatches.sorted { $0.0.location < $1.0.location }
    }

    private func processMatches(_ matches: [(NSRange, MarkupStyle)], in text: String) -> MarkupNode {
        if matches.isEmpty {
            return TextNode(text: text)
        }

        var nodes: [MarkupNode] = []
        var currentIndex = 0
        let nsText = text as NSString

        // 按照位置排序匹配结果
        let sortedMatches = matches.sorted { $0.0.location < $1.0.location }

        for (range, style) in sortedMatches {
            if currentIndex < range.location {
                let plainText = nsText.substring(with: NSRange(location: currentIndex, length: range.location - currentIndex))
                if !plainText.isEmpty {
                    nodes.append(TextNode(text: plainText))
                }
            }

            // 特殊处理列表和引用样式
            if style.style is BulletListStyle {
                let listNode = processListStructure(range: range, style: style, in: text, isBullet: true)
                nodes.append(listNode)
            } else if style.style is NumberListStyle {
                let listNode = processListStructure(range: range, style: style, in: text, isBullet: false)
                nodes.append(listNode)
            } else if style.style is QuoteStyle {
                let quoteText = nsText.substring(with: range)
                let lines = quoteText.components(separatedBy: .newlines)
                var currentLevel = 0
                var currentContent = ""
                var quoteNodes: [MarkupNode] = []

                for line in lines where !line.isEmpty {
                    // 计算当前行的引用级别
                    var level = 0
                    var content = line
                    while content.hasPrefix(">") {
                        level += 1
                        content = content.dropFirst().trimmingCharacters(in: .whitespaces)
                    }

                    if level != currentLevel {
                        // 如果级别改变，处理之前累积的内容
                        if !currentContent.isEmpty {
                            let innerNode = parseInnerContent(currentContent)
                            quoteNodes.append(StyleNode(style: MarkupStyle.quote(level: max(0, currentLevel - 1)), children: [innerNode]))
                            currentContent = ""
                        }
                        currentLevel = level
                    }

                    // 添加当前行内容
                    if !currentContent.isEmpty {
                        currentContent += "\n"
                    }
                    currentContent += content
                }

                // 处理最后一段内容
                if !currentContent.isEmpty {
                    let innerNode = parseInnerContent(currentContent)
                    quoteNodes.append(StyleNode(style: MarkupStyle.quote(level: max(0, currentLevel - 1)), children: [innerNode]))
                }

                // 将所有引用节点添加到主节点列表
                nodes.append(contentsOf: quoteNodes)
            } else {
                // 处理其他样式
                let innerRange = NSRange(
                    location: range.location + style.standardOpeningTag.count,
                    length: range.length - style.standardOpeningTag.count - style.standardClosingTag.count)
                let innerText = nsText.substring(with: innerRange)
                let innerNode = parseInnerContent(innerText)
                nodes.append(StyleNode(style: style, children: [innerNode]))
            }

            currentIndex = range.location + range.length
        }

        if currentIndex < nsText.length {
            let plainText = nsText.substring(with: NSRange(location: currentIndex, length: nsText.length - currentIndex))
            if !plainText.isEmpty {
                nodes.append(TextNode(text: plainText))
            }
        }

        return nodes.count == 1 ? nodes[0] : StyleNode(style: plainStyle, children: nodes)
    }
    
    private func processListStructure(range: NSRange, style: MarkupStyle, in text: String, isBullet: Bool) -> MarkupNode {
        let nsText = text as NSString
        let listText = nsText.substring(with: range)
        
        // 分割所有行，不过滤空行，以保留换行信息
        let allLines = listText.components(separatedBy: .newlines)
        
        // 创建列表项节点
        var itemNodes: [MarkupNode] = []
        // 更新正则表达式模式以匹配制表符
        let itemPattern = isBullet ? 
            "^([\\s\\t]*)[-*]\\s+(.+)$" : 
            "^([\\s\\t]*)([0-9]+)\\.\\s+(.+)$"
        
        var currentItemContent: String = ""
        var currentItemIndent: String = ""
        var currentItemLevel: Int = 0
        var currentItemNumber: Int? = nil
        var inListItem = false
        
        if let itemRegex = try? NSRegularExpression(pattern: itemPattern) {
            for (lineIndex, line) in allLines.enumerated() {
                if line.isEmpty && lineIndex < allLines.count - 1 {
                    // 空行处理：如果在列表项中，添加换行符到当前内容
                    if inListItem {
                        currentItemContent += "\n"
                    }
                    continue
                }
                
                // 检查是否是新的列表项
                if let itemMatch = itemRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.count)) {
                    // 如果已经在处理一个列表项，先保存之前的项
                    if inListItem && !currentItemContent.isEmpty {
                        // 解析列表项内容（可能包含其他标记）
                        let contentNode = parseInnerContent(currentItemContent)
                        
                        // 计算相对缩进级别
                        let baseLevel: Int
                        if isBullet {
                            if let bulletStyle = style.style as? BulletListStyle {
                                baseLevel = bulletStyle.level
                            } else {
                                baseLevel = 0
                            }
                        } else {
                            if let numberStyle = style.style as? NumberListStyle {
                                baseLevel = numberStyle.level
                            } else {
                                baseLevel = 0
                            }
                        }
                        
                        let relativeLevel = currentItemLevel - baseLevel
                        
                        // 为列表项创建特定样式
                        let itemStyle: MarkupStyle
                        if isBullet {
                            itemStyle = MarkupStyle.bulletListItem(level: relativeLevel)
                        } else {
                            itemStyle = MarkupStyle.numberListItem(number: currentItemNumber, level: relativeLevel)
                        }
                        
                        // 添加列表项节点
                        itemNodes.append(StyleNode(style: itemStyle, children: [contentNode]))
                    }
                    
                    // 提取列表项内容和缩进
                    let indentRange = itemMatch.range(at: 1)
                    let indent = (line as NSString).substring(with: indentRange)
                    
                    // 计算缩进级别 - 考虑制表符
                    let level: Int
                    if indent.contains("\t") {
                        // 如果包含制表符，每个制表符算作一个级别
                        level = indent.filter { $0 == "\t" }.count
                    } else {
                        // 如果是空格，每两个空格算作一个级别
                        level = indent.count / 2
                    }
                    
                    // 提取列表项内容
                    let contentGroupIndex = isBullet ? 2 : 3
                    if itemMatch.numberOfRanges > contentGroupIndex {
                        let contentRange = itemMatch.range(at: contentGroupIndex)
                        let content = (line as NSString).substring(with: contentRange)
                        
                        // 保存当前列表项信息
                        currentItemContent = content
                        currentItemIndent = indent
                        currentItemLevel = level
                        inListItem = true
                        
                        // 对于数字列表项，保存编号
                        if !isBullet && itemMatch.numberOfRanges > 2 {
                            let numberRange = itemMatch.range(at: 2)
                            let numberStr = (line as NSString).substring(with: numberRange)
                            currentItemNumber = Int(numberStr)
                        }
                    }
                } else if inListItem {
                    // 检查是否属于当前列表项的后续行（缩进行）
                    // 使用简单的缩进检测：行的前缀应该与列表项的缩进加上额外缩进匹配
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    
                    if !trimmedLine.isEmpty {
                        // 检查行的前缀是否为空格或制表符
                        let leadingWhitespace = line.prefix(while: { $0 == " " || $0 == "\t" })
                        
                        // 如果缩进至少与列表项缩进相同，则认为是后续行
                        if leadingWhitespace.count >= currentItemIndent.count {
                            // 添加换行符和后续内容
                            if !currentItemContent.isEmpty {
                                currentItemContent += "\n"
                            }
                            currentItemContent += trimmedLine
                        } else {
                            // 如果缩进不够，结束当前列表项
                            // 解析列表项内容
                            let contentNode = parseInnerContent(currentItemContent)
                            
                            // 计算相对缩进级别
                            let baseLevel: Int
                            if isBullet {
                                if let bulletStyle = style.style as? BulletListStyle {
                                    baseLevel = bulletStyle.level
                                } else {
                                    baseLevel = 0
                                }
                            } else {
                                if let numberStyle = style.style as? NumberListStyle {
                                    baseLevel = numberStyle.level
                                } else {
                                    baseLevel = 0
                                }
                            }
                            
                            let relativeLevel = currentItemLevel - baseLevel
                            
                            // 为列表项创建特定样式
                            let itemStyle: MarkupStyle
                            if isBullet {
                                itemStyle = MarkupStyle.bulletListItem(level: relativeLevel)
                            } else {
                                itemStyle = MarkupStyle.numberListItem(number: currentItemNumber, level: relativeLevel)
                            }
                            
                            // 添加列表项节点
                            itemNodes.append(StyleNode(style: itemStyle, children: [contentNode]))
                            
                            // 重置列表项状态
                            inListItem = false
                            currentItemContent = ""
                        }
                    } else {
                        // 空行处理：添加换行符到当前内容
                        currentItemContent += "\n"
                    }
                }
            }
            
            // 处理最后一个列表项
            if inListItem && !currentItemContent.isEmpty {
                // 解析列表项内容
                let contentNode = parseInnerContent(currentItemContent)
                
                // 计算相对缩进级别
                let baseLevel: Int
                if isBullet {
                    if let bulletStyle = style.style as? BulletListStyle {
                        baseLevel = bulletStyle.level
                    } else {
                        baseLevel = 0
                    }
                } else {
                    if let numberStyle = style.style as? NumberListStyle {
                        baseLevel = numberStyle.level
                    } else {
                        baseLevel = 0
                    }
                }
                
                let relativeLevel = currentItemLevel - baseLevel
                
                // 为列表项创建特定样式
                let itemStyle: MarkupStyle
                if isBullet {
                    itemStyle = MarkupStyle.bulletListItem(level: relativeLevel)
                } else {
                    itemStyle = MarkupStyle.numberListItem(number: currentItemNumber, level: relativeLevel)
                }
                
                // 添加列表项节点
                itemNodes.append(StyleNode(style: itemStyle, children: [contentNode]))
            }
        }
        
        // 创建列表容器节点
        return StyleNode(style: style, children: itemNodes)
    }

    // 解析内部内容的辅助方法
    private func parseInnerContent(_ text: String) -> MarkupNode {
        // 如果内部文本为空，返回空文本节点
        if text.isEmpty {
            return TextNode(text: "")
        }
        
        // 查找内部文本中的所有匹配
        var innerMatches: [(NSRange, MarkupStyle)] = []
        let nsText = text as NSString
        
        for (pattern, styleCreator) in patterns {
            let results = pattern.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in results {
                if let style = styleCreator(match, text) {
                    innerMatches.append((match.range, style))
                }
            }
        }
        
        // 如果没有匹配，返回纯文本节点
        if innerMatches.isEmpty {
            return TextNode(text: text)
        }
        
        // 找出最外层匹配并处理
        let outerMatches = findOuterMatches(innerMatches)
        return processMatches(outerMatches, in: text)
    }

    private var plainStyle: MarkupStyle {
        return MarkupStyle.custom(name: "plain", attributes: [])
    }
}
