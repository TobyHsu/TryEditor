import UIKit

class MarkupPreviewViewController: UIViewController {
    private let content: String
    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return textView
    }()
    
    init(content: String) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "預覽"
        view.backgroundColor = .systemBackground
        
        // 設置預覽文本
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 轉換並顯示內容
        let parser = MarkupParser()
        let converter = MarkupConverter(parser: parser)
        textView.attributedText = converter.attributedStringFromMarkup(content)
    }
} 