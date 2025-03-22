import Foundation
import UIKit

class MarkupConverter {
    private let parser: MarkupParser
    private let baseFont: UIFont
    private let defaultTextColor: UIColor
    private let defaultBackgroundColor: UIColor
    private let defaultLineHeight: CGFloat
    private let defaultLetterSpacing: CGFloat
    private let defaultTextAlignment: NSTextAlignment
    private let defaultBulletSymbol: String
    
    init(parser: MarkupParser,
         baseFont: UIFont = .systemFont(ofSize: UIFont.systemFontSize),
         defaultTextColor: UIColor = .label,
         defaultBackgroundColor: UIColor = .clear,
         defaultLineHeight: CGFloat = 1.0,
         defaultLetterSpacing: CGFloat = 0.0,
         defaultTextAlignment: NSTextAlignment = .natural,
         defaultBulletSymbol: String = "•") {
        self.parser = parser
        self.baseFont = baseFont
        self.defaultTextColor = defaultTextColor
        self.defaultBackgroundColor = defaultBackgroundColor
        self.defaultLineHeight = defaultLineHeight
        self.defaultLetterSpacing = defaultLetterSpacing
        self.defaultTextAlignment = defaultTextAlignment
        self.defaultBulletSymbol = defaultBulletSymbol
    }
    
    func attributedStringFromMarkup(_ text: String, baseAttributes: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString {
        let node = parser.parse(text)
        let visitor = AttributedStringVisitor(baseFont: baseFont, defaultBulletSymbol: defaultBulletSymbol)
        var result = node.accept(visitor)
        
        if let baseAttributes = baseAttributes {
            let mutable = NSMutableAttributedString(attributedString: result)
            mutable.addAttributes(baseAttributes, range: NSRange(location: 0, length: mutable.length))
            result = mutable
        }
        
        return result
    }
    
    func markupFromAttributedString(_ attributedString: NSAttributedString) -> String {
        let visitor = RawTextVisitor(defaultBulletSymbol: defaultBulletSymbol)
        let node = convertAttributedStringToNode(attributedString)
        return node.accept(visitor)
    }
    
    private func detectStyle(from attributes: [NSAttributedString.Key: Any], in text: String, at range: NSRange) -> [MarkupStyle] {
        var styles: [MarkupStyle] = []
        var styleAttributes: [StyleAttribute] = []
        
        // 檢查字體相關屬性
        if let font = attributes[.font] as? UIFont {
            styles.append(contentsOf: detectFontStyles(font))
            
            appendIfDifferent(&styleAttributes, forFont: font)
        }
        
        // 檢查顏色和背景顏色
        appendIfDifferent(&styleAttributes, forColor: attributes[.foregroundColor] as? UIColor, 
                           andBackgroundColor: attributes[.backgroundColor] as? UIColor)
        
        // 檢查下劃線和刪除線
        appendUnderlineAndStrikethrough(&styles, &styleAttributes, from: attributes)
        
        // 檢查連結
        if let url = attributes[.link] as? String {
            styles.append(MarkupStyle.link(url: url))
        }
        
        // 檢查段落樣式
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            // 檢查引用樣式
            if paragraphStyle.firstLineHeadIndent == 20 && paragraphStyle.headIndent == 20 {
                styles.append(MarkupStyle.quote)
            }
            
            // 檢查列表樣式
            if paragraphStyle.headIndent > 0 && paragraphStyle.firstLineHeadIndent < paragraphStyle.headIndent {
                let listStyles = detectListStyles(paragraphStyle, in: text, at: range)
                if !listStyles.isEmpty {
                    return listStyles // 列表樣式優先返回
                }
            }
            
            // 檢查對齊方式
            appendIfDifferent(&styleAttributes, forAlignment: paragraphStyle.alignment)
        }
        
        // 檢查字間距
        appendIfDifferent(&styleAttributes, forKern: attributes[.kern] as? CGFloat)
        
        // 只有當有非預設的樣式屬性時，才創建 font 樣式
        if !styleAttributes.isEmpty {
            styles.append(MarkupStyle.font(attributes: styleAttributes))
        }
        
        return styles
    }
    
    // MARK: - 輔助方法
    
