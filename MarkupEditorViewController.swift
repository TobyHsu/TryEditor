import UIKit

class MarkupEditorViewController: UIViewController {
    private var markupEditor: MarkupEditor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTestButtons()
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
    
    private func setupTestButtons() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let insertTableButton = UIButton(type: .system)
        insertTableButton.setTitle("插入表格", for: .normal)
        insertTableButton.addTarget(self, action: #selector(insertTableTapped), for: .touchUpInside)
        
        let insertMentionButton = UIButton(type: .system)
        insertMentionButton.setTitle("插入提及", for: .normal)
        insertMentionButton.addTarget(self, action: #selector(insertMentionTapped), for: .touchUpInside)
        
        let insertImageButton = UIButton(type: .system)
        insertImageButton.setTitle("插入圖片", for: .normal)
        insertImageButton.addTarget(self, action: #selector(insertImageTapped), for: .touchUpInside)
        
        let insertGIFButton = UIButton(type: .system)
        insertGIFButton.setTitle("插入GIF", for: .normal)
        insertGIFButton.addTarget(self, action: #selector(insertGIFTapped), for: .touchUpInside)
        
        stackView.addArrangedSubview(insertTableButton)
        stackView.addArrangedSubview(insertMentionButton)
        stackView.addArrangedSubview(insertImageButton)
        stackView.addArrangedSubview(insertGIFButton)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func insertTableTapped() {
        let testData = [
            ["標題1", "標題2", "標題3"],
            ["數據1", "數據2", "數據3"],
            ["數據4", "數據5", "數據6"]
        ]
        
        let textView = markupEditor.getTextView()
        markupEditor.insertTable(data: testData, at: textView.selectedRange)
    }
    
    @objc private func insertMentionTapped() {
        let textView = markupEditor.getTextView()
        markupEditor.insertMention(
            userId: "user123",
            displayName: "測試用戶",
            at: textView.selectedRange
        ) { userId in
            let alert = UIAlertController(
                title: "提及用戶",
                message: "點擊了用戶ID: \(userId)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "確定", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    @objc private func insertImageTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    @objc private func insertGIFTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.gif])
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
    
    @objc private func previewTapped() {
        let previewVC = MarkupPreviewViewController(
            content: markupEditor.getTextView().text
        )
        navigationController?.pushViewController(previewVC, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MarkupEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            let textView = markupEditor.getTextView()
            markupEditor.insertLocalImage(data: imageData, at: textView.selectedRange)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension MarkupEditorViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let gifURL = urls.first else { return }
        
        let textView = markupEditor.getTextView()
        markupEditor.insertGIF(url: gifURL, at: textView.selectedRange)
    }
} 