import UIKit
import FLAnimatedImage

public class GIFAttachment: NSTextAttachment {
    private let gifURL: URL
    private let maxWidth: CGFloat
    private weak var textContainer: NSTextContainer?
    private var animatedImageView: FLAnimatedImageView?
    private var imageSize: CGSize = .zero
    private var isLoading = false
    
    private static let cache = NSCache<NSURL, FLAnimatedImage>()
    
    init(gifURL: URL, maxWidth: CGFloat = UIScreen.main.bounds.width - 32) {
        self.gifURL = gifURL
        self.maxWidth = maxWidth
        super.init(data: nil, ofType: nil)
        
        // 配置緩存
        GIFAttachment.cache.countLimit = 20 // 最多緩存20個GIF
        GIFAttachment.cache.totalCostLimit = 100 * 1024 * 1024 // 100MB 上限
        
        loadGIF()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        self.textContainer = textContainer
        
        if imageSize == .zero {
            return CGRect(x: 0, y: 0, width: maxWidth, height: 44)
        }
        
        let aspectRatio = imageSize.width / imageSize.height
        let width = min(maxWidth, imageSize.width)
        let height = width / aspectRatio
        
        return CGRect(x: 0, y: 0, width: width, height: height)
    }
    
    public override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        return UIImage() // 返回空白圖片,因為我們使用 FLAnimatedImageView 來顯示
    }
    
    private func loadGIF() {
        // 檢查緩存
        if let cachedGIF = GIFAttachment.cache.object(forKey: gifURL as NSURL) {
            setupAnimatedImageView(with: cachedGIF)
            return
        }
        
        guard !isLoading else { return }
        isLoading = true
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try Data(contentsOf: self.gifURL)
                if let animatedImage = FLAnimatedImage(gifData: data) {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        GIFAttachment.cache.setObject(animatedImage, forKey: self.gifURL as NSURL)
                        self.setupAnimatedImageView(with: animatedImage)
                    }
                }
            } catch {
                print("Error loading GIF: \(error)")
                self.isLoading = false
            }
        }
    }
    
    private func setupAnimatedImageView(with animatedImage: FLAnimatedImage) {
        imageSize = animatedImage.size
        
        let aspectRatio = imageSize.width / imageSize.height
        let width = min(maxWidth, imageSize.width)
        let height = width / aspectRatio
        
        let imageView = FLAnimatedImageView()
        imageView.animatedImage = animatedImage
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        self.animatedImageView = imageView
        updateTextContainer()
    }
    
    func addToTextView(_ textView: UITextView) {
        if let imageView = animatedImageView {
            textView.addSubview(imageView)
            
            NotificationCenter.default.addObserver(self,
                selector: #selector(updatePosition),
                name: UITextView.textDidChangeNotification,
                object: textView)
        }
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
        
        animatedImageView?.frame = boundingRect
    }
    
    private func updateTextContainer() {
        guard let textContainer = textContainer,
              let layoutManager = textContainer.layoutManager,
              let textView = layoutManager.textContainerForGlyphAt(0, effectiveRange: nil) as? UITextView,
              let range = findAttachmentRange(in: textView) else {
            return
        }
        
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
    
    // 清理緩存
    public static func clearCache() {
        cache.removeAllObjects()
    }
} 