    private func detectFontStyles(_ font: UIFont) -> [MarkupStyle] {
        var styles: [MarkupStyle] = []
        let traits = font.fontDescriptor.symbolicTraits
        
        if traits.contains(.traitBold) {
            styles.append(MarkupStyle.bold)
        }
        if traits.contains(.traitItalic) {
            styles.append(MarkupStyle.italic)
        }
        if traits.contains(.traitMonoSpace) {
            styles.append(MarkupStyle.code)
        }
        
        return styles
    }
    
    private func appendIfDifferent(_ attributes: inout [StyleAttribute], forFont font: UIFont) {
        // 檢查字體大小
        if font.pointSize != baseFont.pointSize {
            attributes.append(StyleAttribute(key: "size", value: String(format: "%.0f", font.pointSize)))
        }
        
        // 檢查字體名稱
        if font.familyName != baseFont.familyName {
            attributes.append(StyleAttribute(key: "font-family", value: font.familyName))
        }
    }
    
    private func appendIfDifferent(_ attributes: inout [StyleAttribute], forColor color: UIColor?, andBackgroundColor backgroundColor: UIColor?) {
        // 檢查前景顏色
        if let color = color, color != defaultTextColor {
            attributes.append(StyleAttribute(key: "color", value: color.hexString))
        }
        
        // 檢查背景顏色
        if let backgroundColor = backgroundColor, backgroundColor != defaultBackgroundColor {
            attributes.append(StyleAttribute(key: "background-color", value: backgroundColor.hexString))
        }
    }
    
    private func appendUnderlineAndStrikethrough(_ styles: inout [MarkupStyle], _ attributes: inout [StyleAttribute], from textAttributes: [NSAttributedString.Key: Any]) {
        if let underlineStyle = textAttributes[.underlineStyle] as? Int {
            if underlineStyle == NSUnderlineStyle.single.rawValue {
                attributes.append(StyleAttribute(key: "decoration", value: "underline"))
            }
        }
        
        if let strikethroughStyle = textAttributes[.strikethroughStyle] as? Int {
            if strikethroughStyle == NSUnderlineStyle.single.rawValue {
                styles.append(MarkupStyle.strikethrough)
            }
        }
    }
    
    private func appendIfDifferent(_ attributes: inout [StyleAttribute], forAlignment alignment: NSTextAlignment) {
        if alignment != defaultTextAlignment {
            let alignmentValue: String
            switch alignment {
            case .left: alignmentValue = "left"
            case .center: alignmentValue = "center"
            case .right: alignmentValue = "right"
            case .justified: alignmentValue = "justified"
            default: alignmentValue = "left"
            }
            attributes.append(StyleAttribute(key: "text-alignment", value: alignmentValue))
        }
    }
    
    private func appendIfDifferent(_ attributes: inout [StyleAttribute], forKern kern: CGFloat?) {
        if let kern = kern, kern != defaultLetterSpacing {
            attributes.append(StyleAttribute(key: "letter-spacing", value: String(format: "%.1f", kern)))
        }
    }
    
    private func detectListStyles(_ paragraphStyle: NSParagraphStyle, in text: String, at range: NSRange) -> [MarkupStyle] {
        // 獲取當前行的完整範圍
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: range)
        let lineText = nsText.substring(with: lineRange)
        
        // 如果是列表項的開始部分（即range在行的開頭），處理列表項樣式
        if range.location == lineRange.location {
            // 檢查項目符號列表
            if let bulletStyles = detectBulletListStyles(lineText) {
                return bulletStyles
            }
            
            // 檢查數字列表
            if let numberStyles = detectNumberListStyles(lineText) {
                return numberStyles
            }
        } else {
            // 如果不是列表項的開始部分，檢查是否為列表項的內容部分
            // 這裡不需要返回任何樣式，因為列表項的樣式已在開始部分處理
        }
        
