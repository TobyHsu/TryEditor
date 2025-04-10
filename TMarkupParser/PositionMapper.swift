import Foundation
import UIKit

/// 用於處理原始文本和富文本之間游標位置的映射
class PositionMapper {
    // 映射表結構
    struct PositionMap {
        var originalToRendered: [Int: Int] = [:]  // 原始 -> 渲染
        var renderedToOriginal: [Int: Int] = [:]  // 渲染 -> 原始
    }
    
    private var positionMap = PositionMap()
    private let parser: MarkupParser
    
    init(parser: MarkupParser) {
        self.parser = parser
    }
    
    /// 更新位置映射表
    /// - Parameters:
    ///   - rawText: 原始標記文本
    ///   - attributedText: 轉換後的富文本
    func updateMap(rawText: String, attributedText: NSAttributedString) {
        // 解析文本獲取節點樹
        let node = parser.parse(rawText)
        
        // 創建並使用映射訪問者
        let visitor = PositionMapperVisitor(attributedText: attributedText)
        node.accept(visitor)
        
        // 獲取構建的映射
        positionMap.originalToRendered = visitor.originalToRendered
        positionMap.renderedToOriginal = visitor.renderedToOriginal
        
        // DEBUG: 打印映射關係
        printDebugInfo(rawText: rawText)
    }
    
    /// 將渲染位置轉換為原始位置
    /// - Parameter renderedPosition: 富文本中的位置
    /// - Returns: 對應的原始文本位置
    func convertToRawPosition(_ renderedPosition: Int) -> Int {
        // 直接查找映射
        if let rawPosition = positionMap.renderedToOriginal[renderedPosition] {
            return rawPosition
        }
        
        // 如果沒有直接映射，找最接近的位置
        let keys = positionMap.renderedToOriginal.keys.sorted()
        var closestKey = renderedPosition
        
        for key in keys {
            if key > renderedPosition {
                break
            }
            closestKey = key
        }
        
        if let rawPosition = positionMap.renderedToOriginal[closestKey] {
            let offset = renderedPosition - closestKey
            return rawPosition + offset
        }
        
        return renderedPosition
    }
    
    /// 將原始位置轉換為渲染位置
    /// - Parameter rawPosition: 原始文本中的位置
    /// - Returns: 對應的富文本位置
    func convertToRenderedPosition(_ rawPosition: Int) -> Int {
        // 直接查找映射
        if let renderedPosition = positionMap.originalToRendered[rawPosition] {
            return renderedPosition
        }
        
        // 如果沒有直接映射，找最接近的位置
        let keys = positionMap.originalToRendered.keys.sorted()
        var closestKey = rawPosition
        
        for key in keys {
            if key > rawPosition {
                break
            }
            closestKey = key
        }
        
        if let renderedPosition = positionMap.originalToRendered[closestKey] {
            let offset = rawPosition - closestKey
            return renderedPosition + offset
        }
        
        return rawPosition
    }
    
    /// 打印調試信息
    private func printDebugInfo(rawText: String) {
        print("=== 位置映射表 ===")
        print("原始->渲染:")
        let rawString = rawText as NSString
        for i in 0..<min(rawString.length, 100) {
            if let rendered = positionMap.originalToRendered[i] {
                let char = i < rawString.length ? rawString.substring(with: NSRange(location: i, length: 1)) : "END"
                print("原始[\(i)]='\(char)' -> 渲染[\(rendered)]")
            }
        }
        
        print("\n渲染->原始:")
        for (rendered, raw) in positionMap.renderedToOriginal.sorted(by: { $0.key < $1.key }).prefix(20) {
            let char = raw < rawString.length ? rawString.substring(with: NSRange(location: raw, length: 1)) : "END"
            print("渲染[\(rendered)] -> 原始[\(raw)]='\(char)'")
        }
    }
    
    /// 兼容舊版本的方法，作為 updateMap 的別名
    @available(*, deprecated, renamed: "updateMap")
    func buildPositionMap(rawText: String, attributedString: NSAttributedString) {
        updateMap(rawText: rawText, attributedText: attributedString)
    }
}

/// 位置映射訪問者
class PositionMapperVisitor: MarkupVisitor {
    typealias Result = Void
    
    // 存儲映射關係
    var originalToRendered: [Int: Int] = [:]
    var renderedToOriginal: [Int: Int] = [:]
    
    // 跟蹤當前位置
    private var originalPos = 0
    private var renderedPos = 0
    
    // 儲存渲染後的富文本
    private let attributedText: NSAttributedString
    
