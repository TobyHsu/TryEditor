class ImageAttachment: NSTextAttachment {
    var imageURL: URL
    var maxWidth: CGFloat
    var cachedImage: UIImage?
    var imageSize: CGSize = .zero
    var onTap: (() -> Void)?
    
    static let imageCache = NSCache<NSURL, UIImage>().apply {
        $0.countLimit = 50
        $0.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    init(imageURL: URL, maxWidth: CGFloat) {
        self.imageURL = imageURL
        self.maxWidth = maxWidth
        super.init(data: nil, ofType: nil)
        loadImage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        if imageSize == .zero {
            return CGRect(x: 0, y: 0, width: maxWidth, height: 100)
        }
        return CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
    }
    
    override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        return cachedImage
    }
    
    private func loadImage() {
        if let cachedImage = ImageAttachment.imageCache.object(forKey: imageURL as NSURL) {
            self.cachedImage = cachedImage
            calculateImageSize(for: cachedImage)
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            do {
                let imageData = try Data(contentsOf: self.imageURL)
                guard let image = UIImage(data: imageData) else { return }
                
                DispatchQueue.main.async {
                    let resizedImage = self.resizeImage(image: image, maxWidth: self.maxWidth)
                    self.cachedImage = resizedImage
                    ImageAttachment.imageCache.setObject(resizedImage, forKey: self.imageURL as NSURL)
                    self.calculateImageSize(for: resizedImage)
                    
                    // 通知文本视图需要重新布局
                    NotificationCenter.default.post(name: NSTextStorage.didProcessEditingNotification, object: nil)
                }
            } catch {
                print("加载图片错误: \(error)")
            }
        }
    }
    
    private func calculateImageSize(for image: UIImage) {
        let aspectRatio = image.size.width / image.size.height
        let width = min(image.size.width, maxWidth)
        let height = width / aspectRatio
        
        self.imageSize = CGSize(width: width, height: height)
    }
    
    private func resizeImage(image: UIImage, maxWidth: CGFloat) -> UIImage {
        let aspectRatio = image.size.width / image.size.height
        let width = min(image.size.width, maxWidth)
        let height = width / aspectRatio
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    // 更新：显示全屏图片预览方法
    func showFullScreenImage(from viewController: UIViewController) {
        let imageVC = FullScreenImageViewController(imageURL: imageURL)
        viewController.present(imageVC, animated: true)
    }
}

// 添加全屏图片查看控制器
class FullScreenImageViewController: UIViewController {
    private let image: UIImage
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        view.backgroundColor = .black
        
        // 设置关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // 设置滚动视图
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 设置图片视图
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加双击手势
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateImageViewFrame()
    }
    
    private func updateImageViewFrame() {
        let imageAspectRatio = image.size.width / image.size.height
        let screenWidth = scrollView.bounds.width
        let screenHeight = scrollView.bounds.height
        
        var imageWidth = screenWidth
        var imageHeight = imageWidth / imageAspectRatio
        
        if imageHeight > screenHeight {
            imageHeight = screenHeight
            imageWidth = imageHeight * imageAspectRatio
        }
        
        imageView.frame = CGRect(x: (screenWidth - imageWidth) / 2,
                                y: (screenHeight - imageHeight) / 2,
                                width: imageWidth,
                                height: imageHeight)
        
        scrollView.contentSize = CGSize(width: screenWidth, height: screenHeight)
    }
    
    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let scrollSize = scrollView.frame.size
            
            let width = scrollSize.width / scrollView.maximumZoomScale
            let height = scrollSize.height / scrollView.maximumZoomScale
            let x = point.x - (width / 2)
            let y = point.y - (height / 2)
            
            let rect = CGRect(x: x, y: y, width: width, height: height)
            scrollView.zoom(to: rect, animated: true)
        }
    }
}

extension FullScreenImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? 
            (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? 
            (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
    }
} 