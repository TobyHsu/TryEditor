import UIKit

class MarkupEditor: NSObject {
    // MARK: - Properties
    private let textView: CustomTextView
    private let parser: MarkupParser
    private let converter: MarkupConverter
    private var isUpdatingContent = false
    
    // 追蹤當前活動的樣式
    private var activeStyles: Set<String> = []
    private var currentListType: ListType = .none
    private var currentListNumber: Int = 1
    
    enum ListType {
        case none
        case bullet
        case number
    }
    
    // 工具欄
    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.items = [
            UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: self, action: #selector(boldTapped)),
            UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: self, action: #selector(italicTapped)),
            UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(bulletListTapped)),
            UIBarButtonItem(image: UIImage(systemName: "list.number"), style: .plain, target: self, action: #selector(numberListTapped)),
            UIBarButtonItem(image: UIImage(systemName: "text.quote"), style: .plain, target: self, action: #selector(quoteTapped))
        ]
        return toolbar
    }()
    
    // MARK: - Initialization
    init(frame: CGRect) {
        self.textView = CustomTextView(frame: frame)
        self.parser = MarkupParser()
        self.converter = MarkupConverter(parser: parser)
        super.init()
        
        setupTextView()
    }
    
    // MARK: - Setup
    private func setupTextView() {
        textView.delegate = self
        textView.inputAccessoryView = toolbar
        textView.font = .systemFont(ofSize: 16)
    }
    
    // MARK: - Public Methods
    func getTextView() -> UITextView {
        return textView
    }
    
    // MARK: - Style Actions
    @objc private func boldTapped() {
        applyStyle(MarkupStyle.bold)
    }
    
    @objc private func italicTapped() {
        applyStyle(MarkupStyle.italic)
    }
    
    @objc private func bulletListTapped() {
        applyListStyle(type: .bullet)
    }
    
    @objc private func numberListTapped() {
        applyListStyle(type: .number)
    }
    
    @objc private func quoteTapped() {
        applyQuoteStyle()
    }
    
    // MARK: - Style Application
    private func applyStyle(_ style: MarkupStyle) {
        let selectedRange = textView.selectedRange
        let currentText = textView.text as NSString
        
        if selectedRange.length > 0 {
            // 有選取範圍的情況
            let selectedText = currentText.substring(with: selectedRange)
            let styledText = style.standardOpeningTag + selectedText + style.standardClosingTag
            
            // 更新文本
            let newText = currentText.replacingCharacters(in: selectedRange, with: styledText)
            updateContent(newText)
            
            // 更新游標位置
            let newPosition = selectedRange.location + styledText.count
            textView.selectedRange = NSRange(location: newPosition, length: 0)
        } else {
            // 只有游標位置的情況
            if activeStyles.contains(style.name) {
                // 取消樣式
                activeStyles.remove(style.name)
            } else {
                // 啟用樣式
                activeStyles.insert(style.name)
            }
            
            // 更新工具欄狀態
            updateToolbarState()
        }
    }
    
    private func applyListStyle(type: ListType) {
        let selectedRange = textView.selectedRange
        let text = textView.text as NSString
        let lineRange = text.lineRange(for: selectedRange)
        let lineText = text.substring(with: lineRange)
        
        if type == currentListType {
            // 取消列表樣式
            currentListType = .none
            currentListNumber = 1
            
            // 移除列表標記
            let cleanText = removeListMarkers(from: lineText)
            let newText = text.replacingCharacters(in: lineRange, with: cleanText)
            updateContent(newText)
        } else {
            // 套用新的列表樣式
            currentListType = type
            currentListNumber = 1
            
            // 添加列表標記
            let prefix = getListPrefix()
            let cleanText = removeListMarkers(from: lineText)
            let newText = text.replacingCharacters(in: lineRange, with: prefix + cleanText)
            updateContent(newText)
        }
    }
    
    private func applyQuoteStyle() {
        let selectedRange = textView.selectedRange
        let text = textView.text as NSString
        let lineRange = text.lineRange(for: selectedRange)
        let lineText = text.substring(with: lineRange)
        
        // 添加引用標記
        let quotedText = "> " + lineText.replacingOccurrences(of: "\n", with: "\n> ")
        
        // 更新文本
        let newText = text.replacingCharacters(in: lineRange, with: quotedText)
        updateContent(newText)
    }
    