    init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }
    
    /// 處理文本節點
    func visit(text: TextNode) -> Void {
        // 文本節點的映射是一對一的
        for i in 0..<text.text.count {
            originalToRendered[originalPos + i] = renderedPos + i
            renderedToOriginal[renderedPos + i] = originalPos + i
        }
        
        originalPos += text.text.count
        renderedPos += text.text.count
    }
    
    /// 處理樣式節點
    func visit(style: StyleNode) -> Void {
        // 記錄起始位置
        let originalStart = originalPos
        
        // 處理開始標記
        processOpeningTag(for: style.style)
        
        // 記錄渲染開始位置（處理前綴前）
        let renderedStart = renderedPos
        
        // 根據樣式類型處理前綴
        processPrefixForStyle(style.style)
        
        // 記錄內容開始位置
        let contentStart = renderedPos
        
        // 處理子節點
        for child in style.children {
            child.accept(self)
        }
        
        // 記錄內容結束位置
        let contentEnd = renderedPos
        
        // 處理結束標記
        processClosingTag(for: style.style)
        
        // 特殊處理：對於列表項或引用等樣式，確保內容部分的映射正確
        if needsContentMapping(style.style) {
            fixContentMapping(
                originalStart: originalStart, 
                renderedStart: renderedStart,
                contentStart: contentStart,
                contentEnd: contentEnd,
                style: style.style
            )
        }
    }
    
    /// 處理根節點
    func visit(root: RootNode) -> Void {
        for child in root.children {
            child.accept(self)
        }
    }
    
    // MARK: - 輔助方法
    
    /// 處理開始標記
    private func processOpeningTag(for style: MarkupStyle) {
        let tag = style.standardOpeningTag
        let tagLength = tag.count
        
        if tagLength > 0 {
            // 標記在渲染時會被移除或替換
            for i in 0..<tagLength {
                originalToRendered[originalPos + i] = renderedPos
            }
            originalPos += tagLength
        }
    }
    
    /// 處理結束標記
    private func processClosingTag(for style: MarkupStyle) {
        let tag = style.standardClosingTag
        let tagLength = tag.count
        
        if tagLength > 0 {
            // 標記在渲染時會被移除或替換
            for i in 0..<tagLength {
                originalToRendered[originalPos + i] = renderedPos
            }
            originalPos += tagLength
        }
    }
    
    /// 根據樣式類型處理前綴
    private func processPrefixForStyle(_ style: MarkupStyle) {
        if let bulletItem = style.style as? BulletListItemStyle {
            processBulletPrefix(level: bulletItem.level)
        } else if let numberItem = style.style as? NumberListItemStyle {
            processNumberPrefix(number: numberItem.number ?? 1, level: numberItem.level)
        } else if let quoteStyle = style.style as? QuoteStyle {
            processQuotePrefix(level: quoteStyle.level)
        }
        // 可以添加其他樣式的前綴處理...
    }
    
    /// 處理項目符號列表前綴
    private func processBulletPrefix(level: Int) {
        // "- " 變成 "\t• "
        let indentText = String(repeating: "\t", count: level)
        let renderedPrefix = indentText + "• "
        
        // 為渲染後的前綴創建映射
        for i in 0..<renderedPrefix.count {
            renderedToOriginal[renderedPos + i] = originalPos - 2  // 映射到原始的 "- "
        }
        
        renderedPos += renderedPrefix.count
    }
    
    /// 處理數字列表前綴
    private func processNumberPrefix(number: Int, level: Int) {
        let numberText = "\(number)"
        let indentText = String(repeating: "\t", count: level)
        let renderedPrefix = indentText + numberText + ". "
        
        // 為渲染後的前綴創建映射
        for i in 0..<renderedPrefix.count {
            renderedToOriginal[renderedPos + i] = originalPos - (numberText.count + 2)  // 映射到原始的 "數字. "
        }
        
        renderedPos += renderedPrefix.count
    }
    
    /// 處理引用前綴
    private func processQuotePrefix(level: Int) {
        // "> " 變成縮進和背景色
        // 這裡不需要調整渲染位置，因為引用樣式通常是通過段落樣式實現
    }
    
    /// 檢查是否需要特殊內容映射處理
    private func needsContentMapping(_ style: MarkupStyle) -> Bool {
        // 限制只对特定样式类型进行特殊映射处理
        return style.style is BulletListItemStyle || 
               style.style is NumberListItemStyle || 
               style.style is QuoteStyle
    }
    
    /// 修正內容映射
    private func fixContentMapping(
        originalStart: Int,
        renderedStart: Int,
        contentStart: Int,
        contentEnd: Int,
        style: MarkupStyle
    ) {
        // 防止无效参数
        guard contentEnd >= contentStart,
              contentStart >= 0,
              originalStart >= 0 else {
            return
        }
        
        // 获取内容长度，并确保不会过大
        let contentLength = min(contentEnd - contentStart, 1000) // 限制最大长度
        
        // 遍历内容中的每个位置，确保有正确的映射
        for i in 0..<contentLength {
            let renderedPos = contentStart + i
            
            // 如果该渲染位置还没有映射到原始位置
            if renderedToOriginal[renderedPos] == nil {
                // 使用简化的方法找到接近的原始位置
                // 首先尝试使用固定偏移
                let estimatedOrigPos = originalStart + i
                if estimatedOrigPos >= 0 {
                    renderedToOriginal[renderedPos] = estimatedOrigPos
                    continue
                }
                
                // 如果固定偏移不可行，使用更简单的查找逻辑
                var bestOriginalPos = originalStart
                
                // 限制遍历次数，防止过多计算
                let maxIterations = 100
                var iterations = 0
                
                // 遍历已知映射，但限制遍历次数
                for (origPos, rendPos) in originalToRendered {
                    iterations += 1
                    if iterations > maxIterations {
                        break
                    }
                    
                    if abs(rendPos - renderedPos) < abs(originalToRendered[bestOriginalPos] ?? 0 - renderedPos) {
                        bestOriginalPos = origPos
                    }
                }
                
                // 创建映射
                renderedToOriginal[renderedPos] = bestOriginalPos
            }
        }
    }
} 