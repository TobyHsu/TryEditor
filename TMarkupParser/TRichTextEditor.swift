import Foundation
import UIKit
import SwiftUI
import Combine

// MARK: - 样式应用模式枚举
public enum StyleApplicationMode {
    case toggleExisting  // 有则移除，无则添加
    case always          // 始终添加
    case continuation    // 连续应用（光标位置后的输入都应用该样式）
}

// MARK: - TRichTextEditor 核心类
public class TRichTextEditor: NSObject, UITextViewDelegate {
    // MARK: 属性
    internal let textView: UITextView
    private let parser: MarkupParser
    private let converter: MarkupConverter
    
    // 样式管理
    private var activeStyles: [MarkupStyle] = []
    private var continuationStyles: [MarkupStyle] = []
    
    // 状态跟踪
    private var isUpdatingText = false
    private var isEditable: Bool = true
    
    // 文本监听
    private var textUpdatePublisher = PassthroughSubject<NSAttributedString, Never>()
    private var selectionUpdatePublisher = PassthroughSubject<NSRange, Never>()
    private var nodesUpdatePublisher = PassthroughSubject<MarkupNode, Never>()
    private var rawTextUpdatePublisher = PassthroughSubject<String, Never>()
    
    // 游标位置和选择范围监听
    private var selectionObserver: Any?
    
    // MARK: - 初始化方法
    public init(
        textView: UITextView,
        parser: MarkupParser = MarkupParser(),
        baseFont: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .label,
        backgroundColor: UIColor = .clear
    ) {
        self.textView = textView
        self.parser = parser
        self.converter = MarkupConverter(
            parser: parser,
            baseFont: baseFont,
            defaultTextColor: textColor,
            defaultBackgroundColor: backgroundColor
        )
        
        super.init()
        
        setupTextView()
        observeSelectionChanges()
    }
    
    // MARK: - 公开接口
    
    // 设置内容
    public func setContent(_ rawText: String) {
        let attributedString = converter.attributedStringFromMarkup(rawText)
        isUpdatingText = true
        textView.attributedText = attributedString
        isUpdatingText = false
        
        // 通知内容更新
        notifyTextUpdate()
    }
    
    // 获取当前内容
    public func getContent() -> String {
        return converter.markupFromAttributedString(textView.attributedText)
    }
    
    // 获取当前选择范围
    public var selectedRange: NSRange {
        return textView.selectedRange
    }
    
    // 获取当前游标位置
    public var cursorPosition: Int {
        return textView.selectedRange.location
    }
    
    // 获取当前富文本
    public var attributedText: NSAttributedString {
        return textView.attributedText
    }
    
    // 获取解析后的节点树
    public var nodes: MarkupNode {
        let rawText = getContent()
        return parser.parse(rawText)
    }
    
    // 设置是否可编辑
    public var editable: Bool {
        get { return isEditable }
        set {
            isEditable = newValue
            textView.isEditable = newValue
        }
    }
    
    // 成为第一响应者，使编辑器获得焦点
    public func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    // 放弃第一响应者，让编辑器失去焦点
    public func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
    
    // 刷新富文本显示
    public func refreshAttributedText() {
        let rawText = getContent()
        isUpdatingText = true
        textView.attributedText = converter.attributedStringFromMarkup(rawText)
        isUpdatingText = false
    }
    
    // 应用样式
    public func applyStyle(_ style: MarkupStyle, mode: StyleApplicationMode = .toggleExisting) {
        guard isEditable else { return }
        
        // 获取当前选择范围
        let selectedRange = textView.selectedRange
        
        // 根据不同的应用模式处理样式
        switch mode {
        case .toggleExisting:
            // 如果有选择范围，切换样式
            if selectedRange.length > 0 {
                toggleStyle(style, in: selectedRange)
            } else {
                // 无选择范围，添加到连续应用列表
                if !continuationStyles.contains(where: { $0.name == style.name }) {
                    continuationStyles.append(style)
                } else {
                    // 已存在，则移除
                    continuationStyles.removeAll { $0.name == style.name }
                }
            }
            
        case .always:
            // 始终应用，无论是否已存在
            if selectedRange.length > 0 {
                applyStyleToRange(style, range: selectedRange)
            } else {
                if !continuationStyles.contains(where: { $0.name == style.name }) {
                    continuationStyles.append(style)
                }
            }
            
        case .continuation:
            // 仅添加到连续应用列表
            if !continuationStyles.contains(where: { $0.name == style.name }) {
                continuationStyles.append(style)
            }
        }
        
        // 更新后刷新显示
        notifyTextUpdate()
    }
    
