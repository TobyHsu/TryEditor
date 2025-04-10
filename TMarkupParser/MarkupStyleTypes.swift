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

// MARK: - Interactive Attachment
public class InteractiveAttachment: NSTextAttachment {
    private let containerView: UIView
    private weak var textContainer: NSTextContainer?
    private var lastBounds: CGRect = .zero
    
    init(view: UIView) {
        self.containerView = view
        super.init(data: nil, ofType: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        self.textContainer = textContainer
        
        let size = containerView.systemLayoutSizeFitting(
            CGSize(width: lineFrag.width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        lastBounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return lastBounds
    }
    
    public override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        return UIImage()
    }
    
    func addToTextView(_ textView: UITextView) {
        containerView.frame = lastBounds
        textView.addSubview(containerView)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(updatePosition),
            name: UITextView.textDidChangeNotification,
            object: textView)
    }
    
    @objc private func updatePosition(_ notification: Notification) {
        guard let textContainer = textContainer,
              let layoutManager = textContainer.layoutManager,
              let textView = notification.object as? UITextView,
              let range = findAttachmentRange(in: textView) else {
            return
        }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        boundingRect.origin.x += textView.textContainerInset.left
        boundingRect.origin.y += textView.textContainerInset.top
        
        containerView.frame = boundingRect
    }
    
    private func findAttachmentRange(in textView: UITextView) -> NSRange? {
        let attributedText = textView.attributedText
        let fullRange = NSRange(location: 0, length: attributedText?.length ?? 0)
        
        var result: NSRange?
        attributedText?.enumerateAttribute(.attachment, in: fullRange) { value, range, stop in
            if let attachment = value as? NSTextAttachment, attachment === self {
                result = range
                stop.pointee = true
            }
        }
        
        return result
    }
}

// MARK: - Mention View
public class MentionView: UIView {
    private let userId: String
    private let displayName: String
    private var onTap: ((String) -> Void)?
    
    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("@" + displayName, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()
    
    init(userId: String, displayName: String, onTap: @escaping (String) -> Void) {
        self.userId = userId
        self.displayName = displayName
        self.onTap = onTap
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    @objc private func buttonTapped() {
        onTap?(userId)
    }
}

// MARK: - Interactive Table View
public class InteractiveTableView: UITableView {
    private var data: [[String]]
    
    init(data: [[String]]) {
        self.data = data
        super.init(frame: .zero, style: .plain)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        dataSource = self
        delegate = self
        register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        isScrollEnabled = false
        
        // 自動計算高度
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 44
    }
}

extension InteractiveTableView: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let row = data[indexPath.row]
        cell.textLabel?.text = row.joined(separator: " | ")
        return cell
    }
}

// MARK: - Image Attachment
public class ImageAttachment: NSTextAttachment {
    private let imageURL: URL
    private let maxWidth: CGFloat
    private weak var textContainer: NSTextContainer?
    private var cachedImage: UIImage?
    private var imageSize: CGSize = .zero
    private var isLoading = false
    
    private static let imageCache = NSCache<NSURL, UIImage>()
    
    init(imageURL: URL, maxWidth: CGFloat = UIScreen.main.bounds.width - 32) {
        self.imageURL = imageURL
        self.maxWidth = maxWidth
        super.init(data: nil, ofType: nil)
        
        // 配置緩存
        ImageAttachment.imageCache.countLimit = 50 // 最多緩存50張圖片
        ImageAttachment.imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB 上限
        
        loadImage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        self.textContainer = textContainer
        
        if imageSize == .zero {
            // 如果還沒有圖片，返回一個佔位大小
            return CGRect(x: 0, y: 0, width: maxWidth, height: 44)
        }
        
        // 計算適合的大小
        let aspectRatio = imageSize.width / imageSize.height
        let width = min(maxWidth, imageSize.width)
        let height = width / aspectRatio
        
        return CGRect(x: 0, y: 0, width: width, height: height)
    }
    
    public override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        return cachedImage
    }
    
    private func loadImage() {
        // 檢查緩存
        if let cachedImage = ImageAttachment.imageCache.object(forKey: imageURL as NSURL) {
            self.cachedImage = cachedImage
            self.imageSize = cachedImage.size
            updateTextContainer()
            return
        }
        
        guard !isLoading else { return }
        isLoading = true
        
        let task = URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let data = data, let image = UIImage(data: data) {
                    // 根據最大寬度調整圖片大小
                    let aspectRatio = image.size.width / image.size.height
                    let width = min(self.maxWidth, image.size.width)
                    let height = width / aspectRatio
                    
                    // 重新縮放圖片以節省內存
                    let resizedImage = self.resizeImage(image, to: CGSize(width: width, height: height))
                    
                    // 儲存到緩存
                    ImageAttachment.imageCache.setObject(resizedImage, forKey: self.imageURL as NSURL)
                    
                    self.cachedImage = resizedImage
                    self.imageSize = resizedImage.size
                    self.updateTextContainer()
                }
            }
        }
        task.resume()
    }
    
    private func updateTextContainer() {
        guard let textContainer = textContainer,
              let layoutManager = textContainer.layoutManager,
              let textView = layoutManager.textContainer(forGlyphAt: 0, effectiveRange: nil) as? UITextView,
              let range = findAttachmentRange(in: textView) else {
            return
        }
        
        // 通知 TextView 重新布局
        layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        textView.layoutManager.ensureLayout(forCharacterRange: range)
        textView.setNeedsDisplay()
    }
    
    private func findAttachmentRange(in textView: UITextView) -> NSRange? {
        let attributedText = textView.attributedText
        let fullRange = NSRange(location: 0, length: attributedText?.length ?? 0)
        
        var result: NSRange?
        attributedText?.enumerateAttribute(.attachment, in: fullRange) { value, range, stop in
            if let attachment = value as? NSTextAttachment, attachment === self {
                result = range
                stop.pointee = true
            }
        }
        
        return result
    }
    
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // 使用比例較小的一個，確保圖片完全適應目標大小
        let scale = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        
        return resizedImage
    }
    
    // 新增方法 - 无参数版本，通过查找当前视图控制器来显示全屏图片
    public func showFullScreenImage() {
        guard let textContainer = textContainer,
              let layoutManager = textContainer.layoutManager,
              let textView = layoutManager.textContainer(forGlyphAt: 0, effectiveRange: nil) as? UITextView else {
            return
        }
        
        // 寻找当前的视图控制器
        if let viewController = findViewController(from: textView) {
            showFullScreenImage(from: viewController)
        }
    }
    
    // 显示全屏图片的方法
    public func showFullScreenImage(from viewController: UIViewController) {
        let imageVC = FullScreenImageViewController(imageURL: imageURL)
        viewController.present(imageVC, animated: true)
    }
    
    // 辅助方法 - 从视图找到它的视图控制器
    private func findViewController(from view: UIView) -> UIViewController? {
        var responder: UIResponder? = view
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
    
    // 清理緩存
    public static func clearCache() {
        imageCache.removeAllObjects()
    }
} 
