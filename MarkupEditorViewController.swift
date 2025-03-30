import UIKit

class MarkupEditorViewController: UIViewController {
    private var markupEditor: MarkupEditor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // 設置導航欄
        title = "Markup Editor"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "預覽",
            style: .plain,
            target: self,
            action: #selector(previewTapped)
        )
        
        // 設置編輯器
        let editorFrame = CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: view.bounds.height
        )
        markupEditor = MarkupEditor(frame: editorFrame)
        
        // 添加到視圖
        let textView = markupEditor.getTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        // 設置約束
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 設置初始文本
        textView.text = """
        歡迎使用 Markup Editor！

        你可以：
        1. 使用工具欄添加樣式
        2. 直接輸入 Markdown 語法
        3. 預覽最終效果

        支持的樣式：
        - **粗體**
        - _斜體_
        - 列表
        > 引用
        """
    }
    
    @objc private func previewTapped() {
        let previewVC = MarkupPreviewViewController(
            content: markupEditor.getTextView().text
        )
        navigationController?.pushViewController(previewVC, animated: true)
    }
} 