    // 取消所有连续应用的样式
    public func clearContinuationStyles() {
        continuationStyles.removeAll()
    }
    
    // 处理列表样式
    public func applyListStyle(_ style: MarkupStyle) {
        guard isEditable else { return }
        
        // 处理列表样式需要特殊逻辑
        let selectedRange = textView.selectedRange
        let rawText = getContent()
        let attributedString = textView.attributedText
        
        // 获取当前行范围
        let nsString = rawText as NSString
        let lineRange = nsString.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let lineText = nsString.substring(with: lineRange)
        
        // 检查是否已经是列表样式
        let isBulletList = lineText.hasPrefix("- ")
        let isNumberList = lineText.range(of: "^\\d+\\.\\s+", options: .regularExpression) != nil
        
        var newText = rawText
        let nsRange = lineRange
        
        // 根据样式类型和当前状态处理
        if (style.style is BulletListStyle && isBulletList) || 
           (style.style is NumberListStyle && isNumberList) {
            // 已有列表样式，移除
            if isBulletList {
                if let range = lineText.range(of: "- ") {
                    let startIndex = rawText.index(rawText.startIndex, offsetBy: lineRange.location)
                    let removeStartIndex = rawText.index(startIndex, offsetBy: range.lowerBound.utf16Offset(in: lineText))
                    let removeEndIndex = rawText.index(startIndex, offsetBy: range.upperBound.utf16Offset(in: lineText))
                    newText.removeSubrange(removeStartIndex..<removeEndIndex)
                }
            } else if isNumberList {
                if let range = lineText.range(of: "^\\d+\\.\\s+", options: .regularExpression) {
                    let startIndex = rawText.index(rawText.startIndex, offsetBy: lineRange.location)
                    let removeStartIndex = rawText.index(startIndex, offsetBy: range.lowerBound.utf16Offset(in: lineText))
                    let removeEndIndex = rawText.index(startIndex, offsetBy: range.upperBound.utf16Offset(in: lineText))
                    newText.removeSubrange(removeStartIndex..<removeEndIndex)
                }
            }
        } else {
            // 无列表样式或需要转换样式
            
            // 先移除可能存在的列表样式
            var cleanLineText = lineText
            if isBulletList {
                if let range = cleanLineText.range(of: "- ") {
                    cleanLineText.removeSubrange(range)
                }
            } else if isNumberList {
                if let range = cleanLineText.range(of: "^\\d+\\.\\s+", options: .regularExpression) {
                    cleanLineText.removeSubrange(range)
                }
            }
            
            // 添加新的列表样式前缀
            var prefix = ""
            if style.style is BulletListStyle {
                prefix = "- "
            } else if let numberStyle = style.style as? NumberListStyle {
                prefix = "\(numberStyle.start ?? 1). "
            }
            
            let startIndex = rawText.index(rawText.startIndex, offsetBy: lineRange.location)
            let endIndex = rawText.index(startIndex, offsetBy: lineText.count)
            
            newText.replaceSubrange(startIndex..<endIndex, with: prefix + cleanLineText)
        }
        
        // 更新文本
        if newText != rawText {
            setContent(newText)
            notifyTextUpdate()
        }
    }
    