    private func getListPrefix() -> String {
        switch currentListType {
        case .bullet:
            return "- "
        case .number:
            let prefix = "\(currentListNumber). "
            currentListNumber += 1
            return prefix
        case .none:
            return ""
        }
    }
    
    private func removeListMarkers(from text: String) -> String {
        // 移除現有的列表標記
        let pattern = "^([0-9]+\\.|-|\\*)\\s+"
        return text.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    // MARK: - Content Management
    private func updateContent(_ newText: String) {
        isUpdatingContent = true
        
        // 保存當前選擇範圍
        let selectedRange = textView.selectedRange
        
        // 轉換為富文本
        let attributedText = converter.attributedStringFromMarkup(newText)
        textView.attributedText = attributedText
        
        // 恢復選擇範圍
        textView.selectedRange = selectedRange
        
        isUpdatingContent = false
    }
    
    private func insertStyledText(_ text: String, at range: NSRange) {
        var styledText = text
        
        // 應用所有活動的樣式
        for styleName in activeStyles {
            if let style = getStyle(for: styleName) {
                styledText = style.standardOpeningTag + styledText + style.standardClosingTag
            }
        }
        
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: styledText)
        updateContent(newText)
    }
    
    private func insertStyledNewline(at range: NSRange) {
        var newlineText = "\n"
        
        // 應用所有活動的樣式
        for styleName in activeStyles {
            if let style = getStyle(for: styleName) {
                newlineText = style.standardOpeningTag + newlineText + style.standardClosingTag
            }
        }
        
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: newlineText)
        updateContent(newText)
    }
    
    private func getStyle(for name: String) -> MarkupStyle? {
        switch name {
        case "bold":
            return MarkupStyle.bold
        case "italic":
            return MarkupStyle.italic
        default:
            return nil
        }
    }
    
    // MARK: - Toolbar State
    private func updateToolbarState() {
        toolbar.items?.forEach { item in
            if let style = getStyleFromBarItem(item) {
                item.tintColor = activeStyles.contains(style.name) ? .systemBlue : .label
            }
        }
    }
    
    private func getStyleFromBarItem(_ item: UIBarButtonItem) -> MarkupStyle? {
        if let image = item.image {
            switch image.description {
            case "bold":
                return MarkupStyle.bold
            case "italic":
                return MarkupStyle.italic
            default:
                return nil
            }
        }
        return nil
    }
}

// MARK: - UITextViewDelegate
extension MarkupEditor: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if !isUpdatingContent {
            // 將純文本轉換為富文本
            let attributedText = converter.attributedStringFromMarkup(textView.text)
            textView.attributedText = attributedText
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 處理換行
        if text == "\n" {
            switch currentListType {
            case .bullet:
                insertNewBulletListItem(at: range)
                return false
            case .number:
                insertNewNumberListItem(at: range)
                return false
            case .none:
                // 應用當前活動的樣式
                if !activeStyles.isEmpty {
                    insertStyledNewline(at: range)
                    return false
                }
            }
        }
        
        // 處理普通文本輸入
        if !activeStyles.isEmpty {
            insertStyledText(text, at: range)
            return false
        }
        
        return true
    }
    
    private func insertNewBulletListItem(at range: NSRange) {
        let text = textView.text as NSString
        let lineRange = text.lineRange(for: range)
        let currentLine = text.substring(with: lineRange)
        
        // 檢查當前行是否為空（只有列表標記）
        if currentLine.trimmingCharacters(in: .whitespaces) == "-" {
            // 結束列表
            currentListType = .none
            let newText = text.replacingCharacters(in: lineRange, with: "\n")
            updateContent(newText)
        } else {
            // 插入新的列表項
            let newText = text.replacingCharacters(in: range, with: "\n- ")
            updateContent(newText)
        }
    }
    
    private func insertNewNumberListItem(at range: NSRange) {
        let text = textView.text as NSString
        let lineRange = text.lineRange(for: range)
        let currentLine = text.substring(with: lineRange)
        
        // 檢查當前行是否為空（只有列表標記）
        if currentLine.trimmingCharacters(in: .whitespaces).hasSuffix(".") {
            // 結束列表
            currentListType = .none
            currentListNumber = 1
            let newText = text.replacingCharacters(in: lineRange, with: "\n")
            updateContent(newText)
        } else {
            // 插入新的列表項
            let newText = text.replacingCharacters(in: range, with: "\n\(currentListNumber). ")
            currentListNumber += 1
            updateContent(newText)
        }
    }
} 