        return []
    }
    
    private func detectBulletListStyles(_ lineText: String) -> [MarkupStyle]? {
        // 檢查是否為項目符號列表項
        let bulletPrefixes = ["- ", "* ", "\(defaultBulletSymbol) "]
        let hasBulletPrefix = bulletPrefixes.contains { prefix in
            let pattern = "^[\\s\\t]*\(NSRegularExpression.escapedPattern(for: prefix))"
            return (try? NSRegularExpression(pattern: pattern).firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.count))) != nil
        }
        
        if hasBulletPrefix {
            let tabCount = countLeadingTabs(in: lineText)
            
            // 創建列表項樣式和容器樣式
            let itemStyle = MarkupStyle.bulletListItem(level: tabCount)
            let containerStyle = MarkupStyle.bulletList(level: tabCount)
            
            return [itemStyle, containerStyle]
        }
        
        return nil
    }
    
    private func detectNumberListStyles(_ lineText: String) -> [MarkupStyle]? {
        // 檢查是否為數字列表項
        if let match = try? NSRegularExpression(pattern: "^[\\s\\t]*(\\d+)\\.\\s").firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.count)),
           let numberRange = Range(match.range(at: 1), in: lineText) {
            
            let tabCount = countLeadingTabs(in: lineText)
            let number = Int(lineText[numberRange])
            
            // 創建列表項樣式和容器樣式
            let itemStyle = MarkupStyle.numberListItem(number: number, level: tabCount)
            let containerStyle = MarkupStyle.numberList(start: number, level: tabCount)
            
            return [itemStyle, containerStyle]
        }
        
        return nil
    }
    
    private func countLeadingTabs(in text: String) -> Int {
        let leadingWhitespacePattern = "^([\\s\\t]*)"
        if let match = try? NSRegularExpression(pattern: leadingWhitespacePattern).firstMatch(in: text, range: NSRange(location: 0, length: text.count)),
           let indentRange = Range(match.range(at: 1), in: text) {
            
            let indentText = String(text[indentRange])
            return indentText.filter { $0 == "\t" }.count
        }
        
        return 0
    }
    
    private func convertAttributedStringToNode(_ attributedString: NSAttributedString) -> MarkupNode {
        if attributedString.length == 0 {
            return TextNode(text: "")
        }
        
        var styleRanges: [(NSRange, MarkupStyle)] = []
        var currentIndex = 0
        
        while currentIndex < attributedString.length {
            var effectiveRange = NSRange(location: 0, length: 0)
            let attributes = attributedString.attributes(at: currentIndex, effectiveRange: &effectiveRange)
            
            let styles = detectStyle(from: attributes, in: attributedString.string, at: effectiveRange)
            for style in styles {
                styleRanges.append((effectiveRange, style))
            }
            
            currentIndex = effectiveRange.location + effectiveRange.length
        }
                
        if styleRanges.isEmpty {
            return TextNode(text: attributedString.string)
        }
        
        return createNodeTree(from: attributedString, with: styleRanges)
    }
    
    // MARK: - 樣式容器處理
    
    private struct StyleContainer {
        let range: NSRange
        let style: MarkupStyle
        var children: [StyleContainer]
        
        init(range: NSRange, style: MarkupStyle, children: [StyleContainer] = []) {
            self.range = range
            self.style = style
            self.children = children
        }
    }
    
    private func buildStyleContainers(from ranges: [(NSRange, MarkupStyle)]) -> [StyleContainer] {
        // 按照位置排序，位置相同時將字體樣式放在前面
        let sortedRanges = ranges.sorted { a, b in
            if a.0.location != b.0.location {
                return a.0.location < b.0.location
            }
            // 字體樣式優先
            if a.1.style is FontStyle {
                return true
            }
            if b.1.style is FontStyle {
                return false
            }
            return true
        }
        
        var containers: [StyleContainer] = []
        var currentIndex = 0
        
        while currentIndex < sortedRanges.count {
            let (range, style) = sortedRanges[currentIndex]
            
            // 找出所有與當前範圍重疊的樣式
            var currentRanges = [(range, style)]
            var nextIndex = currentIndex + 1
            
            while nextIndex < sortedRanges.count {
                let (nextRange, nextStyle) = sortedRanges[nextIndex]
                
                // 如果下一個範圍與當前範圍有重疊
                if nextRange.location < NSMaxRange(range) {
                    currentRanges.append((nextRange, nextStyle))
                    nextIndex += 1
                } else {
                    break
                }
            }
            
            if currentRanges.count > 1 {
                // 處理重疊的範圍
                processOverlappingRanges(currentRanges, into: &containers)
                currentIndex = nextIndex
            } else {
                // 單一樣式的情況
                containers.append(StyleContainer(range: range, style: style))
                currentIndex += 1
            }
        }
        
        return containers
    }
    
    private func processOverlappingRanges(_ ranges: [(NSRange, MarkupStyle)], into containers: inout [StyleContainer]) {
        // 將重疊的範圍分割成不重疊的部分
        var splitPoints = Set<Int>()
        for (r, _) in ranges {
            splitPoints.insert(r.location)
            splitPoints.insert(NSMaxRange(r))
        }
        
        let sortedPoints = splitPoints.sorted()
        
        // 為每個分割區間創建容器
        for i in 0..<(sortedPoints.count - 1) {
            let start = sortedPoints[i]
            let end = sortedPoints[i + 1]
            let segmentRange = NSRange(location: start, length: end - start)
            
            // 找出所有覆蓋這個區間的樣式
            let segmentStyles = ranges.filter {
                NSLocationInRange(start, $0.0) && NSLocationInRange(end - 1, $0.0)
            }.map { $0.1 }
            
            if !segmentStyles.isEmpty {
                // 創建一個包含所有適用樣式的容器
                let container = StyleContainer(range: segmentRange, style: segmentStyles[0],
                                            children: segmentStyles.dropFirst().map {
                                                StyleContainer(range: segmentRange, style: $0)
                                            })
                containers.append(container)
            }
        }
    }
    
    private func createNodeFromContainer(_ container: StyleContainer, text: String) -> MarkupNode {
        if container.children.isEmpty {
            return StyleNode(style: container.style, children: [TextNode(text: (text as NSString).substring(with: container.range))])
        }
        
        // 如果有子容器，先創建最內層的樣式節點
        var node: MarkupNode = TextNode(text: (text as NSString).substring(with: container.range))
        
        // 從內到外套用樣式
        for child in container.children.reversed() {
            node = StyleNode(style: child.style, children: [node])
        }
        
        // 最後套用外層樣式
        return StyleNode(style: container.style, children: [node])
    }
    
    private func createNodeTree(from attributedString: NSAttributedString, with ranges: [(NSRange, MarkupStyle)]) -> MarkupNode {
        if attributedString.length == 0 {
            return TextNode(text: "")
        }
        
        // 建立樣式容器層級結構
        let containers = buildStyleContainers(from: ranges)
        
        // 如果沒有樣式，直接返回純文本
        if containers.isEmpty {
            return TextNode(text: attributedString.string)
        }
        
        // 處理所有容器
        var nodes: [MarkupNode] = []
        var currentIndex = 0
        
        for container in containers.sorted(by: { $0.range.location < $1.range.location }) {
            // 添加容器之前的純文本
            if currentIndex < container.range.location {
                let plainText = attributedString.attributedSubstring(from: NSRange(location: currentIndex,
                                                                                 length: container.range.location - currentIndex)).string
                if !plainText.isEmpty {
                    nodes.append(TextNode(text: plainText))
                }
            }
            
            // 處理容器
            nodes.append(createNodeFromContainer(container, text: attributedString.string))
            currentIndex = NSMaxRange(container.range)
        }
        
        // 添加最後一個容器之後的純文本
        if currentIndex < attributedString.length {
            let plainText = attributedString.attributedSubstring(from: NSRange(location: currentIndex,
                                                                             length: attributedString.length - currentIndex)).string
            if !plainText.isEmpty {
                nodes.append(TextNode(text: plainText))
            }
        }
        
        return nodes.count == 1 ? nodes[0] : StyleNode(style: plainStyle, children: nodes)
    }
    
    private var plainStyle: MarkupStyle {
        return MarkupStyle.custom(name: "plain", attributes: [])
    }
}

extension UIColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}

// MARK: - UITextView Mention Support
extension UITextView {
    func configureMentionTapHandler(handler: @escaping (String) -> Void) {
        // 確保可以點擊
        isSelectable = true
        isEditable = false
        
        // 設置代理
        delegate = MentionTextViewDelegate.shared
        MentionTextViewDelegate.shared.mentionTapHandler = handler
    }
}

// MARK: - Mention Text View Delegate
class MentionTextViewDelegate: NSObject, UITextViewDelegate {
    static let shared = MentionTextViewDelegate()
    
    var mentionTapHandler: ((String) -> Void)?
    
    private override init() {
        super.init()
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // 檢查是否有 mention 屬性
        if let attributedText = textView.attributedText,
           let userId = attributedText.attribute(.mentionUserId, at: characterRange.location, effectiveRange: nil) as? String {
            mentionTapHandler?(userId)
            return false
        }
        return true
    }
} 