    // 订阅文本更新
    public func onTextUpdate(_ handler: @escaping (NSAttributedString) -> Void) -> AnyCancellable {
        // 立即发送当前值
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            handler(self.textView.attributedText)
        }
        return textUpdatePublisher.sink(receiveValue: handler)
    }
    
    // 订阅选择范围更新
    public func onSelectionUpdate(_ handler: @escaping (NSRange) -> Void) -> AnyCancellable {
        // 立即发送当前值
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            handler(self.textView.selectedRange)
        }
        return selectionUpdatePublisher.sink(receiveValue: handler)
    }
    
    // 订阅节点更新
    public func onNodesUpdate(_ handler: @escaping (MarkupNode) -> Void) -> AnyCancellable {
        // 立即发送当前值
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            handler(self.nodes)
        }
        return nodesUpdatePublisher.sink(receiveValue: handler)
    }
    
    // 订阅原始文本更新
    public func onRawTextUpdate(_ handler: @escaping (String) -> Void) -> AnyCancellable {
        // 立即发送当前值
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            handler(self.getContent())
        }
        return rawTextUpdatePublisher.sink(receiveValue: handler)
    }
    
    // MARK: - UITextViewDelegate
    
    public func textViewDidChange(_ textView: UITextView) {
        guard !isUpdatingText else { return }
        
        // 应用连续样式
        if !continuationStyles.isEmpty {
            applyCurrentStyles()
        }
        
        // 检查是否需要处理列表的回车换行
        processListNewline()
        
        notifyTextUpdate()
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        selectionUpdatePublisher.send(textView.selectedRange)
    }
    
    // MARK: - 私有辅助方法
    
    private func setupTextView() {
        textView.delegate = self
        textView.isEditable = isEditable
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.autocapitalizationType = .none
    }
    
    private func observeSelectionChanges() {
        // 监听选择范围变化
        selectionObserver = NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: textView,
            queue: .main) { [weak self] _ in
                guard let self = self else { return }
                self.selectionUpdatePublisher.send(self.textView.selectedRange)
            }
    }
    
    private func notifyTextUpdate() {
        // 在主线程上通知所有更新，确保 UI 操作的安全性
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let attributedString = self.textView.attributedText {
                let rawText = self.getContent()
                let node = self.parser.parse(rawText)
                
                self.textUpdatePublisher.send(attributedString)
                self.nodesUpdatePublisher.send(node)
                self.rawTextUpdatePublisher.send(rawText)
            }
        }
    }
    
    // 应用当前活动样式
    private func applyCurrentStyles() {
        guard !continuationStyles.isEmpty else { return }
        
        let rawText = getContent()
        var newText = rawText
        
        // 在用户输入的位置应用样式
        for style in continuationStyles {
            // 假设用户在最后一个输入位置
            let insertPoint = textView.selectedRange.location - 1
            if insertPoint >= 0 && insertPoint < newText.count {
                // 获取用户刚输入的内容
                let lastCharIndex = newText.index(newText.startIndex, offsetBy: insertPoint)
                let lastChar = String(newText[lastCharIndex])
                
                // 应用样式
                let styledText = applyStyleToText(lastChar, style: style)
                
                // 替换原文本
                let startIndex = newText.index(newText.startIndex, offsetBy: insertPoint)
                let endIndex = newText.index(after: startIndex)
                newText.replaceSubrange(startIndex..<endIndex, with: styledText)
            }
        }
        
        if newText != rawText {
            // 记录选择位置
            let selectedRange = textView.selectedRange
            
            // 更新内容
            isUpdatingText = true
            setContent(newText)
            isUpdatingText = false
            
            // 恢复选择位置
            if selectedRange.location < textView.text.count {
                textView.selectedRange = selectedRange
            }
        }
    }
    
    // 在范围内切换样式
    private func toggleStyle(_ style: MarkupStyle, in range: NSRange) {
        let rawText = getContent()
        let nsString = rawText as NSString
        let selectedText = nsString.substring(with: range)
        
        // 检查当前是否已应用样式
        let hasStyle = checkIfStyleApplied(style, in: selectedText)
        
        if hasStyle {
            // 移除样式
            removeStyle(style, in: range)
        } else {
            // 添加样式
            applyStyleToRange(style, range: range)
        }
        
        // 应用完成后发送选择范围更新通知
        selectionUpdatePublisher.send(textView.selectedRange)
    }
    
    // 检查文本是否已应用某样式
    private func checkIfStyleApplied(_ style: MarkupStyle, in text: String) -> Bool {
        // 使用解析器解析文本，然后检查节点树是否包含指定样式
        let node = parser.parse(text)
        
        // 检查节点是否包含指定样式
        func checkNode(_ node: MarkupNode) -> Bool {
            // 检查当前节点
            if let styleNode = node as? StyleNode {
                if styleNode.style.name == style.name {
                    return true
                }
                
                // 递归检查子节点
                for child in styleNode.children {
                    if checkNode(child) {
                        return true
                    }
                }
            }
            
            return false
        }
        
        return checkNode(node)
    }
    
    // 移除范围内的样式
    private func removeStyle(_ style: MarkupStyle, in range: NSRange) {
        let rawText = getContent()
        var resultText = rawText
        
        // 使用解析器来处理标记文本
        let parsedNode = parser.parse(rawText)
        
        // 提取选中文本的范围在原始文本中的位置
        let nsString = rawText as NSString
        let selectedRangeText = nsString.substring(with: range)
        
        // 创建访问器来修改标记文本
        let visitor = RemoveStyleVisitor(targetStyleName: style.name, selectedText: selectedRangeText, selectedRange: range)
        let processedText = visitor.visit(node: parsedNode)
        
        if processedText != rawText {
            // 更新内容
            isUpdatingText = true
            setContent(processedText)
            isUpdatingText = false
            
            // 计算新的选择范围 - 需要减去移除的标签长度
            let openTagLength = style.standardOpeningTag.count
            let closeTagLength = style.standardClosingTag.count
            let newLength = range.length - (openTagLength + closeTagLength)
            let newSelectedRange = NSRange(location: range.location, length: max(0, newLength))
            textView.selectedRange = newSelectedRange
        }
    }
    
    // 对范围应用样式
    private func applyStyleToRange(_ style: MarkupStyle, range: NSRange) {
        let rawText = getContent()
        let nsString = rawText as NSString
        let selectedText = nsString.substring(with: range)
        
        // 应用样式，确保正确处理嵌套标签
        let styledText = applyStyleToText(selectedText, style: style)
        
        // 更新文本
        let mutableRawText = NSMutableString(string: rawText)
        mutableRawText.replaceCharacters(in: range, with: styledText)
        
        // 更新内容
        isUpdatingText = true
        setContent(mutableRawText as String)
        isUpdatingText = false
        
        // 更新选择范围并确保选择范围包含整个样式内容
        let newSelectedRange = NSRange(location: range.location, length: styledText.count)
        textView.selectedRange = newSelectedRange
    }
    
    // 应用样式到文本
    private func applyStyleToText(_ text: String, style: MarkupStyle) -> String {
        // 解析当前文本，确保正确处理嵌套
        let node = parser.parse(text)
        
        // 对于特殊的样式，如删除线，需要特殊处理
        if style.name == "删除线" || style.name == "strikethrough" {
            // 删除线使用 ~~ 标记
            return "~~" + text + "~~"
        } else if style.name == "代码" || style.name == "code" {
            // 行内代码使用 ` 标记
            return "`" + text + "`"
        } else if style.name == "quote" {
            // 处理引用样式
            let currentLevel = getCurrentQuoteLevel(text)
            let quoteStyle = MarkupStyle.quote(level: currentLevel)
            return quoteStyle.standardOpeningTag + text + quoteStyle.standardClosingTag
        } else {
            // 使用标准标签
            return style.standardOpeningTag + text + style.standardClosingTag
        }
    }
    
    private func getCurrentQuoteLevel(_ text: String) -> Int {
        var level = 0
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            var currentLineLevel = 0
            var index = line.startIndex
            
            while index < line.endIndex {
                if line[index] == ">" {
                    currentLineLevel += 1
                } else if !line[index].isWhitespace {
                    break
                }
                index = line.index(after: index)
            }
            
            level = max(level, currentLineLevel)
        }
        
        return level
    }
    
    // 处理列表换行，保持列表样式延续
    private func processListNewline() {
        // 获取当前文本和选择范围
        let rawText = getContent()
        let selectedRange = textView.selectedRange
        
        // 检查是否刚刚输入了回车键
        guard selectedRange.location > 0 && selectedRange.length == 0 else { return }
        let nsString = rawText as NSString
        let currentLineRange = nsString.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let previousCharLoc = selectedRange.location - 1
        let previousCharRange = NSRange(location: previousCharLoc, length: 1)
        
        // 检查前一个字符是否为换行符
        guard previousCharLoc >= 0 && nsString.substring(with: previousCharRange) == "\n" else { return }
        
        // 获取当前行文本
        let currentLineText = nsString.substring(with: currentLineRange)
        
        // 获取上一行的范围和文本
        let previousLineRange = nsString.lineRange(for: NSRange(location: previousCharLoc > 0 ? previousCharLoc - 1 : 0, length: 0))
        let previousLineText = nsString.substring(with: previousLineRange)
        
        // 检查上一行是否为列表项
        let isBulletList = previousLineText.matches(pattern: "^(\\s*)- ")
        let isNumberList = previousLineText.matches(pattern: "^(\\s*)\\d+\\. ")
        
        // 检查上一行是否只有列表前缀（用户删除了内容）
        let isPreviousLineEmpty = previousLineText.matches(pattern: "^(\\s*)(- |\\d+\\. )\\s*$")
        
        if (isBulletList || isNumberList) && !isPreviousLineEmpty {
            // 只有当上一行是列表项且不是空列表项时，才继续列表样式
            var prefix = ""
            var indentation = ""
            
            if isBulletList {
                if let match = previousLineText.firstMatch(pattern: "^(\\s*)- ") {
                    indentation = match.group(at: 1, in: previousLineText) ?? ""
                    prefix = indentation + "- "
                }
            } else if isNumberList {
                if let match = previousLineText.firstMatch(pattern: "^(\\s*)(\\d+)\\. ") {
                    indentation = match.group(at: 1, in: previousLineText) ?? ""
                    if let numberStr = match.group(at: 2, in: previousLineText), let number = Int(numberStr) {
                        prefix = indentation + "\(number + 1). "
                    }
                }
            }
            
            // 检查当前行是否已有列表前缀
            if !currentLineText.hasPrefix(prefix) {
                var newText = rawText
                let startIndex = rawText.index(rawText.startIndex, offsetBy: currentLineRange.location)
                
                // 检查当前行是否为空行（只有换行符的行）
                let trimmedLine = currentLineText.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty {
                    // 如果是空行，则添加列表前缀
                    newText.insert(contentsOf: prefix, at: startIndex)
                    
                    // 更新文本并保持光标位置
                    let newCursorPosition = selectedRange.location + prefix.count
                    isUpdatingText = true
                    setContent(newText)
                    isUpdatingText = false
                    
                    // 设置新的光标位置
                    textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
                } else {
                    // 如果不是空行，同样添加列表前缀
                    newText.insert(contentsOf: prefix, at: startIndex)
                    
                    // 更新文本并保持光标位置
                    let newCursorPosition = selectedRange.location + prefix.count
                    isUpdatingText = true
                    setContent(newText)
                    isUpdatingText = false
                    
                    // 设置新的光标位置
                    textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
                }
            }
            
            // 如果连续输入两个空的列表项，考虑取消列表格式（防止无限延续）
            // 这需要检查上一行是不是也是空的列表项
            if previousLineText.matches(pattern: "^(\\s*)(- |\\d+\\. )\\s*$") && 
               currentLineText.matches(pattern: "^(\\s*)(- |\\d+\\. )\\s*$") {
                // 如果在连续的空列表项上按回车，取消当前行的列表格式
                
                // 首先获取当前行的列表前缀
                var prefixRange: NSRange?
                if let match = currentLineText.firstMatch(pattern: "^(\\s*)(- |\\d+\\. )") {
                    let fullRange = match.range
                    prefixRange = fullRange
                }
                
                if let range = prefixRange {
                    // 删除列表前缀
                    var newText = rawText
                    let startIndex = rawText.index(rawText.startIndex, offsetBy: currentLineRange.location + range.location)
                    let endIndex = rawText.index(startIndex, offsetBy: range.length)
                    newText.removeSubrange(startIndex..<endIndex)
                    
                    // 更新文本并设置光标位置
                    let newCursorPosition = selectedRange.location - range.length
                    isUpdatingText = true
                    setContent(newText)
                    isUpdatingText = false
                    
                    // 设置新的光标位置
                    textView.selectedRange = NSRange(location: max(newCursorPosition, 0), length: 0)
                }
            }
        }
    }
    
    deinit {
        if let observer = selectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - TRichTextView 纯显示用视图
public class TRichTextView: UIView {
    private let textView = UITextView()
    private let parser: MarkupParser
    private let converter: MarkupConverter
    
    public init(
        frame: CGRect = .zero,
        parser: MarkupParser = MarkupParser(),
        baseFont: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .label,
        backgroundColor: UIColor = .clear
    ) {
        self.parser = parser
        self.converter = MarkupConverter(
            parser: parser,
            baseFont: baseFont,
            defaultTextColor: textColor,
            defaultBackgroundColor: backgroundColor
        )
        
        super.init(frame: frame)
        
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        self.parser = MarkupParser()
        self.converter = MarkupConverter(parser: parser)
        
        super.init(coder: coder)
        
        setupTextView()
    }
    
    private func setupTextView() {
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // 设置要显示的富文本内容
    public func setContent(_ rawText: String) {
        let attributedString = converter.attributedStringFromMarkup(rawText)
        textView.attributedText = attributedString
    }
    
    // 配置点击事件处理
    public func configureMentionTapHandler(_ handler: @escaping (String) -> Void) {
        textView.configureMentionTapHandler(handler: handler)
    }
    
    // 获取当前显示的富文本
    public var attributedText: NSAttributedString {
        return textView.attributedText
    }
    
    // 获取原始标记文本
    public var rawText: String {
        return converter.markupFromAttributedString(textView.attributedText)
    }
}

// 用于移除特定样式的访问器类
private class RemoveStyleVisitor {
    let targetStyleName: String
    let selectedText: String
    let selectedRange: NSRange
    
    init(targetStyleName: String, selectedText: String, selectedRange: NSRange) {
        self.targetStyleName = targetStyleName
        self.selectedText = selectedText
        self.selectedRange = selectedRange
    }
    
    func visit(node: MarkupNode) -> String {
        if let textNode = node as? TextNode {
            return textNode.text
        } else if let styleNode = node as? StyleNode {
            // 如果是目标样式且内容匹配选中文本，则仅返回子节点内容
            if styleNode.style.name == targetStyleName && containsSelectedText(styleNode) {
                return styleNode.children.map { visit(node: $0) }.joined()
            } else {
                // 否则保留样式标签
                let content = styleNode.children.map { visit(node: $0) }.joined()
                return styleNode.style.standardOpeningTag + content + styleNode.style.standardClosingTag
            }
        } else if let rootNode = node as? RootNode {
            return rootNode.children.map { visit(node: $0) }.joined()
        }
        return ""
    }
    
    // 检查样式节点是否包含选中的文本
    private func containsSelectedText(_ node: StyleNode) -> Bool {
        let nodeText = node.children.map { 
            if let textNode = $0 as? TextNode {
                return textNode.text
            } else if let styleNode = $0 as? StyleNode {
                return styleNode.style.standardOpeningTag + 
                       styleNode.children.map { visit(node: $0) }.joined() + 
                       styleNode.style.standardClosingTag
            }
            return ""
        }.joined()
        
        return nodeText == selectedText
    }
}

// 添加一些字符串扩展用于正则匹配
private extension String {
    func matches(pattern: String) -> Bool {
        return (try? NSRegularExpression(pattern: pattern).firstMatch(in: self, range: NSRange(location: 0, length: self.count))) != nil
    }
    
    func firstMatch(pattern: String) -> NSTextCheckingResult? {
        return try? NSRegularExpression(pattern: pattern).firstMatch(in: self, range: NSRange(location: 0, length: self.count))
    }
}

private extension NSTextCheckingResult {
    func group(at idx: Int, in string: String) -> String? {
        guard idx < numberOfRanges else { return nil }
        let range = self.range(at: idx)
        guard range.location != NSNotFound else { return nil }
        let nsString = string as NSString
        return nsString.substring(with: range)
    }
    
    var range: NSRange {
        return self.range(at: 0)
    }
} 
