import UIKit

class FullScreenImageViewController: UIViewController {
    // MARK: - 属性
    private let imageView = UIImageView()
    private let scrollView = UIScrollView()
    private let closeButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    private let imageURL: URL
    
    // MARK: - 初始化方法
    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 视图生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }
    
    // MARK: - UI设置
    private func setupUI() {
        view.backgroundColor = .black
        
        // 设置滚动视图
        scrollView.frame = view.bounds
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        
        // 设置图片视图
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        scrollView.addSubview(imageView)
        
        // 设置关闭按钮
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // 设置活动指示器
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // 添加双击手势
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        // 添加单击手势
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.require(toFail: doubleTapGesture)
        scrollView.addGestureRecognizer(singleTapGesture)
    }
    
    // MARK: - 图片加载
    private func loadImage() {
        activityIndicator.startAnimating()
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            do {
                let imageData = try Data(contentsOf: self.imageURL)
                
                DispatchQueue.main.async {
                    if let image = UIImage(data: imageData) {
                        self.imageView.image = image
                        self.updateZoomScaleForSize(self.view.bounds.size)
                        self.scrollView.zoomScale = self.scrollView.minimumZoomScale
                    } else {
                        self.showErrorAlert(message: "无法加载图片")
                    }
                    self.activityIndicator.stopAnimating()
                }
            } catch {
                DispatchQueue.main.async {
                    self.showErrorAlert(message: "加载图片失败: \(error.localizedDescription)")
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func updateZoomScaleForSize(_ size: CGSize) {
        guard let image = imageView.image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 else { return }
        
        let widthScale = size.width / image.size.width
        let heightScale = size.height / image.size.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = minScale * 4.0
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - 手势处理
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let scrollViewSize = scrollView.bounds.size
            
            let width = scrollViewSize.width / scrollView.maximumZoomScale
            let height = scrollViewSize.height / scrollView.maximumZoomScale
            let x = point.x - (width / 2.0)
            let y = point.y - (height / 2.0)
            
            let rectToZoom = CGRect(x: x, y: y, width: width, height: height)
            scrollView.zoom(to: rectToZoom, animated: true)
        }
    }
    
    @objc private func handleSingleTap() {
        closeButton.isHidden = !closeButton.isHidden
    }
    
    // MARK: - 布局更新
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        if let image = imageView.image {
            let scrollViewFrame = scrollView.frame
            let imageSize = image.size
            
            let widthScale = scrollViewFrame.width / imageSize.width
            let heightScale = scrollViewFrame.height / imageSize.height
            let minScale = min(widthScale, heightScale)
            
            let scaledWidth = imageSize.width * minScale
            let scaledHeight = imageSize.height * minScale
            
            imageView.frame = CGRect(
                x: (scrollViewFrame.width - scaledWidth) / 2,
                y: (scrollViewFrame.height - scaledHeight) / 2,
                width: scaledWidth,
                height: scaledHeight
            )
        }
    }
}

// MARK: - UIScrollViewDelegate
extension FullScreenImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        
        imageView.center = CGPoint(
            x: scrollView.contentSize.width * 0.5 + offsetX,
            y: scrollView.contentSize.height * 0.5 + offsetY
        )
    }
} 