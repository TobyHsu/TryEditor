import Foundation

// MARK: - Node Protocol
public protocol MarkupNode {
    func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result
    
    // 添加一个子节点的获取方法，便于访问器遍历
    var children: [MarkupNode] { get }
}

// MARK: - Concrete Nodes
public class TextNode: MarkupNode {
    let text: String
    
    // 实现children属性
    public var children: [MarkupNode] {
        return [] // 文本节点没有子节点
    }
    
    init(text: String) {
        self.text = text
    }
    
    public func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visit(text: self)
    }
}

public class StyleNode: MarkupNode {
    let style: MarkupStyle
    public let children: [MarkupNode]
    
    init(style: MarkupStyle, children: [MarkupNode]) {
        self.style = style
        self.children = children
    }
    
    public func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        return visitor.visit(style: self)
    }
}

// 添加根节点类，用作文档的顶层容器
public class RootNode: MarkupNode {
    public let children: [MarkupNode]
    
    public init(children: [MarkupNode]) {
        self.children = children
    }
    
    public func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
        // 根节点通常会遍历所有子节点，并合并结果
        return visitor.visit(root: self)
    }
}

//class ListContainerNode: MarkupNode {
//    let style: MarkupStyle
//    let items: [ListItemNode]
//    let level: Int
//    
//    init(style: MarkupStyle, items: [ListItemNode], level: Int) {
//        self.style = style
//        self.items = items
//        self.level = level
//    }
//    
//    func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
//        return visitor.visit(list: self)
//    }
//}
//
//class ListItemNode: MarkupNode {
//    let style: MarkupStyle
//    let content: [MarkupNode]
//    let nestedList: ListContainerNode?
//    
//    init(style: MarkupStyle, content: [MarkupNode], nestedList: ListContainerNode? = nil) {
//        self.style = style
//        self.content = content
//        self.nestedList = nestedList
//    }
//    
//    func accept<V: MarkupVisitor>(_ visitor: V) -> V.Result {
//        return visitor.visit(listItem: self)
//    }
//}

//class MarkupParser {
//    private struct Pattern {
//        let regex: NSRegularExpression
//        let styleType: MarkupStyle.StyleType
//        
//        init(pattern: String, styleType: MarkupStyle.StyleType) {
//            self.regex = try! NSRegularExpression(pattern: pattern)
//            self.styleType = styleType
//        }
//    }
//    
//    private let patterns: [Pattern] = [
//        // Markdown 風格
//        Pattern(pattern: "\\*\\*([^\\*]+)\\*\\*", styleType: .bold),
//        Pattern(pattern: "_([^_]+)_", styleType: .italic),
//        Pattern(pattern: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", styleType: .link(url: "$2")),
//        
//        // 自定義標籤
//        Pattern(pattern: "\\{\\{color\\s+color=([^\\}]+)\\}\\}([^\\{]+)\\{\\{/color\\}\\}", 
//               styleType: .color(hex: "$1"))
//    ]
//    
//    func parse(_ text: String) -> MarkupNode {
//        var currentText = text
//        var matches: [(Range<String.Index>, MarkupStyle.StyleType)] = []
//        
//        // 使用正則表達式找到所有匹配
//        for pattern in patterns {
//            let results = pattern.regex.matches(in: currentText, range: NSRange(currentText.startIndex..., in: currentText))
//            // 處理匹配結果...
//        }
//        
//        // 使用現有的標籤配對邏輯處理巢狀結構
//        return processMatches(matches, in: text)
//    }
